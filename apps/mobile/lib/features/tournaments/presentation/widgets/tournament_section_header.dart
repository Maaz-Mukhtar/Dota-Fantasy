import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Section header for grouped tournament list
class TournamentSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color? color;

  const TournamentSectionHeader({
    super.key,
    required this.title,
    required this.count,
    this.color,
  });

  factory TournamentSectionHeader.live({required int count}) {
    return TournamentSectionHeader(
      title: 'LIVE',
      count: count,
      color: AppTheme.statusLive,
    );
  }

  factory TournamentSectionHeader.upcoming({required int count}) {
    return TournamentSectionHeader(
      title: 'UPCOMING',
      count: count,
      color: AppTheme.statusUpcoming,
    );
  }

  factory TournamentSectionHeader.completed({required int count}) {
    return TournamentSectionHeader(
      title: 'COMPLETED',
      count: count,
      color: AppTheme.statusCompleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        border: Border(
          left: BorderSide(
            color: effectiveColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: effectiveColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: effectiveColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
