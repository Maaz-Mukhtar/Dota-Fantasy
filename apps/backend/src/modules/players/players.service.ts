import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../../integrations/supabase/supabase.service';

export interface PlayerFilters {
  team_id?: string;
  role?: string;
  tournament_id?: string;
  search?: string;
}

export interface PaginationParams {
  page?: number;
  limit?: number;
}

@Injectable()
export class PlayersService {
  constructor(private readonly supabase: SupabaseService) {}

  async findAll(filters: PlayerFilters = {}, pagination: PaginationParams = {}) {
    const { page = 1, limit = 20 } = pagination;
    const offset = (page - 1) * limit;

    let query = this.supabase.adminClient
      .from('players')
      .select(`
        *,
        team:teams(id, name, tag, logo_url, region)
      `, { count: 'exact' });

    // Apply filters
    if (filters.team_id) {
      query = query.eq('team_id', filters.team_id);
    }

    if (filters.role) {
      query = query.eq('role', filters.role);
    }

    if (filters.search) {
      query = query.or(`nickname.ilike.%${filters.search}%,real_name.ilike.%${filters.search}%`);
    }

    const { data, error, count } = await query
      .order('avg_fantasy_points', { ascending: false, nullsFirst: false })
      .range(offset, offset + limit - 1);

    if (error) {
      throw new BadRequestException(`Failed to fetch players: ${error.message}`);
    }

    return {
      data,
      meta: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    };
  }

  async findByTournament(tournamentId: string, filters: PlayerFilters = {}, pagination: PaginationParams = {}) {
    const { page = 1, limit = 50 } = pagination;
    const offset = (page - 1) * limit;

    let query = this.supabase.adminClient
      .from('tournament_players')
      .select(`
        tournament_id,
        is_active,
        fantasy_value,
        tournament_stats,
        player:players(
          *,
          team:teams(id, name, tag, logo_url, region)
        ),
        team:teams(id, name, tag, logo_url)
      `, { count: 'exact' })
      .eq('tournament_id', tournamentId)
      .eq('is_active', true);

    // Apply filters
    if (filters.team_id) {
      query = query.eq('team_id', filters.team_id);
    }

    if (filters.role) {
      query = query.eq('player.role', filters.role);
    }

    const { data, error, count } = await query
      .range(offset, offset + limit - 1);

    if (error) {
      throw new BadRequestException(`Failed to fetch tournament players: ${error.message}`);
    }

    // Flatten the response
    const players = data?.map((tp: any) => ({
      ...tp.player,
      tournament_team: tp.team,
      fantasy_value: tp.fantasy_value,
      tournament_stats: tp.tournament_stats,
    })) || [];

    return {
      data: players,
      meta: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    };
  }

  async findOne(id: string) {
    const { data, error } = await this.supabase.adminClient
      .from('players')
      .select(`
        *,
        team:teams(id, name, tag, logo_url, region)
      `)
      .eq('id', id)
      .single();

    if (error || !data) {
      throw new NotFoundException('Player not found');
    }

    return data;
  }

  async getPlayerStats(id: string, limit: number = 10) {
    // Get recent match stats for the player
    const { data: stats, error: statsError } = await this.supabase.adminClient
      .from('player_stats')
      .select(`
        *,
        game:games(
          id,
          game_number,
          match:matches(
            id,
            scheduled_at,
            team1:teams!matches_team1_id_fkey(id, name, tag),
            team2:teams!matches_team2_id_fkey(id, name, tag),
            tournament:tournaments(id, name)
          )
        )
      `)
      .eq('player_id', id)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (statsError) {
      throw new BadRequestException(`Failed to fetch player stats: ${statsError.message}`);
    }

    // Calculate aggregates
    const { data: aggregates, error: aggError } = await this.supabase.adminClient
      .from('player_stats')
      .select('kills, deaths, assists, gpm, xpm, last_hits, fantasy_points, is_winner')
      .eq('player_id', id);

    if (aggError) {
      throw new BadRequestException(`Failed to fetch player aggregates: ${aggError.message}`);
    }

    let averages = null;
    if (aggregates && aggregates.length > 0) {
      const totalGames = aggregates.length;
      const wins = aggregates.filter((g: any) => g.is_winner).length;

      averages = {
        total_games: totalGames,
        wins,
        losses: totalGames - wins,
        win_rate: totalGames > 0 ? (wins / totalGames * 100).toFixed(1) : 0,
        avg_kills: (aggregates.reduce((sum: number, g: any) => sum + (g.kills || 0), 0) / totalGames).toFixed(2),
        avg_deaths: (aggregates.reduce((sum: number, g: any) => sum + (g.deaths || 0), 0) / totalGames).toFixed(2),
        avg_assists: (aggregates.reduce((sum: number, g: any) => sum + (g.assists || 0), 0) / totalGames).toFixed(2),
        avg_gpm: (aggregates.reduce((sum: number, g: any) => sum + (g.gpm || 0), 0) / totalGames).toFixed(0),
        avg_xpm: (aggregates.reduce((sum: number, g: any) => sum + (g.xpm || 0), 0) / totalGames).toFixed(0),
        avg_last_hits: (aggregates.reduce((sum: number, g: any) => sum + (g.last_hits || 0), 0) / totalGames).toFixed(0),
        avg_fantasy_points: (aggregates.reduce((sum: number, g: any) => sum + (g.fantasy_points || 0), 0) / totalGames).toFixed(2),
        total_fantasy_points: aggregates.reduce((sum: number, g: any) => sum + (g.fantasy_points || 0), 0).toFixed(2),
      };
    }

    return {
      recent_games: stats || [],
      averages,
    };
  }

  async getPlayerFantasyAverage(id: string, tournamentId?: string) {
    let query = this.supabase.adminClient
      .from('player_stats')
      .select('fantasy_points');

    query = query.eq('player_id', id);

    // If tournament specified, filter by tournament matches
    if (tournamentId) {
      const { data: matchIds } = await this.supabase.adminClient
        .from('matches')
        .select('id')
        .eq('tournament_id', tournamentId);

      if (matchIds && matchIds.length > 0) {
        query = query.in('match_id', matchIds.map((m: any) => m.id));
      }
    }

    const { data, error } = await query;

    if (error) {
      throw new BadRequestException(`Failed to fetch fantasy average: ${error.message}`);
    }

    if (!data || data.length === 0) {
      return {
        average: 0,
        total_games: 0,
        total_points: 0,
      };
    }

    const totalPoints = data.reduce((sum: number, g: any) => sum + (g.fantasy_points || 0), 0);
    const totalGames = data.length;

    return {
      average: (totalPoints / totalGames).toFixed(2),
      total_games: totalGames,
      total_points: totalPoints.toFixed(2),
    };
  }

  async findByTeam(teamId: string) {
    const { data, error } = await this.supabase.adminClient
      .from('players')
      .select(`
        *,
        team:teams(id, name, tag, logo_url, region)
      `)
      .eq('team_id', teamId)
      .order('role', { ascending: true });

    if (error) {
      throw new BadRequestException(`Failed to fetch team players: ${error.message}`);
    }

    return data || [];
  }
}
