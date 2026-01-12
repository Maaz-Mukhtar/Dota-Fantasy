import '../../../tournaments/domain/entities/tournament.dart';

/// Draft status enum
enum DraftStatus {
  pending,
  inProgress,
  completed;

  static DraftStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return DraftStatus.inProgress;
      case 'completed':
        return DraftStatus.completed;
      default:
        return DraftStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case DraftStatus.pending:
        return 'Not Started';
      case DraftStatus.inProgress:
        return 'In Progress';
      case DraftStatus.completed:
        return 'Completed';
    }
  }
}

/// League member role enum
enum MemberRole {
  owner,
  admin,
  member;

  static MemberRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return MemberRole.owner;
      case 'admin':
        return MemberRole.admin;
      default:
        return MemberRole.member;
    }
  }
}

/// League member entity
class LeagueMember {
  final String id;
  final String leagueId;
  final String userId;
  final String? userName;
  final MemberRole role;
  final String teamName;
  final double totalPoints;
  final int? rank;
  final DateTime joinedAt;

  const LeagueMember({
    required this.id,
    required this.leagueId,
    required this.userId,
    this.userName,
    required this.role,
    required this.teamName,
    this.totalPoints = 0,
    this.rank,
    required this.joinedAt,
  });

  bool get isOwner => role == MemberRole.owner;
  bool get isAdmin => role == MemberRole.admin || role == MemberRole.owner;
}

/// League entity
class League {
  final String id;
  final String name;
  final String tournamentId;
  final String ownerId;
  final String inviteCode;
  final int maxMembers;
  final bool isPublic;
  final DraftStatus draftStatus;
  final DateTime? draftDate;
  final Map<String, dynamic>? scoringSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final Tournament? tournament;
  final int memberCount;
  final LeagueMember? myMembership;

  const League({
    required this.id,
    required this.name,
    required this.tournamentId,
    required this.ownerId,
    required this.inviteCode,
    this.maxMembers = 10,
    this.isPublic = false,
    this.draftStatus = DraftStatus.pending,
    this.draftDate,
    this.scoringSystem,
    required this.createdAt,
    required this.updatedAt,
    this.tournament,
    this.memberCount = 0,
    this.myMembership,
  });

  /// Check if current user is the owner
  bool get isOwner => myMembership?.isOwner ?? false;

  /// Check if league is full
  bool get isFull => memberCount >= maxMembers;

  /// Check if draft hasn't started yet
  bool get canJoin => draftStatus == DraftStatus.pending && !isFull;

  /// Member count display
  String get memberCountDisplay => '$memberCount/$maxMembers';

  /// Draft status display
  String get draftStatusDisplay => draftStatus.displayName;
}
