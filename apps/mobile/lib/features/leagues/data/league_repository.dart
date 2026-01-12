import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/entities/league.dart';
import 'models/league_model.dart';

/// Provider for the league repository
final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  return LeagueRepository(ref.read(dioClientProvider));
});

/// Create league request
class CreateLeagueRequest {
  final String name;
  final String tournamentId;
  final int? maxMembers;
  final bool? isPublic;
  final DateTime? draftDate;

  CreateLeagueRequest({
    required this.name,
    required this.tournamentId,
    this.maxMembers,
    this.isPublic,
    this.draftDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tournament_id': tournamentId,
      if (maxMembers != null) 'max_members': maxMembers,
      if (isPublic != null) 'is_public': isPublic,
      if (draftDate != null) 'draft_date': draftDate!.toIso8601String(),
    };
  }
}

/// Join league request
class JoinLeagueRequest {
  final String inviteCode;
  final String? teamName;

  JoinLeagueRequest({
    required this.inviteCode,
    this.teamName,
  });

  Map<String, dynamic> toJson() {
    return {
      'invite_code': inviteCode,
      if (teamName != null) 'team_name': teamName,
    };
  }
}

/// Repository for league operations
class LeagueRepository {
  final DioClient _client;

  LeagueRepository(this._client);

  /// Get user's leagues
  Future<List<League>> getMyLeagues({String? tournamentId}) async {
    final queryParams = <String, String>{};
    if (tournamentId != null) queryParams['tournament_id'] = tournamentId;

    final response = await _client.get(
      '/leagues',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = response.data as Map<String, dynamic>;
    final leaguesJson = data['data'] as List;

    return leaguesJson
        .map((json) => LeagueModel.fromJson(json as Map<String, dynamic>).toEntity())
        .toList();
  }

  /// Get public leagues
  Future<List<League>> getPublicLeagues({String? tournamentId}) async {
    final queryParams = <String, String>{};
    if (tournamentId != null) queryParams['tournament_id'] = tournamentId;

    final response = await _client.get(
      '/leagues/public',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = response.data as Map<String, dynamic>;
    final leaguesJson = data['data'] as List;

    return leaguesJson
        .map((json) => LeagueModel.fromJson(json as Map<String, dynamic>).toEntity())
        .toList();
  }

  /// Get single league by ID
  Future<League> getLeague(String id) async {
    final response = await _client.get('/leagues/$id');
    final data = response.data as Map<String, dynamic>;
    final leagueData = data['data'] as Map<String, dynamic>;
    return LeagueModel.fromJson(leagueData).toEntity();
  }

  /// Find league by invite code
  Future<League> findByInviteCode(String code) async {
    final response = await _client.get('/leagues/invite/${code.toUpperCase()}');
    final data = response.data as Map<String, dynamic>;
    final leagueData = data['data'] as Map<String, dynamic>;
    return LeagueModel.fromJson(leagueData).toEntity();
  }

  /// Create a new league
  Future<League> createLeague(CreateLeagueRequest request) async {
    final response = await _client.post('/leagues', data: request.toJson());
    final data = response.data as Map<String, dynamic>;
    final leagueData = data['data'] as Map<String, dynamic>;
    return LeagueModel.fromJson(leagueData).toEntity();
  }

  /// Join a league
  Future<League> joinLeague(JoinLeagueRequest request) async {
    final response = await _client.post('/leagues/join', data: request.toJson());
    final data = response.data as Map<String, dynamic>;
    // The response includes both the membership and the league
    final leagueData = data['league'] as Map<String, dynamic>? ?? data['data'] as Map<String, dynamic>;
    return LeagueModel.fromJson(leagueData).toEntity();
  }

  /// Leave a league
  Future<void> leaveLeague(String id) async {
    await _client.delete('/leagues/$id/leave');
  }

  /// Delete a league (owner only)
  Future<void> deleteLeague(String id) async {
    await _client.delete('/leagues/$id');
  }

  /// Get league leaderboard
  Future<List<LeagueMember>> getLeaderboard(String leagueId) async {
    final response = await _client.get('/leagues/$leagueId/leaderboard');
    final data = response.data as Map<String, dynamic>;
    final membersJson = data['data'] as List;

    return membersJson.map((json) {
      final memberModel = LeagueMemberModel.fromJson({
        ...json as Map<String, dynamic>,
        'league_id': leagueId,
      });
      return memberModel.toEntity();
    }).toList();
  }
}
