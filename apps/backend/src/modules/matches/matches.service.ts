import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../../integrations/supabase/supabase.service';

export interface MatchFilters {
  status?: 'scheduled' | 'live' | 'completed' | 'postponed' | 'cancelled';
  stage?: string;
}

@Injectable()
export class MatchesService {
  constructor(private supabase: SupabaseService) {}

  async findAll(filters: MatchFilters = {}, page = 1, limit = 20) {
    let query = this.supabase.client
      .from('matches')
      .select(`
        *,
        team1:teams!matches_team1_id_fkey(*),
        team2:teams!matches_team2_id_fkey(*),
        winner:teams!matches_winner_id_fkey(*)
      `, { count: 'exact' });

    if (filters.status) {
      query = query.eq('status', filters.status);
    }

    if (filters.stage) {
      query = query.eq('stage', filters.stage);
    }

    query = query.order('scheduled_at', { ascending: true });

    const from = (page - 1) * limit;
    const to = from + limit - 1;
    query = query.range(from, to);

    const { data, error, count } = await query;

    if (error) {
      throw new Error(`Failed to fetch matches: ${error.message}`);
    }

    return {
      data: data || [],
      meta: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    };
  }

  async findOne(id: string) {
    const { data, error } = await this.supabase.client
      .from('matches')
      .select(`
        *,
        team1:teams!matches_team1_id_fkey(*),
        team2:teams!matches_team2_id_fkey(*),
        winner:teams!matches_winner_id_fkey(*)
      `)
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        throw new NotFoundException(`Match with ID ${id} not found`);
      }
      throw new Error(`Failed to fetch match: ${error.message}`);
    }

    return data;
  }

  async findByTournament(tournamentId: string, filters: MatchFilters = {}) {
    let query = this.supabase.client
      .from('matches')
      .select(`
        *,
        team1:teams!matches_team1_id_fkey(*),
        team2:teams!matches_team2_id_fkey(*),
        winner:teams!matches_winner_id_fkey(*)
      `)
      .eq('tournament_id', tournamentId);

    if (filters.status) {
      query = query.eq('status', filters.status);
    }

    if (filters.stage) {
      query = query.eq('stage', filters.stage);
    }

    query = query.order('scheduled_at', { ascending: true });

    const { data, error } = await query;

    if (error) {
      throw new Error(`Failed to fetch tournament matches: ${error.message}`);
    }

    return data || [];
  }

  async getLiveMatches() {
    const { data, error } = await this.supabase.client
      .from('matches')
      .select(`
        *,
        team1:teams!matches_team1_id_fkey(*),
        team2:teams!matches_team2_id_fkey(*),
        tournament:tournaments(id, name, tier)
      `)
      .eq('status', 'live')
      .order('started_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch live matches: ${error.message}`);
    }

    return data || [];
  }
}
