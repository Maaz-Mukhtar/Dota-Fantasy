import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../teams/domain/entities/team.dart';
import '../../teams/data/models/team_model.dart';
import '../../matches/domain/entities/match.dart';
import '../../matches/data/models/match_model.dart';
import '../domain/entities/tournament.dart';
import 'models/tournament_model.dart';

/// Provider for the tournament repository
final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepository(ref.read(dioClientProvider));
});

/// Pagination metadata
class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

/// Tournament list response
class TournamentListResponse {
  final List<Tournament> tournaments;
  final PaginationMeta meta;

  TournamentListResponse({
    required this.tournaments,
    required this.meta,
  });
}

/// Tournament filter options
class TournamentFilters {
  final String? status;
  final String? tier;
  final String? region;

  const TournamentFilters({
    this.status,
    this.tier,
    this.region,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (status != null) params['status'] = status!;
    if (tier != null) params['tier'] = tier!;
    if (region != null) params['region'] = region!;
    return params;
  }
}

/// Repository for tournament operations
class TournamentRepository {
  final DioClient _client;

  TournamentRepository(this._client);

  /// Get list of tournaments with optional filters
  Future<TournamentListResponse> getTournaments({
    TournamentFilters filters = const TournamentFilters(),
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = {
      ...filters.toQueryParams(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    print('TournamentRepository: Fetching tournaments with params: $queryParams');

    final response = await _client.get(
      '/tournaments',
      queryParameters: queryParams,
    );

    print('TournamentRepository: Response received: ${response.data}');

    final data = response.data as Map<String, dynamic>;
    final tournamentsJson = data['data'] as List;
    final metaJson = data['meta'] as Map<String, dynamic>;

    print('TournamentRepository: Parsing ${tournamentsJson.length} tournaments');

    final tournaments = tournamentsJson
        .map((json) => TournamentModel.fromJson(json).toEntity())
        .toList();

    return TournamentListResponse(
      tournaments: tournaments,
      meta: PaginationMeta.fromJson(metaJson),
    );
  }

  /// Get single tournament by ID
  Future<Tournament> getTournament(String id) async {
    final response = await _client.get('/tournaments/$id');
    final data = response.data as Map<String, dynamic>;
    final tournamentData = data['data'] as Map<String, dynamic>;
    return TournamentModel.fromJson(tournamentData).toEntity();
  }

  /// Get teams participating in a tournament
  Future<List<Team>> getTournamentTeams(String tournamentId) async {
    final response = await _client.get('/tournaments/$tournamentId/teams');
    final data = response.data as Map<String, dynamic>;
    final innerData = data['data'] as Map<String, dynamic>;
    final teamsJson = innerData['data'] as List;

    return teamsJson
        .map((json) => TeamModel.fromJson(json as Map<String, dynamic>).toEntity())
        .toList();
  }

  /// Get matches in a tournament
  Future<List<Match>> getTournamentMatches(
    String tournamentId, {
    String? status,
    String? stage,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (stage != null) queryParams['stage'] = stage;

    final response = await _client.get(
      '/tournaments/$tournamentId/matches',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = response.data as Map<String, dynamic>;
    final innerData = data['data'] as Map<String, dynamic>;
    final matchesJson = innerData['data'] as List;

    return matchesJson
        .map((json) => MatchModel.fromJson(json as Map<String, dynamic>).toEntity())
        .toList();
  }
}
