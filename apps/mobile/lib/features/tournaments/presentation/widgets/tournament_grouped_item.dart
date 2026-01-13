import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/tournament.dart';

/// Tournament item for grouped sections design (Option 2)
/// Clean look without status badge (status shown in section header)
class TournamentGroupedItem extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback? onTap;
  final bool isLast;

  const TournamentGroupedItem({
    super.key,
    required this.tournament,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tournament info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name with tier
                  Row(
                    children: [
                      _buildTierDot(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tournament.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Details row
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Text(
                          _formatDateRange(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        _buildDot(isDark),
                        Text(
                          tournament.formattedPrizePool,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (tournament.region != null) ...[
                          _buildDot(isDark),
                          Text(
                            tournament.region!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierDot() {
    Color tierColor;
    switch (tournament.tier.toLowerCase()) {
      case 'ti':
        tierColor = AppTheme.tierGold;
        break;
      case 'major':
        tierColor = AppTheme.tierGold;
        break;
      case 'tier1':
        tierColor = AppTheme.tierSilver;
        break;
      case 'tier2':
        tierColor = AppTheme.tierBronze;
        break;
      default:
        tierColor = Colors.grey;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: tierColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDot(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '•',
        style: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
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
