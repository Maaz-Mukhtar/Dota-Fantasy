import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../../integrations/supabase/supabase.service';

export interface CreateLeagueDto {
  name: string;
  tournament_id: string;
  max_members?: number;
  is_public?: boolean;
  draft_date?: string;
}

export interface JoinLeagueDto {
  invite_code: string;
  team_name?: string;
}

export interface UpdateLeagueDto {
  name?: string;
  max_members?: number;
  is_public?: boolean;
  draft_date?: string;
  draft_status?: string;
}

@Injectable()
export class LeaguesService {
  constructor(private readonly supabase: SupabaseService) {}

  async findAll(userId: string, filters: { tournament_id?: string } = {}) {
    // First get the league IDs where the user is a member
    // Use adminClient to bypass RLS since we already validated auth
    const { data: membershipData, error: membershipError } = await this.supabase.adminClient
      .from('league_members')
      .select('league_id, user_id, role, team_name, total_points, rank')
      .eq('user_id', userId);

    if (membershipError) {
      throw new BadRequestException(`Failed to fetch memberships: ${membershipError.message}`);
    }

    // If user has no memberships, return empty array
    if (!membershipData || membershipData.length === 0) {
      return [];
    }

    const leagueIds = membershipData.map((m) => m.league_id);

    // Now fetch the leagues
    let query = this.supabase.adminClient
      .from('leagues')
      .select(`
        *,
        tournament:tournaments(*),
        members:league_members(count)
      `)
      .in('id', leagueIds);

    if (filters.tournament_id) {
      query = query.eq('tournament_id', filters.tournament_id);
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) {
      throw new BadRequestException(`Failed to fetch leagues: ${error.message}`);
    }

    // Create a map of league_id -> membership for quick lookup
    const membershipMap = new Map(
      membershipData.map((m) => [m.league_id, m])
    );

    // Attach my_membership to each league
    const leaguesWithMembership = data?.map((league) => ({
      ...league,
      my_membership: membershipMap.get(league.id) ? [membershipMap.get(league.id)] : [],
    }));

    return leaguesWithMembership;
  }

  async findPublic(filters: { tournament_id?: string } = {}) {
    let query = this.supabase.adminClient
      .from('leagues')
      .select(`
        *,
        tournament:tournaments(id, name, tier, status),
        members:league_members(count)
      `)
      .eq('is_public', true);

    if (filters.tournament_id) {
      query = query.eq('tournament_id', filters.tournament_id);
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) {
      throw new BadRequestException(`Failed to fetch public leagues: ${error.message}`);
    }

    return data;
  }

  async findOne(id: string, userId: string) {
    const { data, error } = await this.supabase.adminClient
      .from('leagues')
      .select(`
        *,
        tournament:tournaments(*),
        members:league_members(
          id,
          user_id,
          role,
          team_name,
          total_points,
          rank,
          joined_at
        )
      `)
      .eq('id', id)
      .single();

    if (error || !data) {
      throw new NotFoundException('League not found');
    }

    // Check if user is a member
    const leagueData = data as any;
    const isMember = leagueData.members?.some((m: any) => m.user_id === userId);
    if (!leagueData.is_public && !isMember) {
      throw new ForbiddenException('You are not a member of this league');
    }

    // Find and attach user's membership
    const myMembership = leagueData.members?.find((m: any) => m.user_id === userId);
    if (myMembership) {
      leagueData.my_membership = [myMembership];
    }

    return leagueData;
  }

  async findByInviteCode(inviteCode: string) {
    const { data, error } = await this.supabase.adminClient
      .from('leagues')
      .select(`
        *,
        tournament:tournaments(id, name, tier, status, start_date, end_date),
        members:league_members(count)
      `)
      .eq('invite_code', inviteCode.toUpperCase())
      .single();

    if (error || !data) {
      throw new NotFoundException('League not found with this invite code');
    }

    return data;
  }

  async create(createLeagueDto: CreateLeagueDto, userId: string) {
    // Verify tournament exists
    const { data: tournament, error: tournamentError } = await this.supabase.adminClient
      .from('tournaments')
      .select('id, name, status')
      .eq('id', createLeagueDto.tournament_id)
      .single();

    if (tournamentError || !tournament) {
      throw new NotFoundException('Tournament not found');
    }

    const { data, error } = await this.supabase.adminClient
      .from('leagues')
      .insert({
        name: createLeagueDto.name,
        tournament_id: createLeagueDto.tournament_id,
        owner_id: userId,
        max_members: createLeagueDto.max_members || 10,
        is_public: createLeagueDto.is_public || false,
        draft_date: createLeagueDto.draft_date,
      })
      .select(`
        *,
        tournament:tournaments(*)
      `)
      .single();

    if (error) {
      throw new BadRequestException(`Failed to create league: ${error.message}`);
    }

    return data;
  }

  async join(joinLeagueDto: JoinLeagueDto, userId: string) {
    // Find league by invite code
    const { data: league, error: leagueError } = await this.supabase.adminClient
      .from('leagues')
      .select(`
        *,
        members:league_members(count)
      `)
      .eq('invite_code', joinLeagueDto.invite_code.toUpperCase())
      .single();

    if (leagueError || !league) {
      throw new NotFoundException('Invalid invite code');
    }

    // Check if already a member
    const { data: existingMember } = await this.supabase.adminClient
      .from('league_members')
      .select('id')
      .eq('league_id', league.id)
      .eq('user_id', userId)
      .single();

    if (existingMember) {
      throw new BadRequestException('You are already a member of this league');
    }

    // Check if league is full
    const memberCount = league.members?.[0]?.count || 0;
    if (memberCount >= league.max_members) {
      throw new BadRequestException('This league is full');
    }

    // Check if draft has started
    if (league.draft_status !== 'pending') {
      throw new BadRequestException('Cannot join league after draft has started');
    }

    // Join the league
    const { data, error } = await this.supabase.adminClient
      .from('league_members')
      .insert({
        league_id: league.id,
        user_id: userId,
        role: 'member',
        team_name: joinLeagueDto.team_name || 'My Team',
      })
      .select()
      .single();

    if (error) {
      throw new BadRequestException(`Failed to join league: ${error.message}`);
    }

    return { membership: data, league };
  }

  async update(id: string, updateLeagueDto: UpdateLeagueDto, userId: string) {
    // Check ownership
    const { data: league } = await this.supabase.adminClient
      .from('leagues')
      .select('owner_id')
      .eq('id', id)
      .single();

    if (!league || league.owner_id !== userId) {
      throw new ForbiddenException('Only the league owner can update the league');
    }

    const { data, error } = await this.supabase.adminClient
      .from('leagues')
      .update({
        ...updateLeagueDto,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      throw new BadRequestException(`Failed to update league: ${error.message}`);
    }

    return data;
  }

  async leave(id: string, userId: string) {
    // Check if user is the owner
    const { data: league } = await this.supabase.adminClient
      .from('leagues')
      .select('owner_id')
      .eq('id', id)
      .single();

    if (league?.owner_id === userId) {
      throw new BadRequestException('League owner cannot leave. Transfer ownership or delete the league.');
    }

    const { error } = await this.supabase.adminClient
      .from('league_members')
      .delete()
      .eq('league_id', id)
      .eq('user_id', userId);

    if (error) {
      throw new BadRequestException(`Failed to leave league: ${error.message}`);
    }

    return { success: true };
  }

  async delete(id: string, userId: string) {
    // Check ownership
    const { data: league } = await this.supabase.adminClient
      .from('leagues')
      .select('owner_id')
      .eq('id', id)
      .single();

    if (!league || league.owner_id !== userId) {
      throw new ForbiddenException('Only the league owner can delete the league');
    }

    const { error } = await this.supabase.adminClient
      .from('leagues')
      .delete()
      .eq('id', id);

    if (error) {
      throw new BadRequestException(`Failed to delete league: ${error.message}`);
    }

    return { success: true };
  }

  async getLeaderboard(id: string) {
    const { data, error } = await this.supabase.adminClient
      .from('league_members')
      .select(`
        id,
        user_id,
        team_name,
        total_points,
        rank,
        role
      `)
      .eq('league_id', id)
      .order('total_points', { ascending: false });

    if (error) {
      throw new BadRequestException(`Failed to fetch leaderboard: ${error.message}`);
    }

    // Calculate ranks
    const rankedData = data?.map((member, index) => ({
      ...member,
      rank: index + 1,
    }));

    return rankedData;
  }
}
