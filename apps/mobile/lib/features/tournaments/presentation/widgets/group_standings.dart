import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../teams/domain/entities/team.dart';
import '../../../matches/domain/entities/match.dart';
import '../providers/tournament_provider.dart';

/// Group standings tab for tournament
class GroupStandingsTab extends ConsumerWidget {
  final String tournamentId;

  const GroupStandingsTab({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(tournamentTeamsProvider(tournamentId));
    final seedingMatchesAsync =
        ref.watch(tournamentSeedingDeciderMatchesProvider(tournamentId));

    return teamsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, stack) => app.AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(tournamentTeamsProvider(tournamentId)),
      ),
      data: (teams) {
        // Group teams by their group name
        final groupedTeams = _groupTeamsByGroup(teams);

        if (groupedTeams.isEmpty) {
          return _buildNoGroupsState(context);
        }

        // Get seeding decider matches if available
        final seedingMatches = seedingMatchesAsync.whenOrNull(
          data: (matches) => matches,
        );

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tournamentTeamsProvider(tournamentId));
            ref.invalidate(
                tournamentSeedingDeciderMatchesProvider(tournamentId));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Group standings cards
              ...groupedTeams.entries.map((entry) => GroupStandingsCard(
                    groupName: entry.key,
                    teams: entry.value,
                  )),

              // Seeding Decider section (if matches exist)
              if (seedingMatches != null && seedingMatches.isNotEmpty) ...[
                const SizedBox(height: 8),
                SeedingDeciderCard(matches: seedingMatches),
              ],
            ],
          ),
        );
      },
    );
  }

  Map<String, List<Team>> _groupTeamsByGroup(List<Team> teams) {
    final grouped = <String, List<Team>>{};

    for (final team in teams) {
      final groupName = team.groupName ?? 'Unassigned';
      grouped.putIfAbsent(groupName, () => []).add(team);
    }

    // Sort teams within each group by wins (desc), then by games won (desc)
    for (final group in grouped.values) {
      group.sort((a, b) {
        // Sort by wins first (descending)
        final aWins = a.wins ?? 0;
        final bWins = b.wins ?? 0;
        if (aWins != bWins) {
          return bWins.compareTo(aWins); // Descending
        }
        // If wins are equal, sort by games won (descending)
        final aGameWins = a.gameWins ?? 0;
        final bGameWins = b.gameWins ?? 0;
        return bGameWins.compareTo(aGameWins); // Descending
      });
    }

    // Sort groups alphabetically (Group A, Group B, etc.)
    final sortedGroups = Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Remove "Unassigned" if it's empty or all teams have groups
    if (sortedGroups.containsKey('Unassigned') &&
        sortedGroups.length > 1) {
      sortedGroups.remove('Unassigned');
    }

    return sortedGroups;
  }

  Widget _buildNoGroupsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Group stage not available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Teams have not been assigned to groups yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }
}

/// Individual group standings card
class GroupStandingsCard extends StatelessWidget {
  final String groupName;
  final List<Team> teams;

  const GroupStandingsCard({
    super.key,
    required this.groupName,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.groups,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  groupName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          // Standings table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 32), // Rank column
                Expanded(
                  flex: 3,
                  child: Text(
                    'Team',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    'W',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    'D',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    'L',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'Games',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Team rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: teams.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _TeamStandingRow(
                rank: index + 1,
                team: teams[index],
                isQualified: index < 2, // Top 2 typically qualify
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Individual team standing row
class _TeamStandingRow extends StatelessWidget {
  final int rank;
  final Team team;
  final bool isQualified;

  const _TeamStandingRow({
    required this.rank,
    required this.team,
    required this.isQualified,
  });

  @override
  Widget build(BuildContext context) {
    // Use actual standings data from API
    final wins = team.wins ?? 0;
    final losses = team.losses ?? 0;
    final draws = team.draws ?? 0;
    final gameWins = team.gameWins ?? 0;
    final gameLosses = team.gameLosses ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isQualified
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getRankColor(rank).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getRankColor(rank),
                  ),
                ),
              ),
            ),
          ),
          // Team name and logo
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: team.logoUrl != null
                      ? Image.network(
                          team.logoUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              _buildLogoPlaceholder(context),
                        )
                      : _buildLogoPlaceholder(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    team.shortName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Wins
          SizedBox(
            width: 32,
            child: Text(
              '$wins',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          // Draws
          SizedBox(
            width: 32,
            child: Text(
              '$draws',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          // Losses
          SizedBox(
            width: 32,
            child: Text(
              '$losses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          // Games (wins-losses)
          SizedBox(
            width: 50,
            child: Text(
              '$gameWins-$gameLosses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPlaceholder(BuildContext context) {
    return Center(
      child: Text(
        team.shortName.substring(0, team.shortName.length.clamp(0, 2)),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[700]!;
      case 2:
        return Colors.grey[600]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.grey[500]!;
    }
  }
}

/// Seeding Decider (Phase 2) matches card
class SeedingDeciderCard extends StatelessWidget {
  final List<Match> matches;

  const SeedingDeciderCard({
    super.key,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    // Group matches into series (by teams playing each other)
    final series = _groupMatchesIntoSeries(matches);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_esports,
                  size: 20,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Phase 2: Seeding Decider',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Tiebreaker matches to determine final group placements',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const Divider(height: 1),
          // Series results
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: series.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _SeedingDeciderRow(series: series[index]);
            },
          ),
        ],
      ),
    );
  }

  /// Group individual games into Bo3 series by team matchups
  List<_SeriesResult> _groupMatchesIntoSeries(List<Match> matches) {
    final seriesMap = <String, _SeriesResult>{};

    for (final match in matches) {
      // Create a key based on both teams (order-independent)
      final team1Id = match.team1?.id ?? '';
      final team2Id = match.team2?.id ?? '';
      final key = [team1Id, team2Id]..sort();
      final seriesKey = key.join('-');

      if (!seriesMap.containsKey(seriesKey)) {
        seriesMap[seriesKey] = _SeriesResult(
          team1: match.team1,
          team2: match.team2,
          team1Wins: 0,
          team2Wins: 0,
          games: [],
        );
      }

      final series = seriesMap[seriesKey]!;
      series.games.add(match);

      // Count wins based on the original match result
      if (match.team1Score > match.team2Score) {
        // Team1 won this game
        if (match.team1?.id == series.team1?.id) {
          series.team1Wins++;
        } else {
          series.team2Wins++;
        }
      } else if (match.team2Score > match.team1Score) {
        // Team2 won this game
        if (match.team2?.id == series.team2?.id) {
          series.team2Wins++;
        } else {
          series.team1Wins++;
        }
      }
    }

    // Sort by start time of first game
    final seriesList = seriesMap.values.toList();
    seriesList.sort((a, b) {
      final aTime = a.games.isNotEmpty ? a.games.first.startedAt : null;
      final bTime = b.games.isNotEmpty ? b.games.first.startedAt : null;
      if (aTime != null && bTime != null) {
        return aTime.compareTo(bTime);
      }
      return 0;
    });

    return seriesList;
  }
}

/// Internal class to hold series result
class _SeriesResult {
  final Team? team1;
  final Team? team2;
  int team1Wins;
  int team2Wins;
  final List<Match> games;

  _SeriesResult({
    required this.team1,
    required this.team2,
    required this.team1Wins,
    required this.team2Wins,
    required this.games,
  });

  bool get team1Won => team1Wins > team2Wins;
  bool get team2Won => team2Wins > team1Wins;
}

/// Individual seeding decider series row
class _SeedingDeciderRow extends StatelessWidget {
  final _SeriesResult series;

  const _SeedingDeciderRow({required this.series});

  @override
  Widget build(BuildContext context) {
    final team1 = series.team1;
    final team2 = series.team2;
    // Get the seeding label from the first game's round field (e.g., "A1 vs B3/B4")
    final seedingLabel = series.games.isNotEmpty ? series.games.first.round : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Seeding label (e.g., "A1 vs B3/B4")
          if (seedingLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  seedingLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                ),
              ),
            ),
          // Match row
          Row(
            children: [
              // Team 1
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        team1?.shortName ?? 'TBD',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  series.team1Won ? FontWeight.bold : FontWeight.normal,
                              color: series.team1Won
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTeamLogo(context, team1),
                  ],
                ),
              ),

              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${series.team1Wins}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: series.team1Won ? Colors.green[700] : null,
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '-',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${series.team2Wins}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: series.team2Won ? Colors.green[700] : null,
                          ),
                    ),
                  ],
                ),
              ),

              // Team 2
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildTeamLogo(context, team2),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        team2?.shortName ?? 'TBD',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  series.team2Won ? FontWeight.bold : FontWeight.normal,
                              color: series.team2Won
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(BuildContext context, Team? team) {
    return Container(
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: team?.logoUrl != null
          ? Image.network(
              team!.logoUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildLogoPlaceholder(context, team),
            )
          : _buildLogoPlaceholder(context, team),
    );
  }

  Widget _buildLogoPlaceholder(BuildContext context, Team? team) {
    final name = team?.shortName ?? '?';
    return Center(
      child: Text(
        name.substring(0, name.length.clamp(0, 2)),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
