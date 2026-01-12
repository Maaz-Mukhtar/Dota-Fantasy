import '../.././../teams/domain/entities/team.dart';

/// Match status enum
enum MatchStatus {
  scheduled,
  live,
  completed,
  postponed,
  cancelled;

  static MatchStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return MatchStatus.live;
      case 'completed':
        return MatchStatus.completed;
      case 'postponed':
        return MatchStatus.postponed;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.scheduled;
    }
  }
}

/// Match entity
class Match {
  final String id;
  final String tournamentId;
  final Team? team1;
  final Team? team2;
  final int team1Score;
  final int team2Score;
  final Team? winner;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? stage;
  final String? round;
  final int? matchNumber;
  final int bestOf;
  final MatchStatus status;
  final String? streamUrl;
  final DateTime createdAt;

  const Match({
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
    this.status = MatchStatus.scheduled,
    this.streamUrl,
    required this.createdAt,
  });

  /// Check if match is live
  bool get isLive => status == MatchStatus.live;

  /// Check if match is completed
  bool get isCompleted => status == MatchStatus.completed;

  /// Check if match is upcoming
  bool get isUpcoming => status == MatchStatus.scheduled;

  /// Score display string
  String get scoreDisplay => '$team1Score - $team2Score';

  /// Best of display (BO3, BO5, etc.)
  String get bestOfDisplay => 'BO$bestOf';

  /// Match title (Team1 vs Team2)
  String get title {
    final t1 = team1?.shortName ?? 'TBD';
    final t2 = team2?.shortName ?? 'TBD';
    return '$t1 vs $t2';
  }

  /// Full match title with team names
  String get fullTitle {
    final t1 = team1?.name ?? 'TBD';
    final t2 = team2?.name ?? 'TBD';
    return '$t1 vs $t2';
  }
}
