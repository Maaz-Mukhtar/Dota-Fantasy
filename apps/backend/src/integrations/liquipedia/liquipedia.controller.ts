import { Controller, Get, Param, Query } from '@nestjs/common';
import { Public } from '../../modules/auth/decorators/public.decorator';
import { LiquipediaService } from './liquipedia.service';
import { LiquipediaMatchStageService } from './liquipedia-match-stage.service';
import {
  TournamentInfo,
  MatchStageInfo,
  TournamentStage,
  PlayoffRound,
} from './liquipedia.types';

@Controller('liquipedia')
export class LiquipediaController {
  constructor(
    private readonly liquipediaService: LiquipediaService,
    private readonly matchStageService: LiquipediaMatchStageService,
  ) {}

  /**
   * Get The International tournament info by year
   * Example: GET /api/liquipedia/ti/2024
   */
  @Public()
  @Get('ti/:year')
  async getTheInternational(@Param('year') year: string): Promise<TournamentInfo> {
    const yearNum = parseInt(year, 10);
    if (isNaN(yearNum) || yearNum < 2011 || yearNum > 2030) {
      throw new Error('Invalid year. TI started in 2011.');
    }
    return this.liquipediaService.getTheInternational(yearNum);
  }

  /**
   * Get multiple TI tournaments
   * Example: GET /api/liquipedia/ti?years=2024,2023
   */
  @Public()
  @Get('ti')
  async getMultipleTIs(
    @Query('years') years?: string,
  ): Promise<TournamentInfo[]> {
    const yearList = years
      ? years.split(',').map((y) => parseInt(y.trim(), 10))
      : [2024, 2023];

    return this.liquipediaService.getMultipleTIs(yearList);
  }

  /**
   * Get any tournament by page name
   * Example: GET /api/liquipedia/tournament/ESL_One_Birmingham_2024
   */
  @Public()
  @Get('tournament/:pageName')
  async getTournament(@Param('pageName') pageName: string): Promise<TournamentInfo> {
    return this.liquipediaService.getTournament(pageName);
  }

  /**
   * Get comprehensive tournament data including all participants and rosters
   * Example: GET /api/liquipedia/tournament-full/The_International/2025
   */
  @Public()
  @Get('tournament-full/:pageName(*)')
  async getTournamentFull(@Param('pageName') pageName: string): Promise<TournamentInfo> {
    return this.liquipediaService.getTournamentFull(pageName);
  }

  /**
   * Get The International with full data by year
   * Example: GET /api/liquipedia/ti-full/2025
   */
  @Public()
  @Get('ti-full/:year')
  async getTheInternationalFull(@Param('year') year: string): Promise<TournamentInfo> {
    const yearNum = parseInt(year, 10);
    if (isNaN(yearNum) || yearNum < 2011 || yearNum > 2030) {
      throw new Error('Invalid year. TI started in 2011.');
    }
    return this.liquipediaService.getTournamentFull(`The_International/${yearNum}`);
  }

  /**
   * Search tournaments by year
   * Example: GET /api/liquipedia/tournaments/2024
   */
  @Public()
  @Get('tournaments/:year')
  async searchTournaments(@Param('year') year: string): Promise<string[]> {
    const yearNum = parseInt(year, 10);
    if (isNaN(yearNum)) {
      throw new Error('Invalid year');
    }
    return this.liquipediaService.searchTournaments(yearNum);
  }

  /**
   * Get pages in a category
   * Example: GET /api/liquipedia/category/Tier_1_Tournaments
   */
  @Public()
  @Get('category/:category')
  async getCategoryMembers(
    @Param('category') category: string,
    @Query('limit') limit?: string,
  ): Promise<string[]> {
    const limitNum = limit ? parseInt(limit, 10) : 50;
    return this.liquipediaService.getCategoryMembers(category, limitNum);
  }

  /**
   * Get team logo URLs
   * Example: GET /api/liquipedia/team-logo/Team_Liquid
   */
  @Public()
  @Get('team-logo/:teamName')
  async getTeamLogo(
    @Param('teamName') teamName: string,
  ): Promise<{ logoUrl?: string; logoDarkUrl?: string }> {
    return this.liquipediaService.getTeamLogo(teamName.replace(/_/g, ' '));
  }

  /**
   * Get tournament logo URLs
   * Example: GET /api/liquipedia/tournament-logo/The_International/2024
   * Example: GET /api/liquipedia/tournament-logo/Riyadh_Masters/2024
   */
  @Public()
  @Get('tournament-logo/:pageName(*)')
  async getTournamentLogo(
    @Param('pageName') pageName: string,
  ): Promise<{ logoUrl?: string; logoDarkUrl?: string }> {
    return this.liquipediaService.getTournamentLogo(pageName);
  }

  /**
   * Get The International with full data including team logos
   * Example: GET /api/liquipedia/ti-full-logos/2025
   * Note: This is slower due to fetching logos for each team (rate limited)
   */
  @Public()
  @Get('ti-full-logos/:year')
  async getTheInternationalFullWithLogos(@Param('year') year: string): Promise<TournamentInfo> {
    const yearNum = parseInt(year, 10);
    if (isNaN(yearNum) || yearNum < 2011 || yearNum > 2030) {
      throw new Error('Invalid year. TI started in 2011.');
    }
    return this.liquipediaService.getTournamentFullWithLogos(`The_International/${yearNum}`);
  }

  // ============ Match Stage Endpoints ============

  /**
   * Get match stage mapping for TI by year
   * Example: GET /api/liquipedia/ti-stages/2023
   * Returns all matches with their stage info (group_stage vs playoffs, round, game number)
   */
  @Public()
  @Get('ti-stages/:year')
  async getTIStageMapping(@Param('year') year: string): Promise<{
    tournamentPath: string;
    leagueId?: number;
    groupStageMatchCount: number;
    playoffMatchCount: number;
    series: Array<{
      stage: TournamentStage;
      substage: string;
      round?: PlayoffRound;
      seriesFormat: string;
      matchIds: number[];
      team1?: string;
      team2?: string;
    }>;
  }> {
    const yearNum = parseInt(year, 10);
    if (isNaN(yearNum) || yearNum < 2011 || yearNum > 2030) {
      throw new Error('Invalid year. TI started in 2011.');
    }

    const mapping = await this.matchStageService.getTournamentStageMapping(
      `The_International/${yearNum}`,
    );

    return {
      tournamentPath: mapping.tournamentPath,
      leagueId: mapping.leagueId,
      groupStageMatchCount: mapping.groupStageMatchCount,
      playoffMatchCount: mapping.playoffMatchCount,
      series: mapping.series,
    };
  }

  /**
   * Get stage info for a specific match ID
   * Example: GET /api/liquipedia/match-stage/The_International/2023/7391149823
   */
  @Public()
  @Get('match-stage/:pageName(*)/match/:matchId')
  async getMatchStageInfo(
    @Param('pageName') pageName: string,
    @Param('matchId') matchId: string,
  ): Promise<MatchStageInfo | { error: string }> {
    const id = parseInt(matchId, 10);
    if (isNaN(id)) {
      return { error: 'Invalid match ID' };
    }

    const info = await this.matchStageService.getMatchStageInfo(pageName, id);
    if (!info) {
      return { error: 'Match not found in tournament' };
    }
    return info;
  }

  /**
   * Get all match IDs for a specific stage
   * Example: GET /api/liquipedia/matches-by-stage/The_International/2023?stage=group_stage
   */
  @Public()
  @Get('matches-by-stage/:pageName(*)')
  async getMatchesByStage(
    @Param('pageName') pageName: string,
    @Query('stage') stage: TournamentStage,
  ): Promise<{ matchIds: number[] } | { error: string }> {
    if (!stage || !['group_stage', 'playoffs'].includes(stage)) {
      return { error: 'Invalid stage. Use group_stage or playoffs.' };
    }

    const matchIds = await this.matchStageService.getMatchIdsByStage(
      pageName,
      stage,
    );
    return { matchIds };
  }

  /**
   * Get all match IDs for a specific playoff round
   * Example: GET /api/liquipedia/matches-by-round/The_International/2023?round=grand_final
   */
  @Public()
  @Get('matches-by-round/:pageName(*)')
  async getMatchesByRound(
    @Param('pageName') pageName: string,
    @Query('round') round: PlayoffRound,
  ): Promise<{ matchIds: number[] } | { error: string }> {
    const validRounds: PlayoffRound[] = [
      'upper_bracket_r1',
      'upper_bracket_qf',
      'upper_bracket_sf',
      'upper_bracket_final',
      'lower_bracket_r1',
      'lower_bracket_r2',
      'lower_bracket_r3',
      'lower_bracket_qf',
      'lower_bracket_sf',
      'lower_bracket_final',
      'grand_final',
      'placement',
      'tiebreaker',
      'unknown',
    ];

    if (!round || !validRounds.includes(round)) {
      return { error: `Invalid round. Valid rounds: ${validRounds.join(', ')}` };
    }

    const matchIds = await this.matchStageService.getMatchIdsByRound(
      pageName,
      round,
    );
    return { matchIds };
  }
}
