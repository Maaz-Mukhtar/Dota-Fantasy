import 'package:equatable/equatable.dart';

/// User entity representing the authenticated user
class User extends Equatable {
  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String subscriptionTier;
  final DateTime? subscriptionExpires;
  final double totalFantasyPoints;
  final int tournamentsPlayed;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.subscriptionTier = 'free',
    this.subscriptionExpires,
    this.totalFantasyPoints = 0,
    this.tournamentsPlayed = 0,
    required this.createdAt,
  });

  /// Check if user has an active premium subscription
  bool get isPremium {
    if (subscriptionTier == 'free') return false;
    if (subscriptionExpires == null) return true;
    return subscriptionExpires!.isAfter(DateTime.now());
  }

  /// Check if user has a pro subscription
  bool get isPro => isPremium && subscriptionTier == 'pro';

  /// Check if user has a season pass
  bool get hasSeasonPass => isPremium && subscriptionTier == 'season';

  /// Get the display name or fall back to username or email
  String get name => displayName ?? username ?? email.split('@').first;

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        displayName,
        avatarUrl,
        subscriptionTier,
        subscriptionExpires,
        totalFantasyPoints,
        tournamentsPlayed,
        createdAt,
      ];

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? subscriptionTier,
    DateTime? subscriptionExpires,
    double? totalFantasyPoints,
    int? tournamentsPlayed,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpires: subscriptionExpires ?? this.subscriptionExpires,
      totalFantasyPoints: totalFantasyPoints ?? this.totalFantasyPoints,
      tournamentsPlayed: tournamentsPlayed ?? this.tournamentsPlayed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
