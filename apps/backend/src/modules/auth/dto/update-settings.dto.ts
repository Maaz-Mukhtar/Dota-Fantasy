import { IsOptional, IsBoolean, IsString, IsIn } from 'class-validator';

export class UpdateSettingsDto {
  @IsOptional()
  @IsBoolean()
  notifications_enabled?: boolean;

  @IsOptional()
  @IsBoolean()
  notify_match_start?: boolean;

  @IsOptional()
  @IsBoolean()
  notify_match_end?: boolean;

  @IsOptional()
  @IsBoolean()
  notify_roster_lock?: boolean;

  @IsOptional()
  @IsString()
  @IsIn(['system', 'light', 'dark'])
  theme?: string;

  @IsOptional()
  @IsString()
  @IsIn(['en', 'es', 'ru', 'zh', 'pt'])
  language?: string;
}
