import { Controller, Get, Param, Query } from '@nestjs/common';
import { Public } from '../../modules/auth/decorators/public.decorator';
import { LiquipediaService } from './liquipedia.service';
import { TournamentInfo } from './liquipedia.types';

@Controller('liquipedia')
export class LiquipediaController {
  constructor(private readonly liquipediaService: LiquipediaService) {}

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
}
