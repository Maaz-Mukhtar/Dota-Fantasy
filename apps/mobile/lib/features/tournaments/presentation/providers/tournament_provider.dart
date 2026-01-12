import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tournament_repository.dart';
import '../../domain/entities/tournament.dart';

/// Tournament list state
class TournamentListState {
  final List<Tournament> tournaments;
  final bool isLoading;
  final String? error;
  final PaginationMeta? meta;
  final TournamentFilters filters;

  const TournamentListState({
    this.tournaments = const [],
    this.isLoading = false,
    this.error,
    this.meta,
    this.filters = const TournamentFilters(),
  });

  TournamentListState copyWith({
    List<Tournament>? tournaments,
    bool? isLoading,
    String? error,
    PaginationMeta? meta,
    TournamentFilters? filters,
  }) {
    return TournamentListState(
      tournaments: tournaments ?? this.tournaments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      meta: meta ?? this.meta,
      filters: filters ?? this.filters,
    );
  }

  factory TournamentListState.initial() => const TournamentListState(isLoading: true);
}

/// Tournament list notifier
class TournamentListNotifier extends StateNotifier<TournamentListState> {
  final TournamentRepository _repository;

  TournamentListNotifier(this._repository) : super(const TournamentListState()) {
    _init();
  }

  Future<void> _init() async {
    await loadTournaments(refresh: true);
  }

  /// Load tournaments with current filters
  Future<void> loadTournaments({bool refresh = false}) async {
    if (!refresh && state.isLoading) return;

    print('TournamentListNotifier: Loading tournaments...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getTournaments(
        filters: state.filters,
        page: 1,
      );

      print('TournamentListNotifier: Loaded ${response.tournaments.length} tournaments');
      state = state.copyWith(
        tournaments: response.tournaments,
        meta: response.meta,
        isLoading: false,
      );
    } catch (e, stack) {
      print('TournamentListNotifier: Error loading tournaments: $e');
      print('Stack trace: $stack');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more tournaments (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || state.meta == null) return;
    if (state.meta!.page >= state.meta!.totalPages) return;

    state = state.copyWith(isLoading: true);

    try {
      final response = await _repository.getTournaments(
        filters: state.filters,
        page: state.meta!.page + 1,
      );

      state = state.copyWith(
        tournaments: [...state.tournaments, ...response.tournaments],
        meta: response.meta,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update filters and reload
  Future<void> setFilters(TournamentFilters filters) async {
    state = state.copyWith(filters: filters, tournaments: []);
    await loadTournaments();
  }

  /// Filter by status
  Future<void> filterByStatus(String? status) async {
    await setFilters(TournamentFilters(
      status: status,
      tier: state.filters.tier,
      region: state.filters.region,
    ));
  }
}

/// Tournament list provider
final tournamentListProvider =
    StateNotifierProvider<TournamentListNotifier, TournamentListState>((ref) {
  return TournamentListNotifier(ref.read(tournamentRepositoryProvider));
});

/// Single tournament provider
final tournamentProvider =
    FutureProvider.family<Tournament, String>((ref, id) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.getTournament(id);
});

/// Filtered tournaments by status
final upcomingTournamentsProvider = Provider<List<Tournament>>((ref) {
  final state = ref.watch(tournamentListProvider);
  return state.tournaments.where((t) => t.isUpcoming).toList();
});

final ongoingTournamentsProvider = Provider<List<Tournament>>((ref) {
  final state = ref.watch(tournamentListProvider);
  return state.tournaments.where((t) => t.isLive).toList();
});

final completedTournamentsProvider = Provider<List<Tournament>>((ref) {
  final state = ref.watch(tournamentListProvider);
  return state.tournaments.where((t) => t.isCompleted).toList();
});
