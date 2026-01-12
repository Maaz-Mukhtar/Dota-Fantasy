import '../../domain/entities/player.dart';

/// Player team model for JSON parsing
class PlayerTeamModel extends PlayerTeam {
  const PlayerTeamModel({
    required super.id,
    required super.name,
    super.tag,
    super.logoUrl,
    super.region,
  });

  factory PlayerTeamModel.fromJson(Map<String, dynamic> json) {
    return PlayerTeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tag: json['tag'] as String?,
      logoUrl: json['logo_url'] as String?,
      region: json['region'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tag': tag,
      'logo_url': logoUrl,
      'region': region,
    };
  }
}

/// Player model for JSON parsing
class PlayerModel extends Player {
  const PlayerModel({
    required super.id,
    required super.nickname,
    super.realName,
    super.role,
    super.team,
    super.country,
    super.avatarUrl,
    super.stratzId,
    super.steamId,
    super.avgKills,
    super.avgDeaths,
    super.avgAssists,
    super.avgGpm,
    super.avgXpm,
    super.avgLastHits,
    super.avgFantasyPoints,
    super.totalMatches,
    super.winRate,
    super.fantasyValue,
    super.tournamentStats,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      realName: json['real_name'] as String?,
      role: PlayerRole.fromString(json['role'] as String?),
      team: json['team'] != null
          ? PlayerTeamModel.fromJson(json['team'] as Map<String, dynamic>)
          : null,
      country: json['country'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      stratzId: json['stratz_id'] != null
          ? (json['stratz_id'] is int
              ? json['stratz_id'] as int
              : int.tryParse(json['stratz_id'].toString()))
          : null,
      steamId: json['steam_id'] != null
          ? (json['steam_id'] is int
              ? json['steam_id'] as int
              : int.tryParse(json['steam_id'].toString()))
          : null,
      avgKills: _parseDouble(json['avg_kills']),
      avgDeaths: _parseDouble(json['avg_deaths']),
      avgAssists: _parseDouble(json['avg_assists']),
      avgGpm: _parseDouble(json['avg_gpm']),
      avgXpm: _parseDouble(json['avg_xpm']),
      avgLastHits: _parseDouble(json['avg_last_hits']),
      avgFantasyPoints: _parseDouble(json['avg_fantasy_points']),
      totalMatches: json['total_matches'] as int? ?? 0,
      winRate: _parseDouble(json['win_rate']),
      fantasyValue: json['fantasy_value'] != null
          ? _parseDouble(json['fantasy_value'])
          : null,
      tournamentStats: json['tournament_stats'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'real_name': realName,
      'role': role?.name,
      'team': team != null ? (team as PlayerTeamModel).toJson() : null,
      'country': country,
      'avatar_url': avatarUrl,
      'stratz_id': stratzId,
      'steam_id': steamId,
      'avg_kills': avgKills,
      'avg_deaths': avgDeaths,
      'avg_assists': avgAssists,
      'avg_gpm': avgGpm,
      'avg_xpm': avgXpm,
      'avg_last_hits': avgLastHits,
      'avg_fantasy_points': avgFantasyPoints,
      'total_matches': totalMatches,
      'win_rate': winRate,
      'fantasy_value': fantasyValue,
      'tournament_stats': tournamentStats,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

/// Player game stats model
class PlayerGameStatsModel extends PlayerGameStats {
  const PlayerGameStatsModel({
    required super.id,
    required super.playerId,
    required super.gameId,
    super.matchId,
    super.kills,
    super.deaths,
    super.assists,
    super.lastHits,
    super.denies,
    super.gpm,
    super.xpm,
    super.heroDamage,
    super.towerDamage,
    super.heroHealing,
    super.stuns,
    super.obsPlaced,
    super.campsStacked,
    super.firstBlood,
    super.heroId,
    super.isWinner,
    super.isRadiant,
    super.fantasyPoints,
    super.createdAt,
  });

  factory PlayerGameStatsModel.fromJson(Map<String, dynamic> json) {
    return PlayerGameStatsModel(
      id: json['id'] as String,
      playerId: json['player_id'] as String,
      gameId: json['game_id'] as String,
      matchId: json['match_id'] as String?,
      kills: json['kills'] as int? ?? 0,
      deaths: json['deaths'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      lastHits: json['last_hits'] as int? ?? 0,
      denies: json['denies'] as int? ?? 0,
      gpm: json['gpm'] as int? ?? 0,
      xpm: json['xpm'] as int? ?? 0,
      heroDamage: json['hero_damage'] as int? ?? 0,
      towerDamage: json['tower_damage'] as int? ?? 0,
      heroHealing: json['hero_healing'] as int? ?? 0,
      stuns: _parseDouble(json['stuns']),
      obsPlaced: json['obs_placed'] as int? ?? 0,
      campsStacked: json['camps_stacked'] as int? ?? 0,
      firstBlood: json['first_blood'] as bool? ?? false,
      heroId: json['hero_id'] as int?,
      isWinner: json['is_winner'] as bool? ?? false,
      isRadiant: json['is_radiant'] as bool?,
      fantasyPoints: _parseDouble(json['fantasy_points']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

/// Player averages model
class PlayerAveragesModel extends PlayerAverages {
  const PlayerAveragesModel({
    super.totalGames,
    super.wins,
    super.losses,
    super.winRate,
    super.avgKills,
    super.avgDeaths,
    super.avgAssists,
    super.avgGpm,
    super.avgXpm,
    super.avgLastHits,
    super.avgFantasyPoints,
    super.totalFantasyPoints,
  });

  factory PlayerAveragesModel.fromJson(Map<String, dynamic> json) {
    return PlayerAveragesModel(
      totalGames: json['total_games'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      winRate: _parseDouble(json['win_rate']),
      avgKills: _parseDouble(json['avg_kills']),
      avgDeaths: _parseDouble(json['avg_deaths']),
      avgAssists: _parseDouble(json['avg_assists']),
      avgGpm: _parseDouble(json['avg_gpm']),
      avgXpm: _parseDouble(json['avg_xpm']),
      avgLastHits: _parseDouble(json['avg_last_hits']),
      avgFantasyPoints: _parseDouble(json['avg_fantasy_points']),
      totalFantasyPoints: _parseDouble(json['total_fantasy_points']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

/// Response model for paginated player list
class PlayersResponse {
  final List<PlayerModel> players;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PlayersResponse({
    required this.players,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PlayersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    return PlayersResponse(
      players: data.map((e) => PlayerModel.fromJson(e as Map<String, dynamic>)).toList(),
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      total: meta['total'] as int? ?? 0,
      totalPages: meta['totalPages'] as int? ?? 0,
    );
  }
}

/// Response model for player stats
class PlayerStatsResponse {
  final List<PlayerGameStatsModel> recentGames;
  final PlayerAveragesModel? averages;

  const PlayerStatsResponse({
    required this.recentGames,
    this.averages,
  });

  factory PlayerStatsResponse.fromJson(Map<String, dynamic> json) {
    final recentGamesData = json['recent_games'] as List? ?? [];
    final averagesData = json['averages'] as Map<String, dynamic>?;

    return PlayerStatsResponse(
      recentGames: recentGamesData
          .map((e) => PlayerGameStatsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      averages: averagesData != null
          ? PlayerAveragesModel.fromJson(averagesData)
          : null,
    );
  }
}

/// Response model for fantasy average
class FantasyAverageResponse {
  final double average;
  final int totalGames;
  final double totalPoints;

  const FantasyAverageResponse({
    required this.average,
    required this.totalGames,
    required this.totalPoints,
  });

  factory FantasyAverageResponse.fromJson(Map<String, dynamic> json) {
    return FantasyAverageResponse(
      average: _parseDouble(json['average']),
      totalGames: json['total_games'] as int? ?? 0,
      totalPoints: _parseDouble(json['total_points']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
