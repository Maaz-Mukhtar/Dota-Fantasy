import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/entities/league.dart';
import '../providers/league_provider.dart';

/// League detail screen
class LeagueDetailScreen extends ConsumerWidget {
  final String leagueId;

  const LeagueDetailScreen({
    super.key,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueAsync = ref.watch(leagueProvider(leagueId));

    return leagueAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('League')),
        body: const LoadingIndicator(),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('League')),
        body: app.AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.refresh(leagueProvider(leagueId)),
        ),
      ),
      data: (league) => _LeagueDetailContent(league: league),
    );
  }
}

class _LeagueDetailContent extends ConsumerStatefulWidget {
  final League league;

  const _LeagueDetailContent({required this.league});

  @override
  ConsumerState<_LeagueDetailContent> createState() =>
      _LeagueDetailContentState();
}

class _LeagueDetailContentState extends ConsumerState<_LeagueDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final league = widget.league;

    return Scaffold(
      appBar: AppBar(
        title: Text(league.name),
        actions: [
          if (league.isOwner)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, league),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'invite',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share Invite'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('League Settings'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete League',
                        style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareInviteCode(league),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Leaderboard'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(league: league),
          _LeaderboardTab(leagueId: league.id),
          _MembersTab(league: league),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, League league) {
    switch (action) {
      case 'invite':
        _shareInviteCode(league);
        break;
      case 'settings':
        _showLeagueSettings(league);
        break;
      case 'delete':
        _confirmDeleteLeague(league);
        break;
    }
  }

  void _shareInviteCode(League league) {
    Share.share(
      'Join my Dota Fantasy league "${league.name}"!\n\nInvite code: ${league.inviteCode}',
      subject: 'Join ${league.name}',
    );
  }

  void _showLeagueSettings(League league) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('League settings coming soon')),
    );
  }

  Future<void> _confirmDeleteLeague(League league) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete League'),
        content: Text(
          'Are you sure you want to delete "${league.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await ref.read(myLeaguesProvider.notifier).deleteLeague(league.id);
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('League deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

/// Overview tab
class _OverviewTab extends StatelessWidget {
  final League league;

  const _OverviewTab({required this.league});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // League info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            league.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (league.tournament != null)
                            Text(
                              league.tournament!.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Stats cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people,
                label: 'Members',
                value: league.memberCountDisplay,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.schedule,
                label: 'Draft Status',
                value: league.draftStatusDisplay,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Invite code card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite Code',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        league.inviteCode,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: league.inviteCode),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invite code copied!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // My membership card
        if (league.myMembership != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Team',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          league.myMembership!.teamName[0].toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              league.myMembership!.teamName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              league.myMembership!.role == MemberRole.owner
                                  ? 'Owner'
                                  : 'Member',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${league.myMembership!.totalPoints.toStringAsFixed(1)} pts',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          if (league.myMembership!.rank != null)
                            Text(
                              'Rank #${league.myMembership!.rank}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Leaderboard tab
class _LeaderboardTab extends ConsumerWidget {
  final String leagueId;

  const _LeaderboardTab({required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leagueLeaderboardProvider(leagueId));

    return leaderboardAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, stack) => app.AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.refresh(leagueLeaderboardProvider(leagueId)),
      ),
      data: (members) {
        if (members.isEmpty) {
          return const Center(
            child: Text('No members yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return _LeaderboardItem(
              rank: index + 1,
              member: member,
            );
          },
        );
      },
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final int rank;
  final LeagueMember member;

  const _LeaderboardItem({
    required this.rank,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    Color? rankColor;
    if (rank == 1) rankColor = Colors.amber;
    if (rank == 2) rankColor = Colors.grey;
    if (rank == 3) rankColor = Colors.brown;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rankColor?.withOpacity(0.2) ??
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rankColor ?? Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.teamName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    member.userName ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '${member.totalPoints.toStringAsFixed(1)} pts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Members tab
class _MembersTab extends ConsumerWidget {
  final League league;

  const _MembersTab({required this.league});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leagueLeaderboardProvider(league.id));

    return leaderboardAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, stack) => app.AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.refresh(leagueLeaderboardProvider(league.id)),
      ),
      data: (members) {
        if (members.isEmpty) {
          return const Center(
            child: Text('No members yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return _MemberItem(member: member);
          },
        );
      },
    );
  }
}

class _MemberItem extends StatelessWidget {
  final LeagueMember member;

  const _MemberItem({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(member.teamName[0].toUpperCase()),
        ),
        title: Text(
          member.teamName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(member.userName ?? 'Unknown'),
        trailing: member.role == MemberRole.owner
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'OWNER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
