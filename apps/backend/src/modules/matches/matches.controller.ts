import { Controller, Get, Param, Query } from '@nestjs/common';
import { MatchesService } from './matches.service';
import { Public } from '../auth/decorators/public.decorator';

@Controller('matches')
export class MatchesController {
  constructor(private matchesService: MatchesService) {}

  @Public()
  @Get()
  async findAll(
    @Query('status') status?: 'scheduled' | 'live' | 'completed' | 'postponed' | 'cancelled',
    @Query('stage') stage?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return {
      success: true,
      ...(await this.matchesService.findAll(
        { status, stage },
        page ? parseInt(page, 10) : 1,
        limit ? parseInt(limit, 10) : 20,
      )),
    };
  }

  @Public()
  @Get('live')
  async getLiveMatches() {
    return {
      success: true,
      data: await this.matchesService.getLiveMatches(),
    };
  }

  @Public()
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return {
      success: true,
      data: await this.matchesService.findOne(id),
    };
  }
}
