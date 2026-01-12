import { Injectable, UnauthorizedException } from '@nestjs/common';
import { SupabaseService } from '../../integrations/supabase/supabase.service';

export interface UserProfile {
  id: string;
  username: string;
  display_name: string | null;
  avatar_url: string | null;
  bio: string | null;
  subscription_tier: string;
  subscription_expires: string | null;
  total_fantasy_points: number;
  tournaments_played: number;
  created_at: string;
  updated_at: string;
}

export interface UserSettings {
  user_id: string;
  notifications_enabled: boolean;
  notify_match_start: boolean;
  notify_match_end: boolean;
  notify_roster_lock: boolean;
  theme: string;
  language: string;
}

@Injectable()
export class AuthService {
  constructor(private supabase: SupabaseService) {}

  /**
   * Validate a JWT token and return the user
   */
  async validateToken(token: string) {
    const user = await this.supabase.validateToken(token);

    if (!user) {
      throw new UnauthorizedException('Invalid token');
    }

    return user;
  }

  /**
   * Get user profile with auth user data
   */
  async getProfile(userId: string): Promise<UserProfile> {
    const profile = await this.supabase.getUserProfile(userId);
    return profile as UserProfile;
  }

  /**
   * Update user profile
   */
  async updateProfile(
    userId: string,
    updates: Partial<Pick<UserProfile, 'display_name' | 'avatar_url' | 'bio'>>,
  ): Promise<UserProfile> {
    const profile = await this.supabase.updateUserProfile(userId, updates);
    return profile as UserProfile;
  }

  /**
   * Get user settings
   */
  async getSettings(userId: string): Promise<UserSettings> {
    const settings = await this.supabase.getUserSettings(userId);
    return settings as UserSettings;
  }

  /**
   * Update user settings
   */
  async updateSettings(
    userId: string,
    updates: Partial<Omit<UserSettings, 'user_id'>>,
  ): Promise<UserSettings> {
    const settings = await this.supabase.updateUserSettings(userId, updates);
    return settings as UserSettings;
  }

  /**
   * Get full user data (profile + settings + auth)
   */
  async getFullUser(userId: string) {
    const [profile, settings] = await Promise.all([
      this.getProfile(userId),
      this.getSettings(userId),
    ]);

    return {
      ...profile,
      settings,
    };
  }
}
