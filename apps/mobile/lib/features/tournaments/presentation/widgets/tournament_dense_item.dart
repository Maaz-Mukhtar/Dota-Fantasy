import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/tournament.dart';

/// Option 4: Dense list item with minimal padding
/// Status dot, tier badge inline, date on far right
class TournamentDenseItem extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback? onTap;

  const TournamentDenseItem({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Tier badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getTierColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tournament.tierDisplayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getTierColor(),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Tournament name and prize pool
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tournament.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    tournament.formattedPrizePool,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Date on far right
            Text(
              _formatDate(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (tournament.status) {
      case 'ongoing':
        return AppTheme.statusLive;
      case 'upcoming':
        return AppTheme.statusUpcoming;
      case 'completed':
        return AppTheme.statusCompleted;
      default:
        return Colors.grey;
    }
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

  String _formatDate() {
    final dateFormat = DateFormat('MMM d');
    return dateFormat.format(tournament.startDate);
  }
}
