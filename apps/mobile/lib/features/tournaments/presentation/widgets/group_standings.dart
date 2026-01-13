import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../teams/domain/entities/team.dart';
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

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tournamentTeamsProvider(tournamentId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedTeams.length,
            itemBuilder: (context, index) {
              final groupName = groupedTeams.keys.elementAt(index);
              final groupTeams = groupedTeams[groupName]!;
              return GroupStandingsCard(
                groupName: groupName,
                teams: groupTeams,
              );
            },
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

    // Sort teams within each group by placement/seed
    for (final group in grouped.values) {
      group.sort((a, b) {
        // Sort by placement first, then by seed
        final aPlacement = a.placement ?? 999;
        final bPlacement = b.placement ?? 999;
        if (aPlacement != bPlacement) {
          return aPlacement.compareTo(bPlacement);
        }
        final aSeed = a.seed ?? 999;
        final bSeed = b.seed ?? 999;
        return aSeed.compareTo(bSeed);
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
                  width: 40,
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
                  width: 40,
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
                    'Diff',
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
    // Mock win/loss data - in real app, this would come from match results
    final wins = team.placement != null ? (teams_count - team.placement! + 1).clamp(0, 10) : 0;
    final losses = team.placement != null ? (team.placement! - 1).clamp(0, 10) : 0;
    final diff = wins - losses;

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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: team.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            team.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildLogoPlaceholder(context),
                          ),
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
            width: 40,
            child: Text(
              '$wins',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          // Losses
          SizedBox(
            width: 40,
            child: Text(
              '$losses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          // Diff
          SizedBox(
            width: 50,
            child: Text(
              diff >= 0 ? '+$diff' : '$diff',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: diff >= 0 ? Colors.green[700] : Colors.red[700],
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

  // Placeholder for team count in group
  int get teams_count => 4;
}
