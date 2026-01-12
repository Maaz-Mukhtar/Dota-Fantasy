import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../../integrations/supabase/supabase.service';

export interface TeamFilters {
  region?: string;
}

@Injectable()
export class TeamsService {
  constructor(private supabase: SupabaseService) {}

  async findAll(filters: TeamFilters = {}, page = 1, limit = 20) {
    let query = this.supabase.client
      .from('teams')
      .select('*', { count: 'exact' });

    if (filters.region) {
      query = query.eq('region', filters.region);
    }

    query = query.order('name', { ascending: true });

    const from = (page - 1) * limit;
    const to = from + limit - 1;
    query = query.range(from, to);

    const { data, error, count } = await query;

    if (error) {
      throw new Error(`Failed to fetch teams: ${error.message}`);
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
      .from('teams')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        throw new NotFoundException(`Team with ID ${id} not found`);
      }
      throw new Error(`Failed to fetch team: ${error.message}`);
    }

    return data;
  }

  async findByTournament(tournamentId: string) {
    const { data, error } = await this.supabase.client
      .from('tournament_teams')
      .select(`
        seed,
        group_name,
        placement,
        prize_won,
        team:teams(*)
      `)
      .eq('tournament_id', tournamentId)
      .order('seed', { ascending: true });

    if (error) {
      throw new Error(`Failed to fetch tournament teams: ${error.message}`);
    }

    return data?.map(item => ({
      ...item.team,
      seed: item.seed,
      groupName: item.group_name,
      placement: item.placement,
      prizeWon: item.prize_won,
    })) || [];
  }
}
