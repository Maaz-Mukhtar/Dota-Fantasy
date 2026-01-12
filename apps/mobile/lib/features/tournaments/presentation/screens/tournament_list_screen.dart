import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/tournament_provider.dart';
import '../widgets/tournament_card.dart';

/// Tournament list screen with filtering tabs
class TournamentListScreen extends ConsumerStatefulWidget {
  const TournamentListScreen({super.key});

  @override
  ConsumerState<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends ConsumerState<TournamentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String?> _statusFilters = [null, 'ongoing', 'upcoming', 'completed'];
  final List<String> _tabLabels = ['All', 'Live', 'Upcoming', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final status = _statusFilters[_tabController.index];
      ref.read(tournamentListProvider.notifier).filterByStatus(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
          isScrollable: false,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(TournamentListState state) {
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
        message: 'No tournaments found for the selected filter.',
        actionLabel: 'Refresh',
        onAction: () => ref.read(tournamentListProvider.notifier).loadTournaments(refresh: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tournamentListProvider.notifier).loadTournaments(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.tournaments.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.tournaments.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final tournament = state.tournaments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TournamentCard(
              tournament: tournament,
              onTap: () => context.push('/tournaments/${tournament.id}'),
            ),
          );
        },
      ),
    );
  }
}
