import { Controller, Get, Param, Query } from '@nestjs/common';
import { PlayersService, PlayerFilters, PaginationParams } from './players.service';
import { Public } from '../auth/decorators/public.decorator';

@Controller('players')
export class PlayersController {
  constructor(private readonly playersService: PlayersService) {}

  @Public()
  @Get()
  async findAll(
    @Query('team_id') teamId?: string,
    @Query('role') role?: string,
    @Query('search') search?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const filters: PlayerFilters = {
      team_id: teamId,
      role,
      search,
    };

    const pagination: PaginationParams = {
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 20,
    };

    return this.playersService.findAll(filters, pagination);
  }

  @Public()
  @Get('tournament/:tournamentId')
  async findByTournament(
    @Param('tournamentId') tournamentId: string,
    @Query('team_id') teamId?: string,
    @Query('role') role?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const filters: PlayerFilters = {
      team_id: teamId,
      role,
    };

    const pagination: PaginationParams = {
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 50,
    };

    return this.playersService.findByTournament(tournamentId, filters, pagination);
  }

  @Public()
  @Get('team/:teamId')
  async findByTeam(@Param('teamId') teamId: string) {
    return this.playersService.findByTeam(teamId);
  }

  @Public()
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.playersService.findOne(id);
  }

  @Public()
  @Get(':id/stats')
  async getPlayerStats(
    @Param('id') id: string,
    @Query('limit') limit?: string,
  ) {
    return this.playersService.getPlayerStats(id, limit ? parseInt(limit, 10) : 10);
  }

  @Public()
  @Get(':id/fantasy-avg')
  async getFantasyAverage(
    @Param('id') id: string,
    @Query('tournament_id') tournamentId?: string,
  ) {
    return this.playersService.getPlayerFantasyAverage(id, tournamentId);
  }
}
