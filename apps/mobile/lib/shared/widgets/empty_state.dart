import 'package:flutter/material.dart';

/// Empty state widget for displaying when there's no data
class EmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  /// Creates an empty state for no tournaments
  factory EmptyState.noTournaments({
    VoidCallback? onRefresh,
  }) {
    return EmptyState(
      title: 'No tournaments',
      description: 'Check back later for upcoming DPC events.',
      icon: Icons.emoji_events_outlined,
      actionLabel: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
    );
  }

  /// Creates an empty state for no teams
  factory EmptyState.noFantasyTeams({
    VoidCallback? onCreate,
  }) {
    return EmptyState(
      title: 'No fantasy teams',
      description: 'Create your first fantasy team to get started!',
      icon: Icons.groups_outlined,
      actionLabel: 'Create Team',
      onAction: onCreate,
    );
  }

  /// Creates an empty state for no leagues
  factory EmptyState.noLeagues({
    VoidCallback? onJoin,
  }) {
    return EmptyState(
      title: 'No leagues',
      description: 'Join or create a league to compete with friends.',
      icon: Icons.leaderboard_outlined,
      actionLabel: 'Join League',
      onAction: onJoin,
    );
  }

  /// Creates an empty state for no search results
  factory EmptyState.noSearchResults({
    String? query,
  }) {
    return EmptyState(
      title: 'No results found',
      description: query != null
          ? 'No results found for "$query". Try a different search.'
          : 'Try adjusting your search or filters.',
      icon: Icons.search_off_outlined,
    );
  }

  /// Creates an empty state for no players
  factory EmptyState.noPlayers() {
    return const EmptyState(
      title: 'No players',
      description: 'Player data will be available soon.',
      icon: Icons.person_off_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
