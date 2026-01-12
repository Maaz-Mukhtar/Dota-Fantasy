import { Module, Global } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { LiquipediaService } from './liquipedia.service';
import { LiquipediaMatchStageService } from './liquipedia-match-stage.service';
import { LiquipediaController } from './liquipedia.controller';

@Global()
@Module({
  imports: [
    HttpModule.register({
      timeout: 30000,
      maxRedirects: 5,
    }),
  ],
  controllers: [LiquipediaController],
  providers: [LiquipediaService, LiquipediaMatchStageService],
  exports: [LiquipediaService, LiquipediaMatchStageService],
})
export class LiquipediaModule {}
