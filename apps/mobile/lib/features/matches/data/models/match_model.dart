import '../../domain/entities/match.dart';
import '../../../teams/data/models/team_model.dart';

/// Match model for JSON serialization
class MatchModel {
  final String id;
  final String tournamentId;
  final TeamModel? team1;
  final TeamModel? team2;
  final int team1Score;
  final int team2Score;
  final TeamModel? winner;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? stage;
  final String? round;
  final int? matchNumber;
  final int bestOf;
  final String status;
  final String? streamUrl;
  final DateTime createdAt;

  MatchModel({
    required this.id,
    required this.tournamentId,
    this.team1,
    this.team2,
    this.team1Score = 0,
    this.team2Score = 0,
    this.winner,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.stage,
    this.round,
    this.matchNumber,
    this.bestOf = 3,
    this.status = 'scheduled',
    this.streamUrl,
    required this.createdAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      team1: json['team1'] != null
          ? TeamModel.fromJson(json['team1'] as Map<String, dynamic>)
          : null,
      team2: json['team2'] != null
          ? TeamModel.fromJson(json['team2'] as Map<String, dynamic>)
          : null,
      team1Score: json['team1_score'] as int? ?? 0,
      team2Score: json['team2_score'] as int? ?? 0,
      winner: json['winner'] != null
          ? TeamModel.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      stage: json['stage'] as String?,
      round: json['round'] as String?,
      matchNumber: json['match_number'] as int?,
      bestOf: json['best_of'] as int? ?? 3,
      status: json['status'] as String? ?? 'scheduled',
      streamUrl: json['stream_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'team1': team1?.toJson(),
      'team2': team2?.toJson(),
      'team1_score': team1Score,
      'team2_score': team2Score,
      'winner': winner?.toJson(),
      'scheduled_at': scheduledAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'stage': stage,
      'round': round,
      'match_number': matchNumber,
      'best_of': bestOf,
      'status': status,
      'stream_url': streamUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Match toEntity() {
    return Match(
      id: id,
      tournamentId: tournamentId,
      team1: team1?.toEntity(),
      team2: team2?.toEntity(),
      team1Score: team1Score,
      team2Score: team2Score,
      winner: winner?.toEntity(),
      scheduledAt: scheduledAt,
      startedAt: startedAt,
      endedAt: endedAt,
      stage: stage,
      round: round,
      matchNumber: matchNumber,
      bestOf: bestOf,
      status: MatchStatus.fromString(status),
      streamUrl: streamUrl,
      createdAt: createdAt,
    );
  }
}
