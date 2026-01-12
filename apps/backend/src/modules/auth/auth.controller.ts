import {
  Controller,
  Get,
  Put,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateSettingsDto } from './dto/update-settings.dto';

@Controller('auth')
@UseGuards(JwtAuthGuard)
export class AuthController {
  constructor(private authService: AuthService) {}

  /**
   * Get current user's profile
   */
  @Get('me')
  async getMe(@Request() req: any) {
    const userId = req.user.id;
    return this.authService.getFullUser(userId);
  }

  /**
   * Get current user's profile only
   */
  @Get('profile')
  async getProfile(@Request() req: any) {
    const userId = req.user.id;
    return this.authService.getProfile(userId);
  }

  /**
   * Update current user's profile
   */
  @Put('profile')
  async updateProfile(
    @Request() req: any,
    @Body() updateProfileDto: UpdateProfileDto,
  ) {
    const userId = req.user.id;
    return this.authService.updateProfile(userId, updateProfileDto);
  }

  /**
   * Get current user's settings
   */
  @Get('settings')
  async getSettings(@Request() req: any) {
    const userId = req.user.id;
    return this.authService.getSettings(userId);
  }

  /**
   * Update current user's settings
   */
  @Put('settings')
  async updateSettings(
    @Request() req: any,
    @Body() updateSettingsDto: UpdateSettingsDto,
  ) {
    const userId = req.user.id;
    return this.authService.updateSettings(userId, updateSettingsDto);
  }
}
