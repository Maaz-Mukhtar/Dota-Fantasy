import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/player.dart';
import '../providers/player_provider.dart';

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;

  const PlayerDetailScreen({
    super.key,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerDetailProvider(playerId));

    return Scaffold(
      body: state.isLoading && state.player == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.player == null
              ? _buildErrorState(context, ref, state.error!)
              : state.player != null
                  ? _buildContent(context, ref, state)
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
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
            'Failed to load player',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(playerDetailProvider(playerId).notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, PlayerDetailState state) {
    final player = state.player!;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(playerDetailProvider(playerId).notifier).refresh();
      },
      child: CustomScrollView(
        slivers: [
          // App bar with player header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: _buildPlayerHeader(context, player),
                ),
              ),
            ),
          ),

          // Stats overview
          SliverToBoxAdapter(
            child: _buildStatsOverview(context, player, state.stats?.averages),
          ),

          // Fantasy points section
          SliverToBoxAdapter(
            child: _buildFantasySection(context, player),
          ),

          // Recent games
          if (state.stats?.recentGames.isNotEmpty ?? false) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Recent Games',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final game = state.stats!.recentGames[index];
                  return _buildGameCard(context, game);
                },
                childCount: state.stats!.recentGames.length,
              ),
            ),
          ],

          // Loading indicator for stats
          if (state.isLoadingStats)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader(BuildContext context, Player player) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: player.avatarUrl != null
                ? CachedNetworkImageProvider(player.avatarUrl!)
                : null,
            child: player.avatarUrl == null
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            player.nickname,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (player.realName != null) ...[
            const SizedBox(height: 4),
            Text(
              player.realName!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Team and role
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (player.team != null) ...[
                if (player.team!.logoUrl != null) ...[
                  CachedNetworkImage(
                    imageUrl: player.team!.logoUrl!,
                    width: 20,
                    height: 20,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  player.team!.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
              if (player.role != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    player.role!.displayName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, Player player, PlayerAverages? averages) {
    final theme = Theme.of(context);
    final stats = averages;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Career Stats',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                context,
                'Matches',
                stats?.totalGames.toString() ?? player.totalMatches.toString(),
              ),
              _buildStatItem(
                context,
                'Win Rate',
                '${(stats?.winRate ?? player.winRate).toStringAsFixed(1)}%',
              ),
              _buildStatItem(
                context,
                'KDA',
                player.kdaString,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                context,
                'Avg GPM',
                (stats?.avgGpm ?? player.avgGpm).toStringAsFixed(0),
              ),
              _buildStatItem(
                context,
                'Avg XPM',
                (stats?.avgXpm ?? player.avgXpm).toStringAsFixed(0),
              ),
              _buildStatItem(
                context,
                'Avg LH',
                (stats?.avgLastHits ?? player.avgLastHits).toStringAsFixed(0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFantasySection(BuildContext context, Player player) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: theme.colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Fantasy Points',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  player.avgFantasyPoints.toStringAsFixed(2),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (player.fantasyValue != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Value',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  '\$${player.fantasyValue!.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, PlayerGameStats game) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Result indicator
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: game.isWinner ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // KDA
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.kdaString,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    game.isWinner ? 'Victory' : 'Defeat',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: game.isWinner ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            // GPM/XPM
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    '${game.gpm} GPM',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${game.xpm} XPM',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Fantasy points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  game.fantasyPoints.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'FP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
