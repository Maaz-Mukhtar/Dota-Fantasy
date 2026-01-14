import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../../integrations/supabase/supabase.service';

export interface TournamentFilters {
  status?: 'upcoming' | 'ongoing' | 'completed';
  tier?: string;
  region?: string;
}

@Injectable()
export class TournamentsService {
  constructor(private supabase: SupabaseService) {}

  async findAll(filters: TournamentFilters = {}, page = 1, limit = 20) {
    let query = this.supabase.client
      .from('tournaments')
      .select('*', { count: 'exact' });

    if (filters.status) {
      query = query.eq('status', filters.status);
    }
    if (filters.tier) {
      query = query.eq('tier', filters.tier);
    }
    if (filters.region) {
      query = query.eq('region', filters.region);
    }

    // Order by start_date, upcoming first
    query = query.order('start_date', { ascending: true });

    // Pagination
    const from = (page - 1) * limit;
    const to = from + limit - 1;
    query = query.range(from, to);

    const { data, error, count } = await query;

    if (error) {
      throw new Error(`Failed to fetch tournaments: ${error.message}`);
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
      .from('tournaments')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        throw new NotFoundException(`Tournament with ID ${id} not found`);
      }
      throw new Error(`Failed to fetch tournament: ${error.message}`);
    }

    return data;
  }

  async getTeams(tournamentId: string) {
    // First verify tournament exists
    await this.findOne(tournamentId);

    const { data, error } = await this.supabase.client
      .from('tournament_teams')
      .select(`
        seed,
        group_name,
        placement,
        prize_won,
        wins,
        losses,
        draws,
        game_wins,
        game_losses,
        team:teams(*)
      `)
      .eq('tournament_id', tournamentId)
      .order('seed', { ascending: true });

    if (error) {
      throw new Error(`Failed to fetch tournament teams: ${error.message}`);
    }

    const teams = data?.map(item => ({
      ...item.team,
      seed: item.seed,
      groupName: item.group_name,
      placement: item.placement,
      prizeWon: item.prize_won,
      wins: item.wins,
      losses: item.losses,
      draws: item.draws,
      gameWins: item.game_wins,
      gameLosses: item.game_losses,
    })) || [];

    return { data: teams };
  }

  async getMatches(
    tournamentId: string,
    filters: { status?: string; stage?: string } = {},
  ) {
    // First verify tournament exists
    await this.findOne(tournamentId);

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

    return { data: data || [] };
  }
}
