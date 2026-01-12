import { Controller, Get, Param, Query } from '@nestjs/common';
import { TeamsService } from './teams.service';
import { Public } from '../auth/decorators/public.decorator';

@Controller('teams')
export class TeamsController {
  constructor(private teamsService: TeamsService) {}

  @Public()
  @Get()
  async findAll(
    @Query('region') region?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return {
      success: true,
      ...(await this.teamsService.findAll(
        { region },
        page ? parseInt(page, 10) : 1,
        limit ? parseInt(limit, 10) : 20,
      )),
    };
  }

  @Public()
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return {
      success: true,
      data: await this.teamsService.findOne(id),
    };
  }
}
