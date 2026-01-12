import { Controller, Get, Param } from '@nestjs/common';
import { TournamentsService } from './tournaments.service';
import { Public } from '../auth/decorators/public.decorator';

@Controller('tournaments')
export class TournamentsController {
  constructor(private tournamentsService: TournamentsService) {}

  /**
   * Get list of tournaments
   * This endpoint will be fully implemented in Slice 2
   */
  @Public()
  @Get()
  async findAll() {
    return this.tournamentsService.findAll();
  }

  /**
   * Get tournament by ID
   * This endpoint will be fully implemented in Slice 2
   */
  @Public()
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.tournamentsService.findOne(id);
  }
}
