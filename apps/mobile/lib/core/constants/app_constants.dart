/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'Dota Fantasy';

  /// App version
  static const String appVersion = '1.0.0';

  /// Default page size for pagination
  static const int defaultPageSize = 20;

  /// Cache duration for tournaments (in minutes)
  static const int tournamentCacheDuration = 30;

  /// Cache duration for player stats (in minutes)
  static const int playerStatsCacheDuration = 60;

  /// Roster lock time before match (in minutes)
  static const int rosterLockMinutes = 30;

  /// Player roles
  static const List<String> playerRoles = [
    'carry',
    'mid',
    'offlane',
    'support4',
    'support5',
  ];

  /// Player role display names
  static const Map<String, String> roleDisplayNames = {
    'carry': 'Carry',
    'mid': 'Mid',
    'offlane': 'Offlane',
    'support4': 'Support 4',
    'support5': 'Support 5',
  };

  /// Tournament tiers
  static const List<String> tournamentTiers = [
    'ti',
    'major',
    'tier1',
    'tier2',
    'tier3',
  ];

  /// Tournament tier display names
  static const Map<String, String> tierDisplayNames = {
    'ti': 'The International',
    'major': 'Major',
    'tier1': 'Tier 1',
    'tier2': 'Tier 2',
    'tier3': 'Tier 3',
  };

  /// Tournament status options
  static const List<String> tournamentStatuses = [
    'upcoming',
    'ongoing',
    'completed',
  ];
}
