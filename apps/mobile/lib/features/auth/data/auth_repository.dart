import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/exceptions.dart';
import 'models/user_model.dart';

/// Provider for the auth repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Repository for authentication operations
class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user == null) {
        throw const AppAuthException(
          message: 'Failed to create account',
          code: 'SIGNUP_FAILED',
        );
      }

      // Get the user profile
      final profile = await _getProfile(response.user!.id);

      return UserModel.fromSupabaseUser(
        response.user!.toJson(),
        profile,
      );
    } on AuthApiException catch (e) {
      throw AppAuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
      );
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AppAuthException(
          message: 'Invalid credentials',
          code: 'INVALID_CREDENTIALS',
        );
      }

      // Get the user profile
      final profile = await _getProfile(response.user!.id);

      return UserModel.fromSupabaseUser(
        response.user!.toJson(),
        profile,
      );
    } on AuthApiException catch (e) {
      throw AppAuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthApiException catch (e) {
      throw AppAuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
      );
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final profile = await _getProfile(user.id);
      return UserModel.fromSupabaseUser(user.toJson(), profile);
    } catch (e) {
      return null;
    }
  }

  /// Get user profile from database
  Future<Map<String, dynamic>?> _getProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      // Profile might not exist yet
      return null;
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;

      await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', userId);

      final user = _client.auth.currentUser!;
      final profile = await _getProfile(userId);

      return UserModel.fromSupabaseUser(user.toJson(), profile);
    } catch (e) {
      throw ServerException(
        message: 'Failed to update profile',
        originalError: e,
      );
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthApiException catch (e) {
      throw AppAuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
      );
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthApiException catch (e) {
      throw AppAuthException(
        message: e.message,
        code: e.statusCode,
        originalError: e,
      );
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
