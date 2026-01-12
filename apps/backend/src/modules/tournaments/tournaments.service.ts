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
}
