import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/player_repository.dart';
import '../../data/models/player_model.dart';
import '../../domain/entities/player.dart';

// ============================================================================
// Players List State
// ============================================================================

class PlayersListState {
  final List<Player> players;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int total;
  final String? roleFilter;
  final String? teamFilter;
  final String? searchQuery;

  const PlayersListState({
    this.players = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.roleFilter,
    this.teamFilter,
    this.searchQuery,
  });

  PlayersListState copyWith({
    List<Player>? players,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalPages,
    int? total,
    String? roleFilter,
    String? teamFilter,
    String? searchQuery,
    bool clearError = false,
    bool clearRoleFilter = false,
    bool clearTeamFilter = false,
    bool clearSearchQuery = false,
  }) {
    return PlayersListState(
      players: players ?? this.players,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      teamFilter: clearTeamFilter ? null : (teamFilter ?? this.teamFilter),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasMore => currentPage < totalPages;
}

class PlayersListNotifier extends StateNotifier<PlayersListState> {
  final PlayerRepository _repository;
  bool _mounted = true;

  PlayersListNotifier(this._repository) : super(const PlayersListState()) {
    loadPlayers();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> loadPlayers({bool refresh = false}) async {
    if (!_mounted) return;
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentPage: refresh ? 1 : state.currentPage,
      players: refresh ? [] : state.players,
    );

    try {
      final response = await _repository.getPlayers(
        role: state.roleFilter,
        teamId: state.teamFilter,
        search: state.searchQuery,
        page: 1,
        limit: 20,
      );

      if (!_mounted) return;
      state = state.copyWith(
        players: response.players,
        isLoading: false,
        currentPage: response.page,
        totalPages: response.totalPages,
        total: response.total,
      );
    } catch (e) {
      if (!_mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (!_mounted) return;
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _repository.getPlayers(
        role: state.roleFilter,
        teamId: state.teamFilter,
        search: state.searchQuery,
        page: state.currentPage + 1,
        limit: 20,
      );

      if (!_mounted) return;
      state = state.copyWith(
        players: [...state.players, ...response.players],
        isLoadingMore: false,
        currentPage: response.page,
        totalPages: response.totalPages,
        total: response.total,
      );
    } catch (e) {
      if (!_mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void setRoleFilter(String? role) {
    if (state.roleFilter == role) return;
    state = state.copyWith(
      roleFilter: role,
      clearRoleFilter: role == null,
    );
    loadPlayers(refresh: true);
  }

  void setTeamFilter(String? teamId) {
    if (state.teamFilter == teamId) return;
    state = state.copyWith(
      teamFilter: teamId,
      clearTeamFilter: teamId == null,
    );
    loadPlayers(refresh: true);
  }

  void setSearchQuery(String? query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(
      searchQuery: query,
      clearSearchQuery: query == null,
    );
    loadPlayers(refresh: true);
  }

  void clearFilters() {
    state = state.copyWith(
      clearRoleFilter: true,
      clearTeamFilter: true,
      clearSearchQuery: true,
    );
    loadPlayers(refresh: true);
  }
}

final playersListProvider =
    StateNotifierProvider<PlayersListNotifier, PlayersListState>((ref) {
  return PlayersListNotifier(ref.read(playerRepositoryProvider));
});

// ============================================================================
// Tournament Players State
// ============================================================================

class TournamentPlayersState {
  final List<Player> players;
  final bool isLoading;
  final String? error;
  final String? roleFilter;
  final String? teamFilter;

  const TournamentPlayersState({
    this.players = const [],
    this.isLoading = false,
    this.error,
    this.roleFilter,
    this.teamFilter,
  });

  TournamentPlayersState copyWith({
    List<Player>? players,
    bool? isLoading,
    String? error,
    String? roleFilter,
    String? teamFilter,
    bool clearError = false,
  }) {
    return TournamentPlayersState(
      players: players ?? this.players,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      roleFilter: roleFilter ?? this.roleFilter,
      teamFilter: teamFilter ?? this.teamFilter,
    );
  }

  List<Player> get filteredPlayers {
    var result = players;

    if (roleFilter != null) {
      result = result.where((p) => p.role?.name == roleFilter).toList();
    }

    if (teamFilter != null) {
      result = result.where((p) => p.team?.id == teamFilter).toList();
    }

    return result;
  }
}

class TournamentPlayersNotifier extends StateNotifier<TournamentPlayersState> {
  final PlayerRepository _repository;
  final String tournamentId;
  bool _mounted = true;

  TournamentPlayersNotifier(this._repository, this.tournamentId)
      : super(const TournamentPlayersState()) {
    loadPlayers();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> loadPlayers({bool refresh = false}) async {
    if (!_mounted) return;
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final response = await _repository.getTournamentPlayers(
        tournamentId,
        limit: 100, // Get all players for the tournament
      );

      if (!_mounted) return;
      state = state.copyWith(
        players: response.players,
        isLoading: false,
      );
    } catch (e) {
      if (!_mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setRoleFilter(String? role) {
    state = state.copyWith(roleFilter: role);
  }

  void setTeamFilter(String? teamId) {
    state = state.copyWith(teamFilter: teamId);
  }

  void clearFilters() {
    state = state.copyWith(
      roleFilter: null,
      teamFilter: null,
    );
  }
}

final tournamentPlayersProvider = StateNotifierProvider.family<
    TournamentPlayersNotifier, TournamentPlayersState, String>((ref, tournamentId) {
  return TournamentPlayersNotifier(
    ref.read(playerRepositoryProvider),
    tournamentId,
  );
});

// ============================================================================
// Single Player State
// ============================================================================

class PlayerDetailState {
  final Player? player;
  final PlayerStatsResponse? stats;
  final bool isLoading;
  final bool isLoadingStats;
  final String? error;

  const PlayerDetailState({
    this.player,
    this.stats,
    this.isLoading = false,
    this.isLoadingStats = false,
    this.error,
  });

  PlayerDetailState copyWith({
    Player? player,
    PlayerStatsResponse? stats,
    bool? isLoading,
    bool? isLoadingStats,
    String? error,
    bool clearError = false,
  }) {
    return PlayerDetailState(
      player: player ?? this.player,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PlayerDetailNotifier extends StateNotifier<PlayerDetailState> {
  final PlayerRepository _repository;
  final String playerId;
  bool _mounted = true;

  PlayerDetailNotifier(this._repository, this.playerId)
      : super(const PlayerDetailState()) {
    loadPlayer();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> loadPlayer() async {
    if (!_mounted) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final player = await _repository.getPlayer(playerId);

      if (!_mounted) return;
      state = state.copyWith(
        player: player,
        isLoading: false,
      );

      // Load stats after player loaded
      loadStats();
    } catch (e) {
      if (!_mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadStats() async {
    if (!_mounted) return;

    state = state.copyWith(isLoadingStats: true);

    try {
      final stats = await _repository.getPlayerStats(playerId);

      if (!_mounted) return;
      state = state.copyWith(
        stats: stats,
        isLoadingStats: false,
      );
    } catch (e) {
      if (!_mounted) return;
      state = state.copyWith(
        isLoadingStats: false,
        // Don't set error for stats - player info is still valid
      );
    }
  }

  Future<void> refresh() async {
    await loadPlayer();
  }
}

final playerDetailProvider = StateNotifierProvider.family<
    PlayerDetailNotifier, PlayerDetailState, String>((ref, playerId) {
  return PlayerDetailNotifier(
    ref.read(playerRepositoryProvider),
    playerId,
  );
});

// ============================================================================
// Team Players Provider
// ============================================================================

final teamPlayersProvider =
    FutureProvider.family<List<Player>, String>((ref, teamId) async {
  final repository = ref.read(playerRepositoryProvider);
  return repository.getTeamPlayers(teamId);
});
