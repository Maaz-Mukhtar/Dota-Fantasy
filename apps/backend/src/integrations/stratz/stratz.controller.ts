import { Controller, Get, Param, Query } from '@nestjs/common';
import { Public } from '../../modules/auth/decorators/public.decorator';
import { StratzService } from './stratz.service';

@Controller('stratz')
export class StratzController {
  constructor(private readonly stratzService: StratzService) {}

  /**
   * Get detailed stats for a single match
   * Example: GET /api/stratz/match/7654321
   */
  @Public()
  @Get('match/:matchId')
  async getMatchStats(@Param('matchId') matchId: string) {
    const matchIdNum = parseInt(matchId, 10);
    if (isNaN(matchIdNum)) {
      throw new Error('Invalid match ID');
    }

    const match = await this.stratzService.getMatchStats(matchIdNum);
    if (!match) {
      throw new Error('Match not found');
    }

    return {
      success: true,
      data: match,
    };
  }

  /**
   * Get all matches for a league
   * Example: GET /api/stratz/league/18324/matches
   */
  @Public()
  @Get('league/:leagueId/matches')
  async getLeagueMatches(
    @Param('leagueId') leagueId: string,
    @Query('take') take?: string,
    @Query('skip') skip?: string,
  ) {
    const leagueIdNum = parseInt(leagueId, 10);
    if (isNaN(leagueIdNum)) {
      throw new Error('Invalid league ID');
    }

    const takeNum = take ? parseInt(take, 10) : 100;
    const skipNum = skip ? parseInt(skip, 10) : 0;

    const matches = await this.stratzService.getLeagueMatches(
      leagueIdNum,
      takeNum,
      skipNum,
    );

    return {
      success: true,
      data: matches,
      meta: {
        leagueId: leagueIdNum,
        count: matches.length,
        take: takeNum,
        skip: skipNum,
      },
    };
  }

  /**
   * Get league info with standings and brackets
   * Example: GET /api/stratz/league/18324
   */
  @Public()
  @Get('league/:leagueId')
  async getLeagueInfo(@Param('leagueId') leagueId: string) {
    const leagueIdNum = parseInt(leagueId, 10);
    if (isNaN(leagueIdNum)) {
      throw new Error('Invalid league ID');
    }

    const league = await this.stratzService.getLeagueInfo(leagueIdNum);
    if (!league) {
      throw new Error('League not found');
    }

    return {
      success: true,
      data: league,
    };
  }

  /**
   * Get all pro players (cached)
   * Example: GET /api/stratz/pro-players
   */
  @Public()
  @Get('pro-players')
  async getProPlayers(@Query('refresh') refresh?: string) {
    const forceRefresh = refresh === 'true';
    const players = await this.stratzService.getProPlayers(forceRefresh);

    return {
      success: true,
      data: players,
      meta: {
        count: players.length,
        cached: !forceRefresh,
      },
    };
  }

  /**
   * Find pro player by nickname
   * Example: GET /api/stratz/pro-player/Yatoro
   */
  @Public()
  @Get('pro-player/:nickname')
  async findProPlayer(@Param('nickname') nickname: string) {
    const player = await this.stratzService.findProPlayerByNickname(nickname);

    if (!player) {
      return {
        success: false,
        error: `Player "${nickname}" not found`,
      };
    }

    return {
      success: true,
      data: player,
    };
  }

  /**
   * Get player info by Steam ID
   * Example: GET /api/stratz/player/76561198012345678
   */
  @Public()
  @Get('player/:steamId')
  async getPlayer(@Param('steamId') steamId: string) {
    const steamIdNum = parseInt(steamId, 10);
    if (isNaN(steamIdNum)) {
      throw new Error('Invalid Steam ID');
    }

    const player = await this.stratzService.getPlayerBySteamId(steamIdNum);
    if (!player) {
      throw new Error('Player not found');
    }

    return {
      success: true,
      data: player,
    };
  }

  /**
   * Get player's recent matches
   * Example: GET /api/stratz/player/76561198012345678/matches?leagueId=18324
   */
  @Public()
  @Get('player/:steamId/matches')
  async getPlayerMatches(
    @Param('steamId') steamId: string,
    @Query('take') take?: string,
    @Query('leagueId') leagueId?: string,
  ) {
    const steamIdNum = parseInt(steamId, 10);
    if (isNaN(steamIdNum)) {
      throw new Error('Invalid Steam ID');
    }

    const takeNum = take ? parseInt(take, 10) : 50;
    const leagueIdNum = leagueId ? parseInt(leagueId, 10) : undefined;

    const matches = await this.stratzService.getPlayerMatches(
      steamIdNum,
      takeNum,
      leagueIdNum,
    );

    return {
      success: true,
      data: matches,
      meta: {
        steamId: steamIdNum,
        count: matches.length,
      },
    };
  }

  /**
   * Get all live matches
   * Example: GET /api/stratz/live
   */
  @Public()
  @Get('live')
  async getLiveMatches() {
    const matches = await this.stratzService.getLiveMatches();

    return {
      success: true,
      data: matches,
      meta: {
        count: matches.length,
      },
    };
  }

  /**
   * Get live matches for a specific league
   * Example: GET /api/stratz/live/18324
   */
  @Public()
  @Get('live/:leagueId')
  async getLeagueLiveMatches(@Param('leagueId') leagueId: string) {
    const leagueIdNum = parseInt(leagueId, 10);
    if (isNaN(leagueIdNum)) {
      throw new Error('Invalid league ID');
    }

    const matches = await this.stratzService.getLeagueLiveMatches(leagueIdNum);

    return {
      success: true,
      data: matches,
      meta: {
        leagueId: leagueIdNum,
        count: matches.length,
      },
    };
  }

  /**
   * Get team info
   * Example: GET /api/stratz/team/8605863
   */
  @Public()
  @Get('team/:teamId')
  async getTeamInfo(@Param('teamId') teamId: string) {
    const teamIdNum = parseInt(teamId, 10);
    if (isNaN(teamIdNum)) {
      throw new Error('Invalid team ID');
    }

    const team = await this.stratzService.getTeamInfo(teamIdNum);
    if (!team) {
      throw new Error('Team not found');
    }

    return {
      success: true,
      data: team,
    };
  }

  /**
   * Get series matches (all games in a Bo3/Bo5)
   * Example: GET /api/stratz/series/123456
   */
  @Public()
  @Get('series/:seriesId')
  async getSeriesMatches(@Param('seriesId') seriesId: string) {
    const seriesIdNum = parseInt(seriesId, 10);
    if (isNaN(seriesIdNum)) {
      throw new Error('Invalid series ID');
    }

    const matches = await this.stratzService.getSeriesMatches(seriesIdNum);

    return {
      success: true,
      data: matches,
      meta: {
        seriesId: seriesIdNum,
        gameCount: matches.length,
      },
    };
  }

  /**
   * Map player nicknames to Steam IDs
   * Example: GET /api/stratz/map-players?nicknames=Yatoro,Collapse,Miposhka
   */
  @Public()
  @Get('map-players')
  async mapPlayerNicknames(@Query('nicknames') nicknames: string) {
    if (!nicknames) {
      throw new Error('nicknames query parameter required');
    }

    const nicknameList = nicknames.split(',').map((n) => n.trim());
    const mapping = await this.stratzService.mapNicknamesToSteamIds(nicknameList);

    const result: Record<string, number | null> = {};
    for (const nickname of nicknameList) {
      result[nickname] = mapping.get(nickname) || null;
    }

    return {
      success: true,
      data: result,
      meta: {
        found: mapping.size,
        total: nicknameList.length,
      },
    };
  }

  /**
   * Get tournament player stats summary
   * Example: GET /api/stratz/league/18324/player-stats
   * Note: This is an expensive operation - fetches all matches
   */
  @Public()
  @Get('league/:leagueId/player-stats')
  async getTournamentPlayerStats(@Param('leagueId') leagueId: string) {
    const leagueIdNum = parseInt(leagueId, 10);
    if (isNaN(leagueIdNum)) {
      throw new Error('Invalid league ID');
    }

    const playerStatsMap =
      await this.stratzService.getTournamentPlayerStats(leagueIdNum);

    // Convert map to array for JSON response - raw stats for custom scoring
    const playerStats: Array<{
      steamAccountId: number;
      gamesPlayed: number;
      wins: number;
      stats: {
        totalKills: number;
        totalDeaths: number;
        totalAssists: number;
        totalLastHits: number;
        totalDenies: number;
        totalHeroDamage: number;
        totalTowerDamage: number;
        totalHeroHealing: number;
        totalStuns: number;
        totalObsPlaced: number;
        totalCampsStacked: number;
        avgGpm: number;
        avgXpm: number;
      };
    }> = [];

    for (const [steamAccountId, stats] of playerStatsMap) {
      const totalKills = stats.reduce((a, s) => a + s.kills, 0);
      const totalDeaths = stats.reduce((a, s) => a + s.deaths, 0);
      const totalAssists = stats.reduce((a, s) => a + s.assists, 0);
      const totalLastHits = stats.reduce((a, s) => a + s.lastHits, 0);
      const totalDenies = stats.reduce((a, s) => a + s.denies, 0);
      const totalHeroDamage = stats.reduce((a, s) => a + s.heroDamage, 0);
      const totalTowerDamage = stats.reduce((a, s) => a + s.towerDamage, 0);
      const totalHeroHealing = stats.reduce((a, s) => a + s.heroHealing, 0);
      const totalStuns = stats.reduce((a, s) => a + s.stuns, 0);
      const totalObsPlaced = stats.reduce((a, s) => a + s.obsPlaced, 0);
      const totalCampsStacked = stats.reduce((a, s) => a + s.campsStacked, 0);
      const avgGpm = stats.reduce((a, s) => a + s.gpm, 0) / stats.length;
      const avgXpm = stats.reduce((a, s) => a + s.xpm, 0) / stats.length;
      const wins = stats.filter((s) => s.isWinner).length;

      playerStats.push({
        steamAccountId,
        gamesPlayed: stats.length,
        wins,
        stats: {
          totalKills,
          totalDeaths,
          totalAssists,
          totalLastHits,
          totalDenies,
          totalHeroDamage,
          totalTowerDamage,
          totalHeroHealing,
          totalStuns,
          totalObsPlaced,
          totalCampsStacked,
          avgGpm,
          avgXpm,
        },
      });
    }

    // Sort by games played (descending)
    playerStats.sort((a, b) => b.gamesPlayed - a.gamesPlayed);

    return {
      success: true,
      data: playerStats,
      meta: {
        leagueId: leagueIdNum,
        playerCount: playerStats.length,
      },
    };
  }
}
