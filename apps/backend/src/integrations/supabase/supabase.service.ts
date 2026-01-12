import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService implements OnModuleInit {
  private supabaseClient: SupabaseClient;
  private serviceRoleClient: SupabaseClient;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const supabaseUrl = this.configService.get<string>('supabase.url');
    const anonKey = this.configService.get<string>('supabase.anonKey');
    const serviceRoleKey = this.configService.get<string>(
      'supabase.serviceRoleKey',
    );

    if (!supabaseUrl || !anonKey) {
      throw new Error('Supabase URL and Anon Key are required');
    }

    // Client for user-facing operations (respects RLS)
    this.supabaseClient = createClient(supabaseUrl, anonKey);

    // Service role client for admin operations (bypasses RLS)
    if (serviceRoleKey) {
      this.serviceRoleClient = createClient(supabaseUrl, serviceRoleKey, {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      });
    }
  }

  /**
   * Get the Supabase client (respects RLS)
   */
  get client(): SupabaseClient {
    return this.supabaseClient;
  }

  /**
   * Get the service role client (bypasses RLS)
   * Use with caution - only for admin operations
   */
  get adminClient(): SupabaseClient {
    if (!this.serviceRoleClient) {
      throw new Error('Service role client not initialized');
    }
    return this.serviceRoleClient;
  }

  /**
   * Validate a JWT token and return the user
   */
  async validateToken(token: string) {
    const { data, error } = await this.supabaseClient.auth.getUser(token);

    if (error || !data.user) {
      return null;
    }

    return data.user;
  }

  /**
   * Get user profile from the database
   */
  async getUserProfile(userId: string) {
    const { data, error } = await this.adminClient
      .from('user_profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) {
      throw error;
    }

    return data;
  }

  /**
   * Update user profile
   */
  async updateUserProfile(
    userId: string,
    updates: Record<string, unknown>,
  ) {
    const { data, error } = await this.adminClient
      .from('user_profiles')
      .update({
        ...updates,
        updated_at: new Date().toISOString(),
      })
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      throw error;
    }

    return data;
  }

  /**
   * Get user settings
   */
  async getUserSettings(userId: string) {
    const { data, error } = await this.adminClient
      .from('user_settings')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error) {
      throw error;
    }

    return data;
  }

  /**
   * Update user settings
   */
  async updateUserSettings(
    userId: string,
    updates: Record<string, unknown>,
  ) {
    const { data, error } = await this.adminClient
      .from('user_settings')
      .update(updates)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) {
      throw error;
    }

    return data;
  }
}
