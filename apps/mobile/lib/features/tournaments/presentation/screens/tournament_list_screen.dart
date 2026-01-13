import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/entities/tournament.dart';
import '../providers/tournament_provider.dart';
import '../widgets/tournament_grouped_item.dart';
import '../widgets/tournament_section_header.dart';

/// Tournament list screen - Option 2: Grouped Sections
/// No tabs, single scrollable list with sticky section headers
class TournamentListScreen extends ConsumerWidget {
  const TournamentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tournamentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        elevation: 0,
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TournamentListState state) {
    if (state.isLoading && state.tournaments.isEmpty) {
      return const LoadingIndicator();
    }

    if (state.error != null && state.tournaments.isEmpty) {
      return app.AppErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(tournamentListProvider.notifier).loadTournaments(refresh: true),
      );
    }

    if (state.tournaments.isEmpty) {
      return EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No Tournaments',
        description: 'No tournaments available at the moment.',
        actionLabel: 'Refresh',
        onAction: () => ref.read(tournamentListProvider.notifier).loadTournaments(refresh: true),
      );
    }

    // Group tournaments by status
    final grouped = _groupTournaments(state.tournaments);

    return RefreshIndicator(
      onRefresh: () => ref.read(tournamentListProvider.notifier).loadTournaments(refresh: true),
      child: CustomScrollView(
        slivers: [
          // Live section
          if (grouped.live.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: TournamentSectionHeader.live(count: grouped.live.length),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tournament = grouped.live[index];
                  return TournamentGroupedItem(
                    tournament: tournament,
                    isLast: index == grouped.live.length - 1,
                    onTap: () => context.push('/tournaments/${tournament.id}'),
                  );
                },
                childCount: grouped.live.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // Upcoming section
          if (grouped.upcoming.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: TournamentSectionHeader.upcoming(count: grouped.upcoming.length),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tournament = grouped.upcoming[index];
                  return TournamentGroupedItem(
                    tournament: tournament,
                    isLast: index == grouped.upcoming.length - 1,
                    onTap: () => context.push('/tournaments/${tournament.id}'),
                  );
                },
                childCount: grouped.upcoming.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // Completed section
          if (grouped.completed.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: TournamentSectionHeader.completed(count: grouped.completed.length),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tournament = grouped.completed[index];
                  return TournamentGroupedItem(
                    tournament: tournament,
                    isLast: index == grouped.completed.length - 1,
                    onTap: () => context.push('/tournaments/${tournament.id}'),
                  );
                },
                childCount: grouped.completed.length,
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Loading indicator
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  _GroupedTournaments _groupTournaments(List<Tournament> tournaments) {
    final live = <Tournament>[];
    final upcoming = <Tournament>[];
    final completed = <Tournament>[];

    for (final t in tournaments) {
      switch (t.status) {
        case 'ongoing':
          live.add(t);
          break;
        case 'upcoming':
          upcoming.add(t);
          break;
        case 'completed':
          completed.add(t);
          break;
      }
    }

    return _GroupedTournaments(
      live: live,
      upcoming: upcoming,
      completed: completed,
    );
  }
}

class _GroupedTournaments {
  final List<Tournament> live;
  final List<Tournament> upcoming;
  final List<Tournament> completed;

  _GroupedTournaments({
    required this.live,
    required this.upcoming,
    required this.completed,
  });
}
