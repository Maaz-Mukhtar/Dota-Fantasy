import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/tournament.dart';

/// Option 1: Continuous list item with no card styling
/// Clean, minimal design with subtle dividers
class TournamentListItem extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback? onTap;
  final bool showDivider;

  const TournamentListItem({
    super.key,
    required this.tournament,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tier badge on left
                _buildTierBadge(context),
                const SizedBox(width: 12),

                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tournament name
                      Text(
                        tournament.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Date and prize pool row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateRange(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tournament.formattedPrizePool,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge on right
                _buildStatusBadge(context),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
      ],
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
      width: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
      ),
      child: Text(
        tournament.tierDisplayName,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData? statusIcon;

    switch (tournament.status) {
      case 'ongoing':
        statusColor = AppTheme.statusLive;
        statusText = 'LIVE';
        statusIcon = Icons.circle;
        break;
      case 'upcoming':
        statusColor = AppTheme.statusUpcoming;
        statusText = 'SOON';
        statusIcon = Icons.schedule;
        break;
      case 'completed':
        statusColor = AppTheme.statusCompleted;
        statusText = 'DONE';
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusText = tournament.status.toUpperCase();
        statusIcon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusIcon != null) ...[
            Icon(
              statusIcon,
              size: 10,
              color: statusColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            statusText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
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
