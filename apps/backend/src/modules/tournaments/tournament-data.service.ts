import { Injectable, Logger } from '@nestjs/common';
import { LiquipediaService } from '../../integrations/liquipedia/liquipedia.service';
import { StratzService } from '../../integrations/stratz/stratz.service';
import { TournamentInfo } from '../../integrations/liquipedia/liquipedia.types';
import { StratzLeague, LeagueMatchSummary } from '../../integrations/stratz/stratz.types';

export interface TournamentWithMatches {
  // From Liquipedia
  tournament: TournamentInfo;
  // From STRATZ
  leagueInfo?: StratzLeague;
  matches?: LeagueMatchSummary[];
  matchCount?: number;
}

@Injectable()
export class TournamentDataService {
  private readonly logger = new Logger(TournamentDataService.name);

  constructor(
    private liquipediaService: LiquipediaService,
    private stratzService: StratzService,
  ) {}

  /**
   * Get tournament info from Liquipedia with match data from STRATZ
   */
  async getTournamentWithMatches(
    pageName: string,
    options: { includeMatches?: boolean; matchLimit?: number } = {},
  ): Promise<TournamentWithMatches> {
    const { includeMatches = true, matchLimit = 100 } = options;

    this.logger.log(`Fetching tournament data for: ${pageName}`);

    // Get tournament info from Liquipedia
    const tournament = await this.liquipediaService.getTournamentFull(pageName);

    if (!tournament) {
      throw new Error(`Tournament not found: ${pageName}`);
    }

    const result: TournamentWithMatches = { tournament };

    // If we have a league ID, fetch STRATZ data
    const leagueId = tournament.leagueId
      ? parseInt(tournament.leagueId, 10)
      : null;

    if (leagueId && !isNaN(leagueId)) {
      this.logger.log(`Fetching STRATZ data for league ID: ${leagueId}`);

      // Fetch league info and matches in parallel
      const [leagueInfo, matches] = await Promise.all([
        this.stratzService.getLeagueInfo(leagueId),
        includeMatches
          ? this.stratzService.getLeagueMatches(leagueId, matchLimit)
          : Promise.resolve([]),
      ]);

      result.leagueInfo = leagueInfo || undefined;
      result.matches = matches;
      result.matchCount = matches.length;
    } else {
      this.logger.warn(`No valid league ID found for tournament: ${pageName}`);
    }

    return result;
  }

  /**
   * Get The International by year with match data
   */
  async getTheInternationalWithMatches(
    year: number,
    options: { includeMatches?: boolean; matchLimit?: number } = {},
  ): Promise<TournamentWithMatches> {
    const pageName = `The_International/${year}`;
    return this.getTournamentWithMatches(pageName, options);
  }

  /**
   * Get quick summary of a tournament (basic info + match count)
   */
  async getTournamentSummary(pageName: string): Promise<{
    name: string;
    tier: string;
    prizePool: string;
    leagueId: number | null;
    startDate: string;
    endDate: string;
    teamCount: number;
    matchCount: number;
    winner?: string;
  }> {
    const tournament = await this.liquipediaService.getTournamentFull(pageName);

    if (!tournament) {
      throw new Error(`Tournament not found: ${pageName}`);
    }

    const leagueId = tournament.leagueId
      ? parseInt(tournament.leagueId, 10)
      : null;

    let matchCount = 0;
    if (leagueId && !isNaN(leagueId)) {
      // Get match count by fetching first page
      const matches = await this.stratzService.getLeagueMatches(leagueId, 1, 0);
      matchCount = matches.length > 0 ? -1 : 0; // -1 indicates "has matches"
    }

    return {
      name: tournament.name || pageName,
      tier: tournament.tier || tournament.valveTier || 'Unknown',
      prizePool: String(tournament.prizePool || tournament.prizePoolUsd || 'Unknown'),
      leagueId,
      startDate: tournament.startDate || 'Unknown',
      endDate: tournament.endDate || 'Unknown',
      teamCount: tournament.participants || tournament.teams?.length || 0,
      matchCount,
      winner: tournament.winner,
    };
  }
}
