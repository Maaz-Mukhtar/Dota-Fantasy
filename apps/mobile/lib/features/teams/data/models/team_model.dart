import '../../domain/entities/team.dart';

/// Team model for JSON serialization
class TeamModel {
  final String id;
  final String name;
  final String? tag;
  final String? logoUrl;
  final String? region;
  final String? liquipediaUrl;
  final DateTime createdAt;
  final int? seed;
  final String? groupName;
  final int? placement;
  final double? prizeWon;
  final int? wins;
  final int? losses;
  final int? draws;
  final int? gameWins;
  final int? gameLosses;

  TeamModel({
    required this.id,
    required this.name,
    this.tag,
    this.logoUrl,
    this.region,
    this.liquipediaUrl,
    required this.createdAt,
    this.seed,
    this.groupName,
    this.placement,
    this.prizeWon,
    this.wins,
    this.losses,
    this.draws,
    this.gameWins,
    this.gameLosses,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tag: json['tag'] as String?,
      logoUrl: json['logo_url'] as String?,
      region: json['region'] as String?,
      liquipediaUrl: json['liquipedia_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      seed: json['seed'] as int?,
      groupName: json['groupName'] as String?,
      placement: json['placement'] as int?,
      prizeWon: json['prizeWon'] != null
          ? (json['prizeWon'] as num).toDouble()
          : null,
      wins: json['wins'] as int?,
      losses: json['losses'] as int?,
      draws: json['draws'] as int?,
      gameWins: json['gameWins'] as int?,
      gameLosses: json['gameLosses'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tag': tag,
      'logo_url': logoUrl,
      'region': region,
      'liquipedia_url': liquipediaUrl,
      'created_at': createdAt.toIso8601String(),
      'seed': seed,
      'groupName': groupName,
      'placement': placement,
      'prizeWon': prizeWon,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'gameWins': gameWins,
      'gameLosses': gameLosses,
    };
  }

  Team toEntity() {
    return Team(
      id: id,
      name: name,
      tag: tag,
      logoUrl: logoUrl,
      region: region,
      liquipediaUrl: liquipediaUrl,
      createdAt: createdAt,
      seed: seed,
      groupName: groupName,
      placement: placement,
      prizeWon: prizeWon,
      wins: wins,
      losses: losses,
      draws: draws,
      gameWins: gameWins,
      gameLosses: gameLosses,
    );
  }
}
