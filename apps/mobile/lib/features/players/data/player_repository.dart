import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/entities/player.dart';
import 'models/player_model.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository(ref.read(dioClientProvider));
});

class PlayerRepository {
  final DioClient _client;

  PlayerRepository(this._client);

  /// Get all players with optional filters
  Future<PlayersResponse> getPlayers({
    String? teamId,
    String? role,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (teamId != null) queryParams['team_id'] = teamId;
      if (role != null) queryParams['role'] = role;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _client.get(
        '/players',
        queryParameters: queryParams,
      );

      return PlayersResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Get players for a specific tournament
  Future<PlayersResponse> getTournamentPlayers(
    String tournamentId, {
    String? teamId,
    String? role,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (teamId != null) queryParams['team_id'] = teamId;
      if (role != null) queryParams['role'] = role;

      final response = await _client.get(
        '/players/tournament/$tournamentId',
        queryParameters: queryParams,
      );

      return PlayersResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Get players for a specific team
  Future<List<Player>> getTeamPlayers(String teamId) async {
    try {
      final response = await _client.get('/players/team/$teamId');

      final data = response.data['data'] as List? ?? [];
      return data
          .map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single player by ID
  Future<Player> getPlayer(String id) async {
    try {
      final response = await _client.get('/players/$id');

      return PlayerModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Get player statistics
  Future<PlayerStatsResponse> getPlayerStats(String id, {int limit = 10}) async {
    try {
      final response = await _client.get(
        '/players/$id/stats',
        queryParameters: {'limit': limit},
      );

      return PlayerStatsResponse.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Get player fantasy average
  Future<FantasyAverageResponse> getPlayerFantasyAverage(
    String id, {
    String? tournamentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (tournamentId != null) queryParams['tournament_id'] = tournamentId;

      final response = await _client.get(
        '/players/$id/fantasy-avg',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return FantasyAverageResponse.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
