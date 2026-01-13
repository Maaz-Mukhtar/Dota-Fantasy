import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../matches/domain/entities/match.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/tournament_provider.dart';

/// Tournament schedule screen showing all matches
class TournamentScheduleScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentScheduleScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(tournamentMatchesProvider(tournamentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
      ),
      body: matchesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, stack) => app.AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(tournamentMatchesProvider(tournamentId)),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildMatchesList(context, ref, matches);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No matches scheduled',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Match schedule will appear once announced',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList(
      BuildContext context, WidgetRef ref, List<Match> matches) {
    // Group matches by status
    final liveMatches = matches.where((m) => m.isLive).toList();
    final upcomingMatches = matches.where((m) => m.isUpcoming).toList()
      ..sort((a, b) =>
          (a.scheduledAt ?? DateTime(2100)).compareTo(b.scheduledAt ?? DateTime(2100)));
    final completedMatches = matches.where((m) => m.isCompleted).toList()
      ..sort((a, b) =>
          (b.scheduledAt ?? DateTime(1900)).compareTo(a.scheduledAt ?? DateTime(1900)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tournamentMatchesProvider(tournamentId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (liveMatches.isNotEmpty) ...[
            _buildSectionHeader(context, 'Live Now', AppTheme.statusLive, liveMatches.length),
            ...liveMatches.map((m) => _MatchCard(match: m)),
            const SizedBox(height: 24),
          ],
          if (upcomingMatches.isNotEmpty) ...[
            _buildSectionHeader(context, 'Upcoming', AppTheme.statusUpcoming, upcomingMatches.length),
            ...upcomingMatches.map((m) => _MatchCard(match: m)),
            const SizedBox(height: 24),
          ],
          if (completedMatches.isNotEmpty) ...[
            _buildSectionHeader(context, 'Completed', AppTheme.statusCompleted, completedMatches.length),
            ...completedMatches.map((m) => _MatchCard(match: m)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Match card widget
class _MatchCard extends StatelessWidget {
  final Match match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Match header (stage/round info)
            if (match.stage != null || match.round != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (match.stage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              match.stage!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                        if (match.round != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            match.round!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        match.bestOfDisplay,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            // Teams row
            Row(
              children: [
                // Team 1
                Expanded(
                  child: _TeamDisplay(
                    team: match.team1,
                    score: match.team1Score,
                    isWinner: match.isCompleted &&
                        match.winner?.id == match.team1?.id,
                    alignment: CrossAxisAlignment.start,
                  ),
                ),
                // Score or VS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildMatchStatus(context),
                ),
                // Team 2
                Expanded(
                  child: _TeamDisplay(
                    team: match.team2,
                    score: match.team2Score,
                    isWinner: match.isCompleted &&
                        match.winner?.id == match.team2?.id,
                    alignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
            // Schedule info
            if (match.isUpcoming && match.scheduledAt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatSchedule(match.scheduledAt!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchStatus(BuildContext context) {
    if (match.isLive) {
      return Column(
        children: [
          Text(
            match.scoreDisplay,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.statusLive,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else if (match.isCompleted) {
      return Text(
        match.scoreDisplay,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      );
    } else {
      return Column(
        children: [
          Text(
            'VS',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
          ),
          if (match.scheduledAt != null)
            Text(
              _formatTime(match.scheduledAt!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
        ],
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatSchedule(DateTime dateTime) {
    return DateFormat('EEEE, MMM d • HH:mm').format(dateTime);
  }
}

/// Team display widget
class _TeamDisplay extends StatelessWidget {
  final Team? team;
  final int? score;
  final bool isWinner;
  final CrossAxisAlignment alignment;

  const _TeamDisplay({
    required this.team,
    required this.score,
    required this.isWinner,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        // Team logo
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: isWinner
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: team?.logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    team!.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildLogoPlaceholder(context),
                  ),
                )
              : _buildLogoPlaceholder(context),
        ),
        const SizedBox(height: 8),
        // Team name
        Text(
          team?.shortName ?? 'TBD',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: team == null ? Colors.grey[500] : null,
              ),
          textAlign:
              alignment == CrossAxisAlignment.end ? TextAlign.right : TextAlign.left,
        ),
        // Winner badge
        if (isWinner)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'WINNER',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogoPlaceholder(BuildContext context) {
    return Center(
      child: Text(
        team?.shortName ?? '?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
