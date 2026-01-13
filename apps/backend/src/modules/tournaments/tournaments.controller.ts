import { Controller, Get, Param, Query } from '@nestjs/common';
import { TournamentsService } from './tournaments.service';
import { TournamentDataService } from './tournament-data.service';
import { Public } from '../auth/decorators/public.decorator';

@Controller('tournaments')
export class TournamentsController {
  constructor(
    private tournamentsService: TournamentsService,
    private tournamentDataService: TournamentDataService,
  ) {}

  /**
   * Get list of tournaments with optional filters
   */
  @Public()
  @Get()
  async findAll(
    @Query('status') status?: 'upcoming' | 'ongoing' | 'completed',
    @Query('tier') tier?: string,
    @Query('region') region?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.tournamentsService.findAll(
      { status, tier, region },
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  // ============ External API Integration Endpoints ============
  // NOTE: These must come BEFORE the :id routes to avoid conflicts

  /**
   * Get The International by year with match data from STRATZ
   * Combines Liquipedia tournament info with STRATZ match data
   */
  @Public()
  @Get('ti/:year/external')
  async getTheInternationalExternal(
    @Param('year') year: string,
    @Query('includeMatches') includeMatches?: string,
    @Query('matchLimit') matchLimit?: string,
  ) {
    const data = await this.tournamentDataService.getTheInternationalWithMatches(
      parseInt(year, 10),
      {
        includeMatches: includeMatches !== 'false',
        matchLimit: matchLimit ? parseInt(matchLimit, 10) : 100,
      },
    );
    return { success: true, data };
  }

  /**
   * Get quick tournament summary
   * Example: /tournaments/external-summary?pageName=The_International/2024
   */
  @Public()
  @Get('external-summary')
  async getTournamentSummary(@Query('pageName') pageName: string) {
    if (!pageName) {
      return { success: false, error: 'pageName query parameter is required' };
    }
    const data =
      await this.tournamentDataService.getTournamentSummary(pageName);
    return { success: true, data };
  }

  /**
   * Get any tournament by Liquipedia page name with match data
   * Example: /tournaments/external?pageName=The_International/2024
   */
  @Public()
  @Get('external')
  async getTournamentExternal(
    @Query('pageName') pageName: string,
    @Query('includeMatches') includeMatches?: string,
    @Query('matchLimit') matchLimit?: string,
  ) {
    if (!pageName) {
      return { success: false, error: 'pageName query parameter is required' };
    }
    const data = await this.tournamentDataService.getTournamentWithMatches(
      pageName,
      {
        includeMatches: includeMatches !== 'false',
        matchLimit: matchLimit ? parseInt(matchLimit, 10) : 100,
      },
    );
    return { success: true, data };
  }

  // ============ Database Endpoints ============
  // NOTE: These :id routes must come AFTER static routes

  /**
   * Get tournament by ID (from database)
   */
  @Public()
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.tournamentsService.findOne(id);
  }

  /**
   * Get teams participating in a tournament
   */
  @Public()
  @Get(':id/teams')
  async getTeams(@Param('id') id: string) {
    return this.tournamentsService.getTeams(id);
  }

  /**
   * Get matches in a tournament
   */
  @Public()
  @Get(':id/matches')
  async getMatches(
    @Param('id') id: string,
    @Query('status') status?: 'scheduled' | 'live' | 'completed' | 'postponed' | 'cancelled',
    @Query('stage') stage?: string,
  ) {
    return this.tournamentsService.getMatches(id, { status, stage });
  }
}
