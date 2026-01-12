import 'package:equatable/equatable.dart';

/// Tournament entity
class Tournament extends Equatable {
  final String id;
  final String name;
  final String tier;
  final DateTime startDate;
  final DateTime? endDate;
  final double? prizePool;
  final String? format;
  final String? liquipediaUrl;
  final String? logoUrl;
  final String status;
  final String? region;

  const Tournament({
    required this.id,
    required this.name,
    required this.tier,
    required this.startDate,
    this.endDate,
    this.prizePool,
    this.format,
    this.liquipediaUrl,
    this.logoUrl,
    required this.status,
    this.region,
  });

  /// Check if tournament is live
  bool get isLive => status == 'ongoing';

  /// Check if tournament is upcoming
  bool get isUpcoming => status == 'upcoming';

  /// Check if tournament is completed
  bool get isCompleted => status == 'completed';

  /// Get tier display name
  String get tierDisplayName {
    switch (tier.toLowerCase()) {
      case 'ti':
        return 'The International';
      case 'major':
        return 'Major';
      case 'tier1':
        return 'Tier 1';
      case 'tier2':
        return 'Tier 2';
      case 'tier3':
        return 'Tier 3';
      default:
        return tier;
    }
  }

  /// Get formatted prize pool
  String get formattedPrizePool {
    if (prizePool == null) return 'TBD';
    if (prizePool! >= 1000000) {
      return '\$${(prizePool! / 1000000).toStringAsFixed(1)}M';
    }
    if (prizePool! >= 1000) {
      return '\$${(prizePool! / 1000).toStringAsFixed(0)}K';
    }
    return '\$${prizePool!.toStringAsFixed(0)}';
  }

  @override
  List<Object?> get props => [id, name, tier, startDate, status];
}
