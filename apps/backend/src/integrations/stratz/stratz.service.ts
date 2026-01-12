import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  StratzMatch,
  StratzLeague,
  StratzProPlayer,
  StratzPlayer,
  StratzLiveMatch,
  StratzGraphQLResponse,
  StratzMatchPlayer,
  PlayerMatchStats,
  LeagueMatchSummary,
  ProPlayerMapping,
  StratzPosition,
} from './stratz.types';
import {
  MATCH_STATS_QUERY,
  LEAGUE_MATCHES_QUERY,
  LEAGUE_INFO_QUERY,
  PRO_PLAYERS_QUERY,
  PLAYER_BY_STEAM_ID_QUERY,
  PLAYER_MATCHES_QUERY,
  LIVE_MATCHES_QUERY,
  LEAGUE_LIVE_MATCHES_QUERY,
  TEAM_INFO_QUERY,
  SERIES_MATCHES_QUERY,
  MULTIPLE_MATCHES_QUERY,
} from './stratz.queries';

@Injectable()
export class StratzService {
  private readonly logger = new Logger(StratzService.name);
  private readonly baseUrl = 'https://api.stratz.com/graphql';
  private readonly apiToken: string;

  // Rate limiting: 2000 requests/hour for free tier
  private readonly minRequestInterval = 2000; // 2 seconds between requests
  private lastRequestTime = 0;

  // Cache for pro players (expensive to fetch)
  private proPlayersCache: Map<number, ProPlayerMapping> = new Map();
  private proPlayersCacheTime = 0;
  private readonly proPlayersCacheDuration = 24 * 60 * 60 * 1000; // 24 hours

  constructor(private configService: ConfigService) {
    this.apiToken = this.configService.get<string>('STRATZ_API_TOKEN') || '';
    if (!this.apiToken) {
      this.logger.warn('STRATZ_API_TOKEN not configured');
    }
  }

  /**
   * Execute a GraphQL query against STRATZ API
   */
  private async executeQuery<T>(
    query: string,
    variables: Record<string, unknown> = {},
  ): Promise<T> {
    // Rate limiting
    const now = Date.now();
    const timeSinceLastRequest = now - this.lastRequestTime;
    if (timeSinceLastRequest < this.minRequestInterval) {
      await this.delay(this.minRequestInterval - timeSinceLastRequest);
    }
    this.lastRequestTime = Date.now();

    const response = await fetch(this.baseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiToken}`,
        'User-Agent': 'Dota2FantasyApp/1.0',
      },
      body: JSON.stringify({ query, variables }),
    });

    if (!response.ok) {
      throw new Error(`STRATZ API error: ${response.status} ${response.statusText}`);
    }

    const result: StratzGraphQLResponse<T> = await response.json();

    if (result.errors && result.errors.length > 0) {
      const errorMessages = result.errors.map((e) => e.message).join(', ');
      throw new Error(`STRATZ GraphQL errors: ${errorMessages}`);
    }

    if (!result.data) {
      throw new Error('STRATZ API returned no data');
    }

    return result.data;
  }

  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  // ============ Match Methods ============

  /**
   * Get detailed statistics for a single match
   */
  async getMatchStats(matchId: number): Promise<StratzMatch | null> {
    this.logger.log(`Fetching match stats for match ${matchId}`);

    try {
      const data = await this.executeQuery<{ match: StratzMatch }>(
        MATCH_STATS_QUERY,
        { matchId },
      );
      return data.match;
    } catch (error) {
      this.logger.error(`Error fetching match ${matchId}:`, error);
      return null;
    }
  }

  /**
   * Get stats for multiple matches
   */
  async getMultipleMatchStats(matchIds: number[]): Promise<StratzMatch[]> {
    this.logger.log(`Fetching stats for ${matchIds.length} matches`);

    try {
      const data = await this.executeQuery<{ matches: StratzMatch[] }>(
        MULTIPLE_MATCHES_QUERY,
        { matchIds },
      );
      return data.matches || [];
    } catch (error) {
      this.logger.error('Error fetching multiple matches:', error);
      return [];
    }
  }

  /**
   * Get all matches for a series (Bo3, Bo5, etc.)
   */
  async getSeriesMatches(seriesId: number): Promise<StratzMatch[]> {
    this.logger.log(`Fetching series ${seriesId}`);

    try {
      const data = await this.executeQuery<{
        series: { matches: StratzMatch[] };
      }>(SERIES_MATCHES_QUERY, { seriesId });
      return data.series?.matches || [];
    } catch (error) {
      this.logger.error(`Error fetching series ${seriesId}:`, error);
      return [];
    }
  }

  // ============ League Methods ============

  /**
   * Get all matches for a league/tournament
   */
  async getLeagueMatches(
    leagueId: number,
    take = 100,
    skip = 0,
  ): Promise<LeagueMatchSummary[]> {
    this.logger.log(`Fetching matches for league ${leagueId}`);

    try {
      const data = await this.executeQuery<{ league: StratzLeague }>(
        LEAGUE_MATCHES_QUERY,
        { leagueId, take, skip },
      );

      if (!data.league?.matches) {
        return [];
      }

      return data.league.matches.map((match) => ({
        matchId: match.id,
        radiantTeam: {
          id: match.radiantTeam?.id || 0,
          name: match.radiantTeam?.name || 'Unknown',
          tag: match.radiantTeam?.tag,
        },
        direTeam: {
          id: match.direTeam?.id || 0,
          name: match.direTeam?.name || 'Unknown',
          tag: match.direTeam?.tag,
        },
        radiantWin: match.didRadiantWin,
        durationSeconds: match.durationSeconds,
        startDateTime: match.startDateTime || 0,
        seriesId: match.series?.id,
        seriesType: match.series?.type,
      }));
    } catch (error) {
      this.logger.error(`Error fetching league ${leagueId} matches:`, error);
      return [];
    }
  }

  /**
   * Get comprehensive league info including standings and brackets
   */
  async getLeagueInfo(leagueId: number): Promise<StratzLeague | null> {
    this.logger.log(`Fetching league info for ${leagueId}`);

    try {
      const data = await this.executeQuery<{ league: StratzLeague }>(
        LEAGUE_INFO_QUERY,
        { leagueId },
      );
      return data.league;
    } catch (error) {
      this.logger.error(`Error fetching league ${leagueId}:`, error);
      return null;
    }
  }

  /**
   * Get all league matches with full stats (paginated)
   */
  async getAllLeagueMatchesWithStats(leagueId: number): Promise<StratzMatch[]> {
    this.logger.log(`Fetching all matches with stats for league ${leagueId}`);

    const allMatches: StratzMatch[] = [];
    let skip = 0;
    const take = 100;
    let hasMore = true;

    while (hasMore) {
      const summaries = await this.getLeagueMatches(leagueId, take, skip);

      if (summaries.length === 0) {
        hasMore = false;
        break;
      }

      // Fetch full stats for each match
      const matchIds = summaries.map((s) => s.matchId);
      const matches = await this.getMultipleMatchStats(matchIds);
      allMatches.push(...matches);

      skip += take;
      hasMore = summaries.length === take;
    }

    return allMatches;
  }

  // ============ Player Methods ============

  /**
   * Get all pro players (cached)
   */
  async getProPlayers(forceRefresh = false): Promise<ProPlayerMapping[]> {
    const now = Date.now();

    // Check cache
    if (
      !forceRefresh &&
      this.proPlayersCache.size > 0 &&
      now - this.proPlayersCacheTime < this.proPlayersCacheDuration
    ) {
      return Array.from(this.proPlayersCache.values());
    }

    this.logger.log('Fetching all pro players from STRATZ');

    const allPlayers: ProPlayerMapping[] = [];
    let skip = 0;
    const take = 500;
    let hasMore = true;

    while (hasMore) {
      try {
        const data = await this.executeQuery<{
          proSteamAccounts: StratzProPlayer[];
        }>(PRO_PLAYERS_QUERY, { take, skip });

        const players = data.proSteamAccounts || [];

        if (players.length === 0) {
          hasMore = false;
          break;
        }

        for (const player of players) {
          const mapping: ProPlayerMapping = {
            steamAccountId: player.steamAccountId,
            name: player.name,
            realName: player.realName,
            teamId: player.team?.id,
            teamName: player.team?.name,
            teamTag: player.team?.tag,
            position: this.mapPosition(player.position),
            country: player.countries?.[0],
          };

          allPlayers.push(mapping);
          this.proPlayersCache.set(player.steamAccountId, mapping);
        }

        skip += take;
        hasMore = players.length === take;
      } catch (error) {
        this.logger.error('Error fetching pro players:', error);
        hasMore = false;
      }
    }

    this.proPlayersCacheTime = now;
    this.logger.log(`Cached ${allPlayers.length} pro players`);

    return allPlayers;
  }

  /**
   * Find pro player by nickname (fuzzy match)
   */
  async findProPlayerByNickname(nickname: string): Promise<ProPlayerMapping | null> {
    await this.getProPlayers(); // Ensure cache is populated

    const normalizedNickname = nickname.toLowerCase().trim();

    for (const player of this.proPlayersCache.values()) {
      if (player.name.toLowerCase() === normalizedNickname) {
        return player;
      }
    }

    // Fuzzy match - check if nickname is contained
    for (const player of this.proPlayersCache.values()) {
      if (
        player.name.toLowerCase().includes(normalizedNickname) ||
        normalizedNickname.includes(player.name.toLowerCase())
      ) {
        return player;
      }
    }

    return null;
  }

  /**
   * Get player info by Steam ID
   */
  async getPlayerBySteamId(steamAccountId: number): Promise<StratzPlayer | null> {
    this.logger.log(`Fetching player ${steamAccountId}`);

    try {
      const data = await this.executeQuery<{ player: StratzPlayer }>(
        PLAYER_BY_STEAM_ID_QUERY,
        { steamAccountId },
      );
      return data.player;
    } catch (error) {
      this.logger.error(`Error fetching player ${steamAccountId}:`, error);
      return null;
    }
  }

  /**
   * Get recent matches for a player
   */
  async getPlayerMatches(
    steamAccountId: number,
    take = 50,
    leagueId?: number,
  ): Promise<StratzMatch[]> {
    this.logger.log(`Fetching matches for player ${steamAccountId}`);

    try {
      const variables: Record<string, unknown> = { steamAccountId, take };
      if (leagueId) {
        variables.leagueId = leagueId;
      }

      const data = await this.executeQuery<{
        player: { matches: StratzMatch[] };
      }>(PLAYER_MATCHES_QUERY, variables);

      return data.player?.matches || [];
    } catch (error) {
      this.logger.error(`Error fetching player ${steamAccountId} matches:`, error);
      return [];
    }
  }

  // ============ Live Match Methods ============

  /**
   * Get all live matches
   */
  async getLiveMatches(): Promise<StratzLiveMatch[]> {
    this.logger.log('Fetching live matches');

    try {
      const data = await this.executeQuery<{
        live: { matches: StratzLiveMatch[] };
      }>(LIVE_MATCHES_QUERY);

      return data.live?.matches || [];
    } catch (error) {
      this.logger.error('Error fetching live matches:', error);
      return [];
    }
  }

  /**
   * Get live matches for a specific league
   */
  async getLeagueLiveMatches(leagueId: number): Promise<StratzLiveMatch[]> {
    this.logger.log(`Fetching live matches for league ${leagueId}`);

    try {
      const data = await this.executeQuery<{
        live: { matches: StratzLiveMatch[] };
      }>(LEAGUE_LIVE_MATCHES_QUERY, { leagueId });

      return data.live?.matches || [];
    } catch (error) {
      this.logger.error(`Error fetching live matches for league ${leagueId}:`, error);
      return [];
    }
  }

  // ============ Team Methods ============

  /**
   * Get team info and recent matches
   */
  async getTeamInfo(teamId: number): Promise<unknown> {
    this.logger.log(`Fetching team ${teamId}`);

    try {
      const data = await this.executeQuery<{ team: unknown }>(TEAM_INFO_QUERY, {
        teamId,
      });
      return data.team;
    } catch (error) {
      this.logger.error(`Error fetching team ${teamId}:`, error);
      return null;
    }
  }

  // ============ Fantasy Points Calculation ============

  /**
   * Extract player stats from a match for fantasy points calculation
   */
  extractPlayerStats(
    match: StratzMatch,
    gameNumber = 1,
  ): PlayerMatchStats[] {
    const stats: PlayerMatchStats[] = [];

    for (const player of match.players) {
      const campsStacked = player.stats?.campStack
        ? player.stats.campStack.reduce((a, b) => a + b, 0)
        : 0;

      const stunDuration =
        player.stats?.heroDamageReport?.dealtTotal?.stunDuration || 0;

      const obsPlaced = player.stats?.observerWardsPlaced || 0;

      // Determine if player got first blood
      // First blood is usually given to the player with award = 'firstblood'
      const firstBlood = player.award === 'firstblood';

      const playerStats: PlayerMatchStats = {
        playerId: '', // Will be mapped later
        steamAccountId: player.steamAccountId,
        matchId: match.id,
        gameNumber,
        kills: player.kills,
        deaths: player.deaths,
        assists: player.assists,
        lastHits: player.numLastHits,
        denies: player.numDenies,
        gpm: player.goldPerMinute,
        xpm: player.experiencePerMinute,
        heroDamage: player.heroDamage,
        towerDamage: player.towerDamage,
        heroHealing: player.heroHealing,
        stuns: stunDuration,
        obsPlaced,
        campsStacked,
        firstBlood,
        heroId: player.heroId,
        isWinner: player.isVictory,
        isRadiant: player.isRadiant,
      };

      // Calculate fantasy points
      playerStats.fantasyPoints = this.calculateFantasyPoints(playerStats);

      stats.push(playerStats);
    }

    return stats;
  }

  /**
   * Calculate fantasy points for a player's match performance
   * Based on the scoring rules from plan.md
   */
  calculateFantasyPoints(stats: PlayerMatchStats): number {
    const points = {
      kills: stats.kills * 0.3,
      deaths: stats.deaths * -0.3,
      assists: stats.assists * 0.15,
      lastHits: stats.lastHits * 0.003,
      gpm: stats.gpm * 0.002,
      xpm: stats.xpm * 0.001,
      towerDamage: stats.towerDamage * 0.001,
      heroDamage: stats.heroDamage * 0.0001,
      heroHealing: stats.heroHealing * 0.0002,
      stuns: stats.stuns * 0.05,
      obsPlaced: stats.obsPlaced * 0.25,
      campsStacked: stats.campsStacked * 0.3,
      firstBlood: stats.firstBlood ? 1.0 : 0,
      winBonus: stats.isWinner ? 3.0 : 0,
    };

    return Object.values(points).reduce((a, b) => a + b, 0);
  }

  // ============ Helper Methods ============

  /**
   * Map STRATZ position enum to role string
   */
  private mapPosition(position?: StratzPosition): string | undefined {
    if (!position) return undefined;

    const positionMap: Record<StratzPosition, string> = {
      [StratzPosition.POSITION_1]: 'carry',
      [StratzPosition.POSITION_2]: 'mid',
      [StratzPosition.POSITION_3]: 'offlane',
      [StratzPosition.POSITION_4]: 'support4',
      [StratzPosition.POSITION_5]: 'support5',
      [StratzPosition.UNKNOWN]: 'unknown',
    };

    return positionMap[position];
  }

  /**
   * Map player nickname to Steam ID using cached pro players
   */
  async mapNicknameToSteamId(nickname: string): Promise<number | null> {
    const player = await this.findProPlayerByNickname(nickname);
    return player?.steamAccountId || null;
  }

  /**
   * Map multiple nicknames to Steam IDs
   */
  async mapNicknamesToSteamIds(
    nicknames: string[],
  ): Promise<Map<string, number>> {
    await this.getProPlayers(); // Ensure cache is populated

    const result = new Map<string, number>();

    for (const nickname of nicknames) {
      const player = await this.findProPlayerByNickname(nickname);
      if (player) {
        result.set(nickname, player.steamAccountId);
      }
    }

    return result;
  }

  /**
   * Get match stats with player fantasy points calculated
   */
  async getMatchWithFantasyPoints(matchId: number): Promise<{
    match: StratzMatch;
    playerStats: PlayerMatchStats[];
  } | null> {
    const match = await this.getMatchStats(matchId);
    if (!match) return null;

    const playerStats = this.extractPlayerStats(match);

    return { match, playerStats };
  }

  /**
   * Get all player stats for a tournament
   */
  async getTournamentPlayerStats(
    leagueId: number,
  ): Promise<Map<number, PlayerMatchStats[]>> {
    this.logger.log(`Fetching all player stats for league ${leagueId}`);

    const playerStatsMap = new Map<number, PlayerMatchStats[]>();
    const matches = await this.getAllLeagueMatchesWithStats(leagueId);

    let gameNumber = 1;
    for (const match of matches) {
      const stats = this.extractPlayerStats(match, gameNumber);

      for (const stat of stats) {
        const existing = playerStatsMap.get(stat.steamAccountId) || [];
        existing.push(stat);
        playerStatsMap.set(stat.steamAccountId, existing);
      }

      gameNumber++;
    }

    return playerStatsMap;
  }
}
