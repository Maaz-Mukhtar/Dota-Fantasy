import 'package:equatable/equatable.dart';

/// Player roles in Dota 2
enum PlayerRole {
  carry,
  mid,
  offlane,
  support4,
  support5;

  String get displayName {
    switch (this) {
      case PlayerRole.carry:
        return 'Carry';
      case PlayerRole.mid:
        return 'Mid';
      case PlayerRole.offlane:
        return 'Offlane';
      case PlayerRole.support4:
        return 'Support (4)';
      case PlayerRole.support5:
        return 'Support (5)';
    }
  }

  String get shortName {
    switch (this) {
      case PlayerRole.carry:
        return 'Pos 1';
      case PlayerRole.mid:
        return 'Pos 2';
      case PlayerRole.offlane:
        return 'Pos 3';
      case PlayerRole.support4:
        return 'Pos 4';
      case PlayerRole.support5:
        return 'Pos 5';
    }
  }

  static PlayerRole? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'carry':
        return PlayerRole.carry;
      case 'mid':
        return PlayerRole.mid;
      case 'offlane':
        return PlayerRole.offlane;
      case 'support4':
        return PlayerRole.support4;
      case 'support5':
        return PlayerRole.support5;
      default:
        return null;
    }
  }
}

/// Player team information
class PlayerTeam extends Equatable {
  final String id;
  final String name;
  final String? tag;
  final String? logoUrl;
  final String? region;

  const PlayerTeam({
    required this.id,
    required this.name,
    this.tag,
    this.logoUrl,
    this.region,
  });

  @override
  List<Object?> get props => [id, name, tag, logoUrl, region];
}

/// Player entity
class Player extends Equatable {
  final String id;
  final String nickname;
  final String? realName;
  final PlayerRole? role;
  final PlayerTeam? team;
  final String? country;
  final String? avatarUrl;
  final int? stratzId;
  final int? steamId;

  // Cached stats
  final double avgKills;
  final double avgDeaths;
  final double avgAssists;
  final double avgGpm;
  final double avgXpm;
  final double avgLastHits;
  final double avgFantasyPoints;
  final int totalMatches;
  final double winRate;

  // Tournament-specific (optional)
  final double? fantasyValue;
  final Map<String, dynamic>? tournamentStats;

  const Player({
    required this.id,
    required this.nickname,
    this.realName,
    this.role,
    this.team,
    this.country,
    this.avatarUrl,
    this.stratzId,
    this.steamId,
    this.avgKills = 0,
    this.avgDeaths = 0,
    this.avgAssists = 0,
    this.avgGpm = 0,
    this.avgXpm = 0,
    this.avgLastHits = 0,
    this.avgFantasyPoints = 0,
    this.totalMatches = 0,
    this.winRate = 0,
    this.fantasyValue,
    this.tournamentStats,
  });

  String get kdaString => '${avgKills.toStringAsFixed(1)}/${avgDeaths.toStringAsFixed(1)}/${avgAssists.toStringAsFixed(1)}';

  @override
  List<Object?> get props => [
        id,
        nickname,
        realName,
        role,
        team,
        country,
        avatarUrl,
        stratzId,
        steamId,
        avgKills,
        avgDeaths,
        avgAssists,
        avgGpm,
        avgXpm,
        avgLastHits,
        avgFantasyPoints,
        totalMatches,
        winRate,
        fantasyValue,
        tournamentStats,
      ];
}

/// Player statistics from a single game
class PlayerGameStats extends Equatable {
  final String id;
  final String playerId;
  final String gameId;
  final String? matchId;
  final int kills;
  final int deaths;
  final int assists;
  final int lastHits;
  final int denies;
  final int gpm;
  final int xpm;
  final int heroDamage;
  final int towerDamage;
  final int heroHealing;
  final double stuns;
  final int obsPlaced;
  final int campsStacked;
  final bool firstBlood;
  final int? heroId;
  final bool isWinner;
  final bool? isRadiant;
  final double fantasyPoints;
  final DateTime? createdAt;

  const PlayerGameStats({
    required this.id,
    required this.playerId,
    required this.gameId,
    this.matchId,
    this.kills = 0,
    this.deaths = 0,
    this.assists = 0,
    this.lastHits = 0,
    this.denies = 0,
    this.gpm = 0,
    this.xpm = 0,
    this.heroDamage = 0,
    this.towerDamage = 0,
    this.heroHealing = 0,
    this.stuns = 0,
    this.obsPlaced = 0,
    this.campsStacked = 0,
    this.firstBlood = false,
    this.heroId,
    this.isWinner = false,
    this.isRadiant,
    this.fantasyPoints = 0,
    this.createdAt,
  });

  String get kdaString => '$kills/$deaths/$assists';

  @override
  List<Object?> get props => [
        id,
        playerId,
        gameId,
        matchId,
        kills,
        deaths,
        assists,
        lastHits,
        denies,
        gpm,
        xpm,
        heroDamage,
        towerDamage,
        heroHealing,
        stuns,
        obsPlaced,
        campsStacked,
        firstBlood,
        heroId,
        isWinner,
        isRadiant,
        fantasyPoints,
        createdAt,
      ];
}

/// Player stats averages
class PlayerAverages extends Equatable {
  final int totalGames;
  final int wins;
  final int losses;
  final double winRate;
  final double avgKills;
  final double avgDeaths;
  final double avgAssists;
  final double avgGpm;
  final double avgXpm;
  final double avgLastHits;
  final double avgFantasyPoints;
  final double totalFantasyPoints;

  const PlayerAverages({
    this.totalGames = 0,
    this.wins = 0,
    this.losses = 0,
    this.winRate = 0,
    this.avgKills = 0,
    this.avgDeaths = 0,
    this.avgAssists = 0,
    this.avgGpm = 0,
    this.avgXpm = 0,
    this.avgLastHits = 0,
    this.avgFantasyPoints = 0,
    this.totalFantasyPoints = 0,
  });

  @override
  List<Object?> get props => [
        totalGames,
        wins,
        losses,
        winRate,
        avgKills,
        avgDeaths,
        avgAssists,
        avgGpm,
        avgXpm,
        avgLastHits,
        avgFantasyPoints,
        totalFantasyPoints,
      ];
}
