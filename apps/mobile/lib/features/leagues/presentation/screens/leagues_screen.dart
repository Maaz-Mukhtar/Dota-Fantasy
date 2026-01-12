import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/league_provider.dart';
import '../widgets/league_card.dart';
import 'create_league_screen.dart';
import 'join_league_screen.dart';

/// Leagues screen - shows user's leagues
class LeaguesScreen extends ConsumerWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaguesState = ref.watch(myLeaguesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leagues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(myLeaguesProvider.notifier).loadLeagues(refresh: true),
          ),
        ],
      ),
      body: _buildBody(context, ref, leaguesState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOrJoinDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New League'),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, MyLeaguesState state) {
    if (state.isLoading && state.leagues.isEmpty) {
      return const LoadingIndicator();
    }

    if (state.error != null && state.leagues.isEmpty) {
      return app.AppErrorWidget(
        message: state.error!,
        onRetry: () =>
            ref.read(myLeaguesProvider.notifier).loadLeagues(refresh: true),
      );
    }

    if (state.leagues.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(myLeaguesProvider.notifier).loadLeagues(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.leagues.length,
        itemBuilder: (context, index) {
          final league = state.leagues[index];
          return LeagueCard(
            league: league,
            onTap: () => context.push('/leagues/${league.id}'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Leagues Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new league or join an existing one to start competing!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showJoinDialog(context),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Join League'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create League'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOrJoinDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.add),
                ),
                title: const Text('Create New League'),
                subtitle: const Text('Start your own fantasy league'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateDialog(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.group_add),
                ),
                title: const Text('Join Existing League'),
                subtitle: const Text('Enter an invite code to join'),
                onTap: () {
                  Navigator.pop(context);
                  _showJoinDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateLeagueScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const JoinLeagueScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}
