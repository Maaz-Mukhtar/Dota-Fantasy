/**
 * Core tournament import logic
 *
 * This module provides the main functionality for importing tournament data
 * from Liquipedia and STRATZ into the Supabase database.
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';
import {
  generateTournamentId,
  generateTeamId,
  mapTournamentToDb,
  mapTeamToDb,
  mapTournamentTeamToDb,
  mapPlayerToDb,
  mapTournamentPlayerToDb,
  LiquipediaTournament,
  LiquipediaParticipant,
  DbTournament,
  DbTeam,
  DbTournamentTeam,
  DbPlayer,
  DbTournamentPlayer,
  DbMatch,
} from './data-mapper';
import { ProgressLogger, sleep } from './progress-logger';

// Load environment variables
dotenv.config();

export interface ImportOptions {
  dryRun?: boolean;
  verbose?: boolean;
  skipMatches?: boolean;
  skipStats?: boolean;
  skipLogos?: boolean;
  backendUrl?: string;
}

export interface ImportResult {
  success: boolean;
  tournamentId?: string;
  tournamentName?: string;
  teamsImported: number;
  playersImported: number;
  matchesImported: number;
  errors: string[];
}

/**
 * Tournament Importer class
 */
export class TournamentImporter {
  private supabase: SupabaseClient;
  private backendUrl: string;
  private logger: ProgressLogger;
  private options: ImportOptions;

  constructor(options: ImportOptions = {}) {
    this.options = options;
    this.logger = new ProgressLogger({
      verbose: options.verbose,
      dryRun: options.dryRun,
    });

    // Initialize Supabase client
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in environment');
    }

    this.supabase = createClient(supabaseUrl, supabaseKey);
    this.backendUrl = options.backendUrl || process.env.BACKEND_URL || 'http://localhost:3000';
  }

  /**
   * Import a single tournament by Liquipedia page name
   */
  async importTournament(pageName: string): Promise<ImportResult> {
    const result: ImportResult = {
      success: false,
      teamsImported: 0,
      playersImported: 0,
      matchesImported: 0,
      errors: [],
    };

    try {
      this.logger.header(`Importing Tournament: ${pageName}`);

      // Step 1: Fetch tournament data from Liquipedia via backend API
      this.logger.section('Fetching Tournament Data');
      const tournament = await this.fetchTournamentData(pageName);

      if (!tournament) {
        result.errors.push('Failed to fetch tournament data');
        return result;
      }

      result.tournamentName = tournament.name;
      this.logger.tournamentPreview({
        name: tournament.name,
        tier: tournament.tier,
        prizePool: tournament.prizePoolUsd || tournament.prizePool,
        startDate: tournament.startDate,
        endDate: tournament.endDate,
        teams: (tournament.directInvites?.length || 0) + (tournament.qualifiedTeams?.length || 0),
      });

      // Step 2: Fetch tournament logo
      let logoUrl: string | undefined;
      if (!this.options.skipLogos) {
        this.logger.info('Fetching tournament logo...');
        logoUrl = await this.fetchTournamentLogo(pageName);
        if (logoUrl) {
          this.logger.success(`Logo found: ${logoUrl.substring(0, 50)}...`);
        }
      }

      // Step 3: Prepare database records
      this.logger.section('Preparing Database Records');
      const dbTournament = mapTournamentToDb(tournament, logoUrl);
      result.tournamentId = dbTournament.id;

      const allParticipants = [
        ...(tournament.directInvites || []),
        ...(tournament.qualifiedTeams || []),
      ];

      if (allParticipants.length === 0) {
        this.logger.warn('No participants found in tournament data');
        this.logger.info('Tournament might not have announced teams yet');
      }

      this.logger.info(`Found ${allParticipants.length} teams`);

      // Step 4: Upsert tournament
      this.logger.section('Importing to Database');
      if (!this.options.dryRun) {
        await this.upsertTournament(dbTournament);
        this.logger.success('Tournament record upserted');
      } else {
        this.logger.info('[DRY RUN] Would upsert tournament record');
      }

      // Step 5: Upsert teams
      if (allParticipants.length > 0) {
        const teams = allParticipants.map(p => mapTeamToDb(p));
        if (!this.options.dryRun) {
          await this.upsertTeams(teams);
          this.logger.success(`Upserted ${teams.length} teams`);
        } else {
          this.logger.info(`[DRY RUN] Would upsert ${teams.length} teams`);
        }
        result.teamsImported = teams.length;

        // Step 6: Link teams to tournament
        const tournamentTeams = allParticipants.map((p, i) =>
          mapTournamentTeamToDb(dbTournament.id, p, i, allParticipants.length),
        );
        if (!this.options.dryRun) {
          await this.linkTeamsToTournament(dbTournament.id, tournamentTeams);
          this.logger.success(`Linked ${tournamentTeams.length} teams to tournament`);
        } else {
          this.logger.info(`[DRY RUN] Would link ${tournamentTeams.length} teams`);
        }

        // Step 7: Upsert players
        const players: DbPlayer[] = [];
        const tournamentPlayers: DbTournamentPlayer[] = [];

        for (const participant of allParticipants) {
          const teamId = generateTeamId(participant.teamName);

          for (const player of participant.players) {
            if (player.isSubstitute) continue; // Skip subs

            const dbPlayer = mapPlayerToDb(player, participant.teamName, teamId);
            players.push(dbPlayer);

            const dbTournamentPlayer = mapTournamentPlayerToDb(
              dbTournament.id,
              dbPlayer.id,
              teamId,
            );
            tournamentPlayers.push(dbTournamentPlayer);
          }
        }

        if (players.length > 0) {
          if (!this.options.dryRun) {
            await this.upsertPlayers(players);
            this.logger.success(`Upserted ${players.length} players`);

            await this.linkPlayersToTournament(dbTournament.id, tournamentPlayers);
            this.logger.success(`Linked ${tournamentPlayers.length} players to tournament`);
          } else {
            this.logger.info(`[DRY RUN] Would upsert ${players.length} players`);
          }
          result.playersImported = players.length;
        }
      }

      // Step 8: Import matches from STRATZ (if leagueId available)
      if (!this.options.skipMatches && tournament.leagueId) {
        this.logger.section('Importing Matches from STRATZ');
        const leagueId = parseInt(tournament.leagueId, 10);

        if (!isNaN(leagueId)) {
          const matchCount = await this.importMatchesFromStratz(
            dbTournament.id,
            leagueId,
            allParticipants,
          );
          result.matchesImported = matchCount;
        } else {
          this.logger.warn(`Invalid leagueId: ${tournament.leagueId}`);
        }
      } else if (!this.options.skipMatches) {
        this.logger.info('No leagueId found - skipping STRATZ match import');
      }

      // Summary
      this.logger.summary({
        'Tournament': tournament.name,
        'Tournament ID': dbTournament.id,
        'Teams imported': result.teamsImported,
        'Players imported': result.playersImported,
        'Matches imported': result.matchesImported,
        'Mode': this.options.dryRun ? 'DRY RUN' : 'LIVE',
      });

      result.success = true;
      return result;

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.logger.error(`Import failed: ${errorMessage}`, error instanceof Error ? error : undefined);
      result.errors.push(errorMessage);
      return result;
    }
  }

  /**
   * Fetch tournament data from backend API
   */
  private async fetchTournamentData(pageName: string): Promise<LiquipediaTournament | null> {
    try {
      // Use the full tournament endpoint for comprehensive data
      const url = `${this.backendUrl}/api/v1/liquipedia/tournament-full/${encodeURIComponent(pageName)}`;
      this.logger.debug(`Fetching: ${url}`);

      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`API responded with status ${response.status}`);
      }

      const json = await response.json() as { success: boolean; data: LiquipediaTournament };

      if (!json.success || !json.data) {
        throw new Error('API returned unsuccessful response');
      }

      return json.data;
    } catch (error) {
      this.logger.error('Failed to fetch tournament data', error instanceof Error ? error : undefined);
      return null;
    }
  }

  /**
   * Fetch tournament logo from backend API
   */
  private async fetchTournamentLogo(pageName: string): Promise<string | undefined> {
    try {
      const url = `${this.backendUrl}/api/v1/liquipedia/tournament-logo/${encodeURIComponent(pageName)}`;
      const response = await fetch(url);

      if (!response.ok) return undefined;

      const json = await response.json() as { success: boolean; data: { logoUrl?: string } };

      return json.data?.logoUrl;
    } catch {
      return undefined;
    }
  }

  /**
   * Upsert tournament record
   */
  private async upsertTournament(tournament: DbTournament): Promise<void> {
    const { error } = await this.supabase
      .from('tournaments')
      .upsert(tournament, { onConflict: 'id' });

    if (error) {
      throw new Error(`Failed to upsert tournament: ${error.message}`);
    }
  }

  /**
   * Upsert teams
   */
  private async upsertTeams(teams: DbTeam[]): Promise<void> {
    const { error } = await this.supabase
      .from('teams')
      .upsert(teams, { onConflict: 'id' });

    if (error) {
      throw new Error(`Failed to upsert teams: ${error.message}`);
    }
  }

  /**
   * Link teams to tournament (delete existing, insert new)
   */
  private async linkTeamsToTournament(
    tournamentId: string,
    tournamentTeams: DbTournamentTeam[],
  ): Promise<void> {
    // Delete existing links
    await this.supabase
      .from('tournament_teams')
      .delete()
      .eq('tournament_id', tournamentId);

    // Insert new links
    const { error } = await this.supabase
      .from('tournament_teams')
      .insert(tournamentTeams);

    if (error) {
      throw new Error(`Failed to link teams: ${error.message}`);
    }
  }

  /**
   * Upsert players
   */
  private async upsertPlayers(players: DbPlayer[]): Promise<void> {
    const { error } = await this.supabase
      .from('players')
      .upsert(players, { onConflict: 'id' });

    if (error) {
      throw new Error(`Failed to upsert players: ${error.message}`);
    }
  }

  /**
   * Link players to tournament
   */
  private async linkPlayersToTournament(
    tournamentId: string,
    tournamentPlayers: DbTournamentPlayer[],
  ): Promise<void> {
    // Delete existing links
    await this.supabase
      .from('tournament_players')
      .delete()
      .eq('tournament_id', tournamentId);

    // Insert new links
    const { error } = await this.supabase
      .from('tournament_players')
      .insert(tournamentPlayers);

    if (error) {
      throw new Error(`Failed to link players: ${error.message}`);
    }
  }

  /**
   * Import matches from STRATZ
   */
  private async importMatchesFromStratz(
    tournamentId: string,
    leagueId: number,
    participants: LiquipediaParticipant[],
  ): Promise<number> {
    try {
      // Fetch league matches from backend
      const url = `${this.backendUrl}/api/v1/stratz/league/${leagueId}/matches`;
      this.logger.debug(`Fetching matches: ${url}`);

      const response = await fetch(url);

      if (!response.ok) {
        this.logger.warn(`Failed to fetch matches: ${response.status}`);
        return 0;
      }

      const json = await response.json() as {
        success: boolean;
        data: Array<{
          id: number;
          radiantTeamId?: number;
          direTeamId?: number;
          didRadiantWin?: boolean;
          startDateTime?: number;
          durationSeconds?: number;
          seriesId?: number;
          radiantTeam?: { name: string };
          direTeam?: { name: string };
        }>;
      };

      if (!json.success || !json.data) {
        return 0;
      }

      const matches = json.data;
      this.logger.info(`Found ${matches.length} matches from STRATZ`);

      // Build team name to ID mapping
      const teamNameToId = new Map<string, string>();
      participants.forEach(p => {
        teamNameToId.set(p.teamName.toLowerCase(), generateTeamId(p.teamName));
      });

      // Convert to database matches
      const dbMatches: DbMatch[] = [];

      for (const match of matches) {
        const team1Name = match.radiantTeam?.name?.toLowerCase();
        const team2Name = match.direTeam?.name?.toLowerCase();

        // Find team IDs (fuzzy match)
        const team1Id = team1Name ? this.findTeamId(team1Name, teamNameToId) : undefined;
        const team2Id = team2Name ? this.findTeamId(team2Name, teamNameToId) : undefined;

        if (!team1Id || !team2Id) {
          this.logger.debug(`Skipping match ${match.id} - teams not found`);
          continue;
        }

        const winnerId = match.didRadiantWin ? team1Id : team2Id;
        const startTime = match.startDateTime
          ? new Date(match.startDateTime * 1000).toISOString()
          : undefined;

        dbMatches.push({
          tournament_id: tournamentId,
          team1_id: team1Id,
          team2_id: team2Id,
          winner_id: winnerId,
          team1_score: match.didRadiantWin ? 1 : 0,
          team2_score: match.didRadiantWin ? 0 : 1,
          started_at: startTime,
          ended_at: startTime,
          status: 'completed',
          stratz_match_id: match.id,
          updated_at: new Date().toISOString(),
        });
      }

      if (dbMatches.length > 0 && !this.options.dryRun) {
        // Delete existing matches
        await this.supabase
          .from('matches')
          .delete()
          .eq('tournament_id', tournamentId);

        // Insert new matches
        const { error } = await this.supabase
          .from('matches')
          .insert(dbMatches);

        if (error) {
          this.logger.error(`Failed to insert matches: ${error.message}`);
          return 0;
        }

        this.logger.success(`Imported ${dbMatches.length} matches`);
      } else if (this.options.dryRun) {
        this.logger.info(`[DRY RUN] Would import ${dbMatches.length} matches`);
      }

      return dbMatches.length;

    } catch (error) {
      this.logger.error('Failed to import matches', error instanceof Error ? error : undefined);
      return 0;
    }
  }

  /**
   * Find team ID with fuzzy matching
   */
  private findTeamId(teamName: string, teamNameToId: Map<string, string>): string | undefined {
    // Exact match first
    if (teamNameToId.has(teamName)) {
      return teamNameToId.get(teamName);
    }

    // Try fuzzy match
    const entries = Array.from(teamNameToId.entries());
    for (const [name, id] of entries) {
      if (name.includes(teamName) || teamName.includes(name)) {
        return id;
      }
    }

    return undefined;
  }

  /**
   * Check if tournament already exists
   */
  async tournamentExists(pageName: string): Promise<boolean> {
    const tournamentId = generateTournamentId(pageName);

    const { data, error } = await this.supabase
      .from('tournaments')
      .select('id')
      .eq('id', tournamentId)
      .single();

    return !error && !!data;
  }
}

/**
 * Create importer instance with default options
 */
export function createImporter(options?: ImportOptions): TournamentImporter {
  return new TournamentImporter(options);
}
