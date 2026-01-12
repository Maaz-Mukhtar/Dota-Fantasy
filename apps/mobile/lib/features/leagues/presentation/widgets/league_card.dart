import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/league.dart';

/// League card widget
class LeagueCard extends StatelessWidget {
  final League league;
  final VoidCallback? onTap;

  const LeagueCard({
    super.key,
    required this.league,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          league.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (league.tournament != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            league.tournament!.name,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildDraftStatusBadge(context),
                ],
              ),
              const SizedBox(height: 16),
              // Stats row
              Row(
                children: [
                  _buildStatItem(
                    context,
                    Icons.people,
                    league.memberCountDisplay,
                    'Members',
                  ),
                  const SizedBox(width: 24),
                  if (league.myMembership != null)
                    _buildStatItem(
                      context,
                      Icons.leaderboard,
                      league.myMembership!.rank?.toString() ?? '-',
                      'Rank',
                    ),
                  const Spacer(),
                  if (league.isOwner)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OWNER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              // Points row (if member has points)
              if (league.myMembership != null &&
                  league.myMembership!.totalPoints > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Points',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        league.myMembership!.totalPoints.toStringAsFixed(1),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraftStatusBadge(BuildContext context) {
    Color color;
    switch (league.draftStatus) {
      case DraftStatus.pending:
        color = AppTheme.statusUpcoming;
        break;
      case DraftStatus.inProgress:
        color = AppTheme.statusLive;
        break;
      case DraftStatus.completed:
        color = AppTheme.statusCompleted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        league.draftStatusDisplay,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
