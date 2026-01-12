import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/tournament.dart';

/// Tournament card widget
class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback? onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with tier badge and status
              Row(
                children: [
                  _buildTierBadge(context),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 12),

              // Info row
              Row(
                children: [
                  // Date
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateRange(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Prize pool
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tournament.formattedPrizePool,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                      ),
                    ],
                  ),
                ],
              ),

              // Region if available
              if (tournament.region != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.public,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tournament.region!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierBadge(BuildContext context) {
    Color badgeColor;
    switch (tournament.tier.toLowerCase()) {
      case 'ti':
        badgeColor = AppTheme.tierGold;
        break;
      case 'major':
        badgeColor = AppTheme.tierGold;
        break;
      case 'tier1':
        badgeColor = AppTheme.tierSilver;
        break;
      case 'tier2':
        badgeColor = AppTheme.tierBronze;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        tournament.tierDisplayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (tournament.status) {
      case 'ongoing':
        statusColor = AppTheme.statusLive;
        statusText = 'LIVE';
        break;
      case 'upcoming':
        statusColor = AppTheme.statusUpcoming;
        statusText = 'UPCOMING';
        break;
      case 'completed':
        statusColor = AppTheme.statusCompleted;
        statusText = 'COMPLETED';
        break;
      default:
        statusColor = Colors.grey;
        statusText = tournament.status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatDateRange() {
    final dateFormat = DateFormat('MMM d');
    final startStr = dateFormat.format(tournament.startDate);

    if (tournament.endDate != null) {
      final endStr = dateFormat.format(tournament.endDate!);
      return '$startStr - $endStr';
    }

    return startStr;
  }
}
