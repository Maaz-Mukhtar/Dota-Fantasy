import '../../domain/entities/league.dart';
import '../../../tournaments/data/models/tournament_model.dart';

/// League member model for JSON serialization
class LeagueMemberModel {
  final String id;
  final String leagueId;
  final String userId;
  final String? userName;
  final String role;
  final String teamName;
  final double totalPoints;
  final int? rank;
  final DateTime joinedAt;

  LeagueMemberModel({
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

  factory LeagueMemberModel.fromJson(Map<String, dynamic> json) {
    // Handle user name from profile join
    String? userName;
    if (json['profile'] != null && json['profile'] is Map) {
      userName = (json['profile'] as Map<String, dynamic>)['name'] as String?;
    } else if (json['user_name'] != null) {
      userName = json['user_name'] as String?;
    }

    return LeagueMemberModel(
      id: json['id'] as String? ?? '',
      leagueId: json['league_id'] as String? ?? '',
      userId: json['user_id'] as String,
      userName: userName,
      role: json['role'] as String? ?? 'member',
      teamName: json['team_name'] as String? ?? 'My Team',
      totalPoints: (json['total_points'] as num?)?.toDouble() ?? 0,
      rank: json['rank'] as int?,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'user_id': userId,
      'user_name': userName,
      'role': role,
      'team_name': teamName,
      'total_points': totalPoints,
      'rank': rank,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  LeagueMember toEntity() {
    return LeagueMember(
      id: id,
      leagueId: leagueId,
      userId: userId,
      userName: userName,
      role: MemberRole.fromString(role),
      teamName: teamName,
      totalPoints: totalPoints,
      rank: rank,
      joinedAt: joinedAt,
    );
  }
}

/// League model for JSON serialization
class LeagueModel {
  final String id;
  final String name;
  final String tournamentId;
  final String ownerId;
  final String inviteCode;
  final int maxMembers;
  final bool isPublic;
  final String draftStatus;
  final DateTime? draftDate;
  final Map<String, dynamic>? scoringSystem;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TournamentModel? tournament;
  final int memberCount;
  final LeagueMemberModel? myMembership;

  LeagueModel({
    required this.id,
    required this.name,
    required this.tournamentId,
    required this.ownerId,
    required this.inviteCode,
    this.maxMembers = 10,
    this.isPublic = false,
    this.draftStatus = 'pending',
    this.draftDate,
    this.scoringSystem,
    required this.createdAt,
    required this.updatedAt,
    this.tournament,
    this.memberCount = 0,
    this.myMembership,
  });

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    // Handle member count from different formats
    int memberCount = 0;
    if (json['members'] != null) {
      if (json['members'] is List) {
        final members = json['members'] as List;
        if (members.isNotEmpty && members[0] is Map && members[0]['count'] != null) {
          memberCount = members[0]['count'] as int;
        } else {
          memberCount = members.length;
        }
      } else if (json['members'] is int) {
        memberCount = json['members'] as int;
      }
    }

    // Handle my_membership
    LeagueMemberModel? myMembership;
    if (json['my_membership'] != null) {
      if (json['my_membership'] is List && (json['my_membership'] as List).isNotEmpty) {
        myMembership = LeagueMemberModel.fromJson({
          'id': '',
          'league_id': json['id'],
          ...json['my_membership'][0] as Map<String, dynamic>,
        });
      } else if (json['my_membership'] is Map) {
        myMembership = LeagueMemberModel.fromJson({
          'id': '',
          'league_id': json['id'],
          ...json['my_membership'] as Map<String, dynamic>,
        });
      }
    }

    return LeagueModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tournamentId: json['tournament_id'] as String,
      ownerId: json['owner_id'] as String,
      inviteCode: json['invite_code'] as String,
      maxMembers: json['max_members'] as int? ?? 10,
      isPublic: json['is_public'] as bool? ?? false,
      draftStatus: json['draft_status'] as String? ?? 'pending',
      draftDate: json['draft_date'] != null
          ? DateTime.parse(json['draft_date'] as String)
          : null,
      scoringSystem: json['scoring_system'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tournament: json['tournament'] != null
          ? TournamentModel.fromJson(json['tournament'] as Map<String, dynamic>)
          : null,
      memberCount: memberCount,
      myMembership: myMembership,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tournament_id': tournamentId,
      'owner_id': ownerId,
      'invite_code': inviteCode,
      'max_members': maxMembers,
      'is_public': isPublic,
      'draft_status': draftStatus,
      'draft_date': draftDate?.toIso8601String(),
      'scoring_system': scoringSystem,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  League toEntity() {
    return League(
      id: id,
      name: name,
      tournamentId: tournamentId,
      ownerId: ownerId,
      inviteCode: inviteCode,
      maxMembers: maxMembers,
      isPublic: isPublic,
      draftStatus: DraftStatus.fromString(draftStatus),
      draftDate: draftDate,
      scoringSystem: scoringSystem,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tournament: tournament?.toEntity(),
      memberCount: memberCount,
      myMembership: myMembership?.toEntity(),
    );
  }
}
