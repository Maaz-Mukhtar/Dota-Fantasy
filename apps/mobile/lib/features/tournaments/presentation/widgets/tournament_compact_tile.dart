import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/tournament.dart';

/// Option 3: Compact tile with tier accent bar on left
/// No card shadows, single background, tight spacing
class TournamentCompactTile extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback? onTap;

  const TournamentCompactTile({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tier accent bar
              Container(
                width: 4,
                color: _getTierColor(),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      // Tier label
                      SizedBox(
                        width: 48,
                        child: Text(
                          tournament.tierDisplayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getTierColor(),
                          ),
                        ),
                      ),

                      // Vertical divider
                      Container(
                        width: 1,
                        height: 32,
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                      ),
                      const SizedBox(width: 12),

                      // Tournament info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tournament.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatDateRange()}  •  ${tournament.formattedPrizePool}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status indicator
                      _buildStatusIndicator(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTierColor() {
    switch (tournament.tier.toLowerCase()) {
      case 'ti':
        return AppTheme.tierGold;
      case 'major':
        return AppTheme.tierGold;
      case 'tier1':
        return AppTheme.tierSilver;
      case 'tier2':
        return AppTheme.tierBronze;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusIndicator(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (tournament.status) {
      case 'ongoing':
        statusColor = AppTheme.statusLive;
        statusIcon = Icons.play_circle_filled;
        break;
      case 'upcoming':
        statusColor = AppTheme.statusUpcoming;
        statusIcon = Icons.schedule;
        break;
      case 'completed':
        statusColor = AppTheme.statusCompleted;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        statusIcon,
        color: statusColor,
        size: 20,
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
