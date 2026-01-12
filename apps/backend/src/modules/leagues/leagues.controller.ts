import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { LeaguesService, CreateLeagueDto, JoinLeagueDto, UpdateLeagueDto } from './leagues.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Public } from '../auth/decorators/public.decorator';

@Controller('leagues')
@UseGuards(JwtAuthGuard)
export class LeaguesController {
  constructor(private readonly leaguesService: LeaguesService) {}

  @Get()
  async findAll(
    @Request() req: any,
    @Query('tournament_id') tournamentId?: string,
  ) {
    return this.leaguesService.findAll(req.user.sub, { tournament_id: tournamentId });
  }

  @Public()
  @Get('public')
  async findPublic(@Query('tournament_id') tournamentId?: string) {
    return this.leaguesService.findPublic({ tournament_id: tournamentId });
  }

  @Get('invite/:code')
  async findByInviteCode(@Param('code') code: string) {
    return this.leaguesService.findByInviteCode(code);
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @Request() req: any) {
    return this.leaguesService.findOne(id, req.user.sub);
  }

  @Get(':id/leaderboard')
  async getLeaderboard(@Param('id') id: string) {
    return this.leaguesService.getLeaderboard(id);
  }

  @Post()
  async create(@Body() createLeagueDto: CreateLeagueDto, @Request() req: any) {
    return this.leaguesService.create(createLeagueDto, req.user.sub);
  }

  @Post('join')
  async join(@Body() joinLeagueDto: JoinLeagueDto, @Request() req: any) {
    return this.leaguesService.join(joinLeagueDto, req.user.sub);
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() updateLeagueDto: UpdateLeagueDto,
    @Request() req: any,
  ) {
    return this.leaguesService.update(id, updateLeagueDto, req.user.sub);
  }

  @Delete(':id')
  async delete(@Param('id') id: string, @Request() req: any) {
    return this.leaguesService.delete(id, req.user.sub);
  }

  @Delete(':id/leave')
  async leave(@Param('id') id: string, @Request() req: any) {
    return this.leaguesService.leave(id, req.user.sub);
  }
}
