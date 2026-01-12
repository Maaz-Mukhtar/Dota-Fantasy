import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { StratzService } from './stratz.service';
import { StratzController } from './stratz.controller';

@Module({
  imports: [ConfigModule],
  controllers: [StratzController],
  providers: [StratzService],
  exports: [StratzService],
})
export class StratzModule {}
