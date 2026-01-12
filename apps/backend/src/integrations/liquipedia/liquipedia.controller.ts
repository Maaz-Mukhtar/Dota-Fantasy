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
}
