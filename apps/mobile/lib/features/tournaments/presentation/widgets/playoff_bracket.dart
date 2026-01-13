import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../matches/domain/entities/match.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/tournament_provider.dart';

/// Playoff bracket tab for tournament
class PlayoffBracketTab extends ConsumerWidget {
  final String tournamentId;

  const PlayoffBracketTab({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(tournamentMatchesProvider(tournamentId));

    return matchesAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, stack) => app.AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(tournamentMatchesProvider(tournamentId)),
      ),
      data: (matches) {
        // Filter playoff matches (those with bracket-related stages)
        final playoffMatches = _filterPlayoffMatches(matches);

        if (playoffMatches.isEmpty) {
          return _buildNoPlayoffsState(context);
        }

        // Group matches by round/stage
        final roundedMatches = _groupMatchesByRound(playoffMatches);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tournamentMatchesProvider(tournamentId));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: roundedMatches.entries.map((entry) {
                    return _BracketRound(
                      roundName: entry.key,
                      matches: entry.value,
                      isLast: entry.key == roundedMatches.keys.last,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Match> _filterPlayoffMatches(List<Match> matches) {
    final playoffKeywords = [
      'playoff',
      'bracket',
      'quarterfinal',
      'semifinal',
      'final',
      'upper',
      'lower',
      'winner',
      'loser',
      'elimination',
      'grand',
    ];

    return matches.where((match) {
      final stage = (match.stage ?? '').toLowerCase();
      final round = (match.round ?? '').toLowerCase();
      return playoffKeywords.any((keyword) =>
          stage.contains(keyword) || round.contains(keyword));
    }).toList();
  }

  Map<String, List<Match>> _groupMatchesByRound(List<Match> matches) {
    final grouped = <String, List<Match>>{};

    for (final match in matches) {
      final roundName = _getRoundName(match);
      grouped.putIfAbsent(roundName, () => []).add(match);
    }

    // Sort rounds by their typical order
    final roundOrder = [
      'Round 1',
      'Upper R1',
      'Lower R1',
      'Round 2',
      'Upper R2',
      'Lower R2',
      'Quarterfinals',
      'Upper QF',
      'Lower QF',
      'Semifinals',
      'Upper SF',
      'Lower SF',
      'Upper Final',
      'Lower Final',
      'Grand Final',
      'Final',
    ];

    final sortedGroups = Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) {
          final aIndex = roundOrder.indexWhere(
              (r) => a.key.toLowerCase().contains(r.toLowerCase()));
          final bIndex = roundOrder.indexWhere(
              (r) => b.key.toLowerCase().contains(r.toLowerCase()));
          if (aIndex == -1 && bIndex == -1) return a.key.compareTo(b.key);
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;
          return aIndex.compareTo(bIndex);
        }),
    );

    return sortedGroups;
  }

  String _getRoundName(Match match) {
    if (match.round != null && match.round!.isNotEmpty) {
      return match.round!;
    }
    if (match.stage != null && match.stage!.isNotEmpty) {
      return match.stage!;
    }
    return 'Playoffs';
  }

  Widget _buildNoPlayoffsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Playoffs not available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Playoff bracket will appear once the group stage is complete',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Bracket round column
class _BracketRound extends StatelessWidget {
  final String roundName;
  final List<Match> matches;
  final bool isLast;

  const _BracketRound({
    required this.roundName,
    required this.matches,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Round header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              roundName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          // Match cards
          ...matches.map((match) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BracketMatchCard(match: match),
              )),
        ],
      ),
    );
  }
}

/// Bracket match card
class _BracketMatchCard extends StatelessWidget {
  final Match match;

  const _BracketMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: match.isLive
              ? AppTheme.statusLive
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: match.isLive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Live indicator
          if (match.isLive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.statusLive,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // Teams
          _TeamRow(
            team: match.team1,
            score: match.team1Score,
            isWinner: match.isCompleted && match.winner?.id == match.team1?.id,
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _TeamRow(
            team: match.team2,
            score: match.team2Score,
            isWinner: match.isCompleted && match.winner?.id == match.team2?.id,
          ),
          // Match info footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.bestOfDisplay,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (match.scheduledAt != null && !match.isCompleted)
                  Text(
                    _formatMatchTime(match.scheduledAt!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                if (match.isCompleted)
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppTheme.statusCompleted,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMatchTime(DateTime time) {
    return DateFormat('MMM d, HH:mm').format(time);
  }
}

/// Team row in bracket match card
class _TeamRow extends StatelessWidget {
  final Team? team;
  final int? score;
  final bool isWinner;

  const _TeamRow({
    required this.team,
    required this.score,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isWinner
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
      ),
      child: Row(
        children: [
          // Team logo
          Container(
            width: 28,
            height: 28,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: team?.logoUrl != null
                ? Image.network(
                    team!.logoUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        _buildLogoPlaceholder(context),
                  )
                : _buildLogoPlaceholder(context),
          ),
          const SizedBox(width: 8),
          // Team name
          Expanded(
            child: Text(
              team?.shortName ?? 'TBD',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                    color: team == null ? Colors.grey[500] : null,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Score
          if (score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isWinner
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? Colors.white : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoPlaceholder(BuildContext context) {
    return Center(
      child: Text(
        team != null
            ? team!.shortName.substring(0, team!.shortName.length.clamp(0, 2))
            : '?',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
