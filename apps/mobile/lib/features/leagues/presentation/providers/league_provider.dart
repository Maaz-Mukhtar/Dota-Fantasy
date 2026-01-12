import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/league_repository.dart';
import '../../domain/entities/league.dart';

/// My leagues state
class MyLeaguesState {
  final List<League> leagues;
  final bool isLoading;
  final String? error;
  final bool hasLoaded;

  const MyLeaguesState({
    this.leagues = const [],
    this.isLoading = false,
    this.error,
    this.hasLoaded = false,
  });

  MyLeaguesState copyWith({
    List<League>? leagues,
    bool? isLoading,
    String? error,
    bool? hasLoaded,
  }) {
    return MyLeaguesState(
      leagues: leagues ?? this.leagues,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

/// My leagues notifier
class MyLeaguesNotifier extends StateNotifier<MyLeaguesState> {
  final LeagueRepository _repository;
  final bool _isAuthenticated;

  MyLeaguesNotifier(this._repository, this._isAuthenticated) : super(const MyLeaguesState()) {
    // Only load if authenticated
    if (_isAuthenticated) {
      loadLeagues();
    }
  }

  Future<void> loadLeagues({bool refresh = false}) async {
    if (!_isAuthenticated) {
      if (mounted) state = state.copyWith(isLoading: false, error: null, leagues: []);
      return;
    }

    if (!refresh && state.isLoading) return;

    if (mounted) state = state.copyWith(isLoading: true, error: null);

    try {
      final leagues = await _repository.getMyLeagues();
      if (mounted) state = state.copyWith(leagues: leagues, isLoading: false, hasLoaded: true);
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString(), hasLoaded: true);
    }
  }

  Future<League?> createLeague(CreateLeagueRequest request) async {
    try {
      final league = await _repository.createLeague(request);
      state = state.copyWith(leagues: [league, ...state.leagues]);
      return league;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<League?> joinLeague(JoinLeagueRequest request) async {
    try {
      final league = await _repository.joinLeague(request);
      // Refresh to get updated list
      await loadLeagues(refresh: true);
      return league;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> leaveLeague(String leagueId) async {
    try {
      await _repository.leaveLeague(leagueId);
      state = state.copyWith(
        leagues: state.leagues.where((l) => l.id != leagueId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteLeague(String leagueId) async {
    try {
      await _repository.deleteLeague(leagueId);
      state = state.copyWith(
        leagues: state.leagues.where((l) => l.id != leagueId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// My leagues provider - depends on auth state
final myLeaguesProvider =
    StateNotifierProvider<MyLeaguesNotifier, MyLeaguesState>((ref) {
  final authState = ref.watch(authProvider);
  final isAuthenticated = authState.isAuthenticated;
  return MyLeaguesNotifier(ref.read(leagueRepositoryProvider), isAuthenticated);
});

/// Single league provider
final leagueProvider =
    FutureProvider.family<League, String>((ref, id) async {
  final repository = ref.read(leagueRepositoryProvider);
  return repository.getLeague(id);
});

/// League by invite code provider
final leagueByInviteCodeProvider =
    FutureProvider.family<League, String>((ref, code) async {
  final repository = ref.read(leagueRepositoryProvider);
  return repository.findByInviteCode(code);
});

/// Public leagues provider
final publicLeaguesProvider = FutureProvider<List<League>>((ref) async {
  final repository = ref.read(leagueRepositoryProvider);
  return repository.getPublicLeagues();
});

/// Public leagues for tournament provider
final publicLeaguesForTournamentProvider =
    FutureProvider.family<List<League>, String>((ref, tournamentId) async {
  final repository = ref.read(leagueRepositoryProvider);
  return repository.getPublicLeagues(tournamentId: tournamentId);
});

/// League leaderboard provider
final leagueLeaderboardProvider =
    FutureProvider.family<List<LeagueMember>, String>((ref, leagueId) async {
  final repository = ref.read(leagueRepositoryProvider);
  return repository.getLeaderboard(leagueId);
});
