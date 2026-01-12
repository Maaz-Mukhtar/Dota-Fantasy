import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { APP_GUARD, APP_FILTER, APP_INTERCEPTOR } from '@nestjs/core';

import { configuration } from './config/configuration';
import { AuthModule } from './modules/auth/auth.module';
import { TournamentsModule } from './modules/tournaments/tournaments.module';
import { TeamsModule } from './modules/teams/teams.module';
import { MatchesModule } from './modules/matches/matches.module';
import { SupabaseModule } from './integrations/supabase/supabase.module';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),

    // Schedule for cron jobs
    ScheduleModule.forRoot(),

    // Integrations
    SupabaseModule,

    // Feature modules
    AuthModule,
    TournamentsModule,
    TeamsModule,
    MatchesModule,
  ],
  providers: [
    // Global JWT guard
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    // Global exception filter
    {
      provide: APP_FILTER,
      useClass: HttpExceptionFilter,
    },
    // Global response transformer
    {
      provide: APP_INTERCEPTOR,
      useClass: TransformInterceptor,
    },
  ],
})
export class AppModule {}
