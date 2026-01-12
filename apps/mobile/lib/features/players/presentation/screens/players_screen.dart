import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/player.dart';
import '../providers/player_provider.dart';
import '../widgets/player_card.dart';

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(playersListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search players...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(playersListProvider.notifier).setSearchQuery(null);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (value) {
                ref.read(playersListProvider.notifier).setSearchQuery(
                      value.isEmpty ? null : value,
                    );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Role filter chips
          _buildRoleFilters(state),

          // Player list
          Expanded(
            child: _buildPlayerList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilters(PlayersListState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: state.roleFilter == null,
            onSelected: (_) {
              ref.read(playersListProvider.notifier).setRoleFilter(null);
            },
          ),
          const SizedBox(width: 8),
          ...PlayerRole.values.map((role) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: RoleFilterChip(
                role: role,
                isSelected: state.roleFilter == role.name,
                onTap: () {
                  ref.read(playersListProvider.notifier).setRoleFilter(
                        state.roleFilter == role.name ? null : role.name,
                      );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlayerList(PlayersListState state) {
    if (state.isLoading && state.players.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load players',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(playersListProvider.notifier).loadPlayers(refresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No players found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (state.roleFilter != null || state.searchQuery != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(playersListProvider.notifier).clearFilters();
                },
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(playersListProvider.notifier).loadPlayers(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: state.players.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.players.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final player = state.players[index];
          return PlayerCard(
            player: player,
            onTap: () => context.push('/players/${player.id}'),
          );
        },
      ),
    );
  }
}
