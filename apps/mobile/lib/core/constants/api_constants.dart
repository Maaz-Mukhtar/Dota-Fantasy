import 'env.dart';

/// API endpoint constants
class ApiConstants {
  ApiConstants._();

  /// Base URL for API requests
  static String get baseUrl => Env.apiBaseUrl;

  // Auth endpoints
  static const String authMe = '/auth/me';
  static const String authProfile = '/auth/profile';
  static const String authSettings = '/auth/settings';

  // Tournament endpoints
  static const String tournaments = '/tournaments';
  static String tournamentById(String id) => '/tournaments/$id';
  static String tournamentTeams(String id) => '/tournaments/$id/teams';
  static String tournamentMatches(String id) => '/tournaments/$id/matches';
  static String tournamentStandings(String id) => '/tournaments/$id/standings';

  // Player endpoints
  static const String players = '/players';
  static String playerById(String id) => '/players/$id';
  static String playerStats(String id) => '/players/$id/stats';
  static String playerFantasyAvg(String id) => '/players/$id/fantasy-avg';

  // Match endpoints
  static String matchById(String id) => '/matches/$id';
  static String matchGames(String id) => '/matches/$id/games';
  static String matchStats(String id) => '/matches/$id/stats';

  // Fantasy endpoints
  static const String fantasyLeagues = '/fantasy/leagues';
  static String fantasyLeagueById(String id) => '/fantasy/leagues/$id';
  static String fantasyLeagueJoin(String id) => '/fantasy/leagues/$id/join';
  static String fantasyLeagueLeaderboard(String id) =>
      '/fantasy/leagues/$id/leaderboard';
  static const String fantasyTeams = '/fantasy/teams';
  static String fantasyTeamById(String id) => '/fantasy/teams/$id';
  static String fantasyTeamRoster(String id) => '/fantasy/teams/$id/roster';
  static String fantasyTeamPoints(String id) => '/fantasy/teams/$id/points';

  // Leaderboard endpoints
  static const String globalLeaderboard = '/leaderboard/global';
}
