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

      // Step 5: Upsert teams (with logos if not skipped)
      if (allParticipants.length > 0) {
        let teams = allParticipants.map(p => mapTeamToDb(p));

        // Fetch team logos if not skipped
        if (!this.options.skipLogos) {
          this.logger.info('Fetching team logos...');
          teams = await this.fetchTeamLogos(teams);
        }

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
          const { matchCount, stratzTeamIdToGroup } = await this.importMatchesFromStratz(
            dbTournament.id,
            leagueId,
            allParticipants,
          );
          result.matchesImported = matchCount;

          // Step 9: Update team group assignments from STRATZ data
          if (stratzTeamIdToGroup.size > 0 && !this.options.dryRun) {
            this.logger.section('Updating Team Groups');
            await this.updateTeamGroupsFromStratz(
              dbTournament.id,
              leagueId,
              allParticipants,
              stratzTeamIdToGroup,
            );
          }
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
   * Fetch league structure from STRATZ (nodeGroups with stage/round info)
   */
  private async fetchLeagueStructure(leagueId: number): Promise<{
    seriesIdToStage: Map<number, { stage: string; round?: string; bestOf?: number }>;
    stratzTeamIdToGroup: Map<number, string>;
  }> {
    const seriesIdToStage = new Map<number, { stage: string; round?: string; bestOf?: number }>();
    const stratzTeamIdToGroup = new Map<number, string>();

    try {
      const url = `${this.backendUrl}/api/v1/stratz/league/${leagueId}`;
      this.logger.debug(`Fetching league structure: ${url}`);

      const response = await fetch(url);
      if (!response.ok) return { seriesIdToStage, stratzTeamIdToGroup };

      const json = await response.json() as {
        success: boolean;
        data: {
          nodeGroups?: Array<{
            id: number;
            name: string;
            nodeGroupType: string;
            nodes?: Array<{
              id: number;
              name?: string;
              nodeType?: string;
              teamOneId?: number;
              teamTwoId?: number;
              seriesId?: number;
            }>;
          }>;
        };
      };

      if (!json.success || !json.data?.nodeGroups) {
        return { seriesIdToStage, stratzTeamIdToGroup };
      }

      // Process each node group
      for (const nodeGroup of json.data.nodeGroups) {
        const stageName = this.normalizeStage(nodeGroup.name, nodeGroup.nodeGroupType);

        if (!nodeGroup.nodes) continue;

        let roundCounter = 1;
        for (const node of nodeGroup.nodes) {
          // Map seriesId to stage info
          if (node.seriesId) {
            const bestOf = this.parseBestOf(node.nodeType);
            seriesIdToStage.set(node.seriesId, {
              stage: stageName,
              round: node.name || this.generateRoundName(nodeGroup, roundCounter),
              bestOf,
            });
          }

          // Map team IDs to groups (for group stages)
          if (nodeGroup.nodeGroupType === 'ROUND_ROBIN') {
            if (node.teamOneId) stratzTeamIdToGroup.set(node.teamOneId, nodeGroup.name);
            if (node.teamTwoId) stratzTeamIdToGroup.set(node.teamTwoId, nodeGroup.name);
          }

          roundCounter++;
        }
      }

      this.logger.info(`Loaded structure: ${seriesIdToStage.size} series, ${stratzTeamIdToGroup.size} team-group mappings`);

    } catch (error) {
      this.logger.debug('Failed to fetch league structure');
    }

    return { seriesIdToStage, stratzTeamIdToGroup };
  }

  /**
   * Normalize stage name from nodeGroup
   */
  private normalizeStage(name: string, nodeGroupType: string): string {
    if (name.startsWith('Group')) return 'Group Stage';
    if (name === 'Playoff' || nodeGroupType.includes('BRACKET')) return 'Playoffs';
    if (name === 'Placement') return 'Playoffs';
    return name;
  }

  /**
   * Generate round name based on node group and position
   */
  private generateRoundName(nodeGroup: { name: string; nodeGroupType: string }, position: number): string {
    if (nodeGroup.nodeGroupType === 'ROUND_ROBIN') {
      return `Round ${Math.ceil(position / 5)}`; // Approximate round
    }
    if (nodeGroup.name === 'Playoff' || nodeGroup.nodeGroupType.includes('BRACKET')) {
      // For playoffs, try to infer round from position
      // This is approximate - real bracket position would be better
      return '';
    }
    return '';
  }

  /**
   * Parse best_of from node type
   */
  private parseBestOf(nodeType?: string): number | undefined {
    if (!nodeType) return undefined;
    if (nodeType.includes('ONE')) return 1;
    if (nodeType.includes('TWO')) return 2;
    if (nodeType.includes('THREE')) return 3;
    if (nodeType.includes('FIVE')) return 5;
    return undefined;
  }

  /**
   * Import matches from STRATZ
   */
  private async importMatchesFromStratz(
    tournamentId: string,
    leagueId: number,
    participants: LiquipediaParticipant[],
  ): Promise<{ matchCount: number; stratzTeamIdToGroup: Map<number, string> }> {
    try {
      // First fetch league structure for stage/round mapping
      const { seriesIdToStage, stratzTeamIdToGroup } = await this.fetchLeagueStructure(leagueId);

      // Fetch ALL league matches from backend using pagination
      const allMatches: Array<{
        matchId: number;
        radiantTeam?: { id: number; name: string };
        direTeam?: { id: number; name: string };
        radiantWin?: boolean;
        startDateTime?: number;
        durationSeconds?: number;
        seriesId?: number;
      }> = [];

      const batchSize = 100;
      let skip = 0;
      let hasMore = true;

      while (hasMore) {
        const url = `${this.backendUrl}/api/v1/stratz/league/${leagueId}/matches?take=${batchSize}&skip=${skip}`;
        this.logger.debug(`Fetching matches: ${url}`);

        const response = await fetch(url);

        if (!response.ok) {
          this.logger.warn(`Failed to fetch matches: ${response.status}`);
          break;
        }

        const json = await response.json() as {
          success: boolean;
          data: Array<{
            matchId: number;
            radiantTeam?: { id: number; name: string };
            direTeam?: { id: number; name: string };
            radiantWin?: boolean;
            startDateTime?: number;
            durationSeconds?: number;
            seriesId?: number;
          }>;
        };

        if (!json.success || !json.data || json.data.length === 0) {
          hasMore = false;
          break;
        }

        allMatches.push(...json.data);
        this.logger.info(`Fetched ${json.data.length} matches (total: ${allMatches.length})`);

        if (json.data.length < batchSize) {
          hasMore = false;
        } else {
          skip += batchSize;
          // Small delay between batches to avoid rate limiting
          await sleep(1000);
        }
      }

      const matches = allMatches;
      this.logger.info(`Found ${matches.length} total matches from STRATZ`);

      // Build team name to ID mapping (and STRATZ ID mapping)
      const teamNameToId = new Map<string, string>();
      const stratzTeamIdToDbId = new Map<number, string>();
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
          this.logger.debug(`Skipping match ${match.matchId} - teams not found: ${team1Name} vs ${team2Name}`);
          continue;
        }

        // Map STRATZ team IDs to DB IDs for group assignment
        if (match.radiantTeam?.id && team1Id) {
          stratzTeamIdToDbId.set(match.radiantTeam.id, team1Id);
        }
        if (match.direTeam?.id && team2Id) {
          stratzTeamIdToDbId.set(match.direTeam.id, team2Id);
        }

        const winnerId = match.radiantWin ? team1Id : team2Id;
        const startTime = match.startDateTime
          ? new Date(match.startDateTime * 1000).toISOString()
          : undefined;

        // Get stage/round info from seriesId
        const stageInfo = match.seriesId ? seriesIdToStage.get(match.seriesId) : undefined;

        dbMatches.push({
          tournament_id: tournamentId,
          team1_id: team1Id,
          team2_id: team2Id,
          winner_id: winnerId,
          team1_score: match.radiantWin ? 1 : 0,
          team2_score: match.radiantWin ? 0 : 1,
          started_at: startTime,
          ended_at: startTime,
          stage: stageInfo?.stage,
          round: stageInfo?.round,
          best_of: stageInfo?.bestOf,
          status: 'completed',
          updated_at: new Date().toISOString(),
        });
      }

      // Log stage distribution
      const stageCount = new Map<string, number>();
      dbMatches.forEach(m => {
        const stage = m.stage || 'Unknown';
        stageCount.set(stage, (stageCount.get(stage) || 0) + 1);
      });
      this.logger.info(`Match stages: ${Array.from(stageCount.entries()).map(([s, c]) => `${s}=${c}`).join(', ')}`);

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
          return { matchCount: 0, stratzTeamIdToGroup };
        }

        this.logger.success(`Imported ${dbMatches.length} matches`);
      } else if (this.options.dryRun) {
        this.logger.info(`[DRY RUN] Would import ${dbMatches.length} matches`);
      }

      return { matchCount: dbMatches.length, stratzTeamIdToGroup };

    } catch (error) {
      this.logger.error('Failed to import matches', error instanceof Error ? error : undefined);
      return { matchCount: 0, stratzTeamIdToGroup: new Map() };
    }
  }

  /**
   * Update tournament teams with group assignments from STRATZ
   */
  private async updateTeamGroupsFromStratz(
    tournamentId: string,
    leagueId: number,
    participants: LiquipediaParticipant[],
    stratzTeamIdToGroup: Map<number, string>,
  ): Promise<void> {
    if (stratzTeamIdToGroup.size === 0) return;

    // Build map of team name to STRATZ team ID (from match data)
    // We need to fetch one batch of matches to get this mapping
    const url = `${this.backendUrl}/api/v1/stratz/league/${leagueId}/matches?take=100`;
    try {
      const response = await fetch(url);
      if (!response.ok) return;

      const json = await response.json() as {
        success: boolean;
        data: Array<{
          radiantTeam?: { id: number; name: string };
          direTeam?: { id: number; name: string };
        }>;
      };

      if (!json.success || !json.data) return;

      // Build team name to STRATZ ID mapping
      const teamNameToStratzId = new Map<string, number>();
      for (const match of json.data) {
        if (match.radiantTeam) {
          teamNameToStratzId.set(this.normalizeTeamName(match.radiantTeam.name), match.radiantTeam.id);
        }
        if (match.direTeam) {
          teamNameToStratzId.set(this.normalizeTeamName(match.direTeam.name), match.direTeam.id);
        }
      }

      // Update each team's group
      let groupsUpdated = 0;
      for (const participant of participants) {
        const normalizedName = this.normalizeTeamName(participant.teamName);
        const stratzId = teamNameToStratzId.get(normalizedName);

        if (stratzId && stratzTeamIdToGroup.has(stratzId)) {
          const groupName = stratzTeamIdToGroup.get(stratzId)!;
          const teamId = generateTeamId(participant.teamName);

          const { error } = await this.supabase
            .from('tournament_teams')
            .update({ group_name: groupName })
            .eq('tournament_id', tournamentId)
            .eq('team_id', teamId);

          if (!error) groupsUpdated++;
        }
      }

      this.logger.success(`Updated ${groupsUpdated} team group assignments`);

    } catch (error) {
      this.logger.debug('Failed to update team groups');
    }
  }

  /**
   * Fetch team logos from Liquipedia
   */
  private async fetchTeamLogos(teams: DbTeam[]): Promise<DbTeam[]> {
    const updatedTeams: DbTeam[] = [];

    for (const team of teams) {
      try {
        const url = `${this.backendUrl}/api/v1/liquipedia/team-logo/${encodeURIComponent(team.name.replace(/ /g, '_'))}`;
        this.logger.debug(`Fetching logo for: ${team.name}`);

        const response = await fetch(url);

        if (response.ok) {
          const json = await response.json() as {
            success: boolean;
            data: { logoUrl?: string; logoDarkUrl?: string };
          };

          if (json.success && json.data?.logoUrl) {
            team.logo_url = json.data.logoUrl;
            this.logger.debug(`Found logo for ${team.name}`);
          }
        }
      } catch (error) {
        this.logger.debug(`Failed to fetch logo for ${team.name}`);
      }

      updatedTeams.push(team);

      // Small delay to respect rate limits
      await sleep(500);
    }

    const logosFound = updatedTeams.filter(t => t.logo_url).length;
    this.logger.success(`Found logos for ${logosFound}/${teams.length} teams`);

    return updatedTeams;
  }

  /**
   * Normalize team name for matching
   * Handles variations like "PSG.Quest" vs "PSG Quest" vs "PSG_Quest"
   */
  private normalizeTeamName(name: string): string {
    return name
      .toLowerCase()
      .replace(/[.\-_]/g, ' ')  // Replace dots, dashes, underscores with spaces
      .replace(/\s+/g, ' ')     // Collapse multiple spaces
      .trim();
  }

  /**
   * Find team ID with fuzzy matching
   */
  private findTeamId(teamName: string, teamNameToId: Map<string, string>): string | undefined {
    // Exact match first
    if (teamNameToId.has(teamName)) {
      return teamNameToId.get(teamName);
    }

    // Normalize the incoming team name
    const normalizedInput = this.normalizeTeamName(teamName);

    // Try normalized match
    const entries = Array.from(teamNameToId.entries());
    for (const [name, id] of entries) {
      const normalizedName = this.normalizeTeamName(name);

      // Exact normalized match
      if (normalizedName === normalizedInput) {
        return id;
      }

      // Substring match (both directions)
      if (normalizedName.includes(normalizedInput) || normalizedInput.includes(normalizedName)) {
        return id;
      }
    }

    // Try word-based matching for abbreviated names
    const inputWords = normalizedInput.split(' ').filter(w => w.length > 0);
    for (const [name, id] of entries) {
      const nameWords = this.normalizeTeamName(name).split(' ').filter(w => w.length > 0);

      // Check if key words match (handles "Team Spirit" vs "Spirit")
      const significantInputWords = inputWords.filter(w => w.length > 2);
      const significantNameWords = nameWords.filter(w => w.length > 2);

      if (significantInputWords.length > 0 && significantNameWords.length > 0) {
        const matchingWords = significantInputWords.filter(w =>
          significantNameWords.some(nw => nw === w || nw.includes(w) || w.includes(nw))
        );

        // If at least half the significant words match, consider it a match
        if (matchingWords.length >= Math.max(1, significantInputWords.length / 2)) {
          return id;
        }
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
