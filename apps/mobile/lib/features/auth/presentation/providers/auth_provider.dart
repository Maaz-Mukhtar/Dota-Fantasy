import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:gotrue/gotrue.dart' as gotrue show AuthState;

import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';

/// Auth state class
class AppAuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AppAuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AppAuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AppAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  /// Initial loading state
  factory AppAuthState.initial() => const AppAuthState(isLoading: true);

  /// Authenticated state
  factory AppAuthState.authenticated(User user) => AppAuthState(
        user: user,
        isAuthenticated: true,
      );

  /// Unauthenticated state
  factory AppAuthState.unauthenticated() => const AppAuthState();

  /// Error state
  factory AppAuthState.error(String message) => AppAuthState(error: message);

  /// Loading state
  factory AppAuthState.loading() => const AppAuthState(isLoading: true);
}

/// Auth notifier provider
final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

/// Current user provider (derived from auth state)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Is authenticated provider (derived from auth state)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Auth notifier for managing auth state
class AuthNotifier extends StateNotifier<AppAuthState> {
  final AuthRepository _repository;
  StreamSubscription<gotrue.AuthState>? _authSubscription;

  AuthNotifier(this._repository) : super(AppAuthState.initial()) {
    _init();
  }

  /// Initialize auth state
  Future<void> _init() async {
    // Listen to auth state changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (event) async {
        if (event.event == AuthChangeEvent.signedIn ||
            event.event == AuthChangeEvent.tokenRefreshed) {
          await _loadCurrentUser();
        } else if (event.event == AuthChangeEvent.signedOut) {
          state = AppAuthState.unauthenticated();
        }
      },
    );

    // Check initial auth state
    await _loadCurrentUser();
  }

  /// Load current user
  Future<void> _loadCurrentUser() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AppAuthState.authenticated(user.toEntity());
      } else {
        state = AppAuthState.unauthenticated();
      }
    } catch (e) {
      state = AppAuthState.unauthenticated();
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        username: username,
      );
      state = AppAuthState.authenticated(user.toEntity());
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
      );
      state = AppAuthState.authenticated(user.toEntity());
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.signOut();
      state = AppAuthState.unauthenticated();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Update profile
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repository.updateProfile(
        userId: state.user!.id,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
      );
      state = AppAuthState.authenticated(user.toEntity());
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
