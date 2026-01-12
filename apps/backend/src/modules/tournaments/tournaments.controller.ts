import { Controller, Get, Param, Query } from '@nestjs/common';
import { TournamentsService } from './tournaments.service';
import { Public } from '../auth/decorators/public.decorator';

@Controller('tournaments')
export class TournamentsController {
  constructor(private tournamentsService: TournamentsService) {}

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

  /**
   * Get tournament by ID
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
