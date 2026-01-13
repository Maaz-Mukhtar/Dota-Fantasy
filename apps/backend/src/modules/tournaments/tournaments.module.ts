import { Module } from '@nestjs/common';
import { TournamentsController } from './tournaments.controller';
import { TournamentsService } from './tournaments.service';
import { TournamentDataService } from './tournament-data.service';
import { LiquipediaModule } from '../../integrations/liquipedia/liquipedia.module';
import { StratzModule } from '../../integrations/stratz/stratz.module';

@Module({
  imports: [LiquipediaModule, StratzModule],
  controllers: [TournamentsController],
  providers: [TournamentsService, TournamentDataService],
  exports: [TournamentsService, TournamentDataService],
})
export class TournamentsModule {}
