/// Team entity
class Team {
  final String id;
  final String name;
  final String? tag;
  final String? logoUrl;
  final String? region;
  final String? liquipediaUrl;
  final DateTime createdAt;

  // Tournament-specific fields (when part of a tournament)
  final int? seed;
  final String? groupName;
  final int? placement;
  final double? prizeWon;

  // Standings fields
  final int? wins;
  final int? losses;
  final int? draws;
  final int? gameWins;
  final int? gameLosses;

  const Team({
    required this.id,
    required this.name,
    this.tag,
    this.logoUrl,
    this.region,
    this.liquipediaUrl,
    required this.createdAt,
    this.seed,
    this.groupName,
    this.placement,
    this.prizeWon,
    this.wins,
    this.losses,
    this.draws,
    this.gameWins,
    this.gameLosses,
  });

  /// Display name with tag if available
  String get displayName => tag != null ? '$name ($tag)' : name;

  /// Short name (tag if available, otherwise first 3 chars of name)
  String get shortName => tag ?? name.substring(0, name.length > 3 ? 3 : name.length);

  /// Formatted prize won
  String get formattedPrizeWon {
    if (prizeWon == null) return '-';
    if (prizeWon! >= 1000000) {
      return '\$${(prizeWon! / 1000000).toStringAsFixed(1)}M';
    }
    if (prizeWon! >= 1000) {
      return '\$${(prizeWon! / 1000).toStringAsFixed(0)}K';
    }
    return '\$${prizeWon!.toStringAsFixed(0)}';
  }

  /// Placement display (1st, 2nd, 3rd, etc.)
  String get placementDisplay {
    if (placement == null) return '-';
    switch (placement) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${placement}th';
    }
  }
}
