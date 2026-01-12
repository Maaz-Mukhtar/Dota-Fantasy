import '../../domain/entities/user.dart';

/// User model for JSON serialization
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.username,
    super.displayName,
    super.avatarUrl,
    super.subscriptionTier,
    super.subscriptionExpires,
    super.totalFantasyPoints,
    super.tournamentsPlayed,
    required super.createdAt,
  });

  /// Create a UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      subscriptionExpires: json['subscription_expires'] != null
          ? DateTime.parse(json['subscription_expires'] as String)
          : null,
      totalFantasyPoints:
          (json['total_fantasy_points'] as num?)?.toDouble() ?? 0,
      tournamentsPlayed: json['tournaments_played'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Create a UserModel from Supabase auth user
  factory UserModel.fromSupabaseUser(
    Map<String, dynamic> authUser,
    Map<String, dynamic>? profile,
  ) {
    return UserModel(
      id: authUser['id'] as String,
      email: authUser['email'] as String,
      username: profile?['username'] as String? ??
          authUser['user_metadata']?['username'] as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      subscriptionTier: profile?['subscription_tier'] as String? ?? 'free',
      subscriptionExpires: profile?['subscription_expires'] != null
          ? DateTime.parse(profile!['subscription_expires'] as String)
          : null,
      totalFantasyPoints:
          (profile?['total_fantasy_points'] as num?)?.toDouble() ?? 0,
      tournamentsPlayed: profile?['tournaments_played'] as int? ?? 0,
      createdAt: authUser['created_at'] != null
          ? DateTime.parse(authUser['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'subscription_tier': subscriptionTier,
      'subscription_expires': subscriptionExpires?.toIso8601String(),
      'total_fantasy_points': totalFantasyPoints,
      'tournaments_played': tournamentsPlayed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to User entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      subscriptionTier: subscriptionTier,
      subscriptionExpires: subscriptionExpires,
      totalFantasyPoints: totalFantasyPoints,
      tournamentsPlayed: tournamentsPlayed,
      createdAt: createdAt,
    );
  }
}
