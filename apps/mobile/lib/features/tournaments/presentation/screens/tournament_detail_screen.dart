import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/entities/tournament.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/tournament_provider.dart';
import '../widgets/teams_grid.dart';
import '../widgets/group_standings.dart';
import '../widgets/playoff_bracket.dart';
import '../widgets/team_roster_sheet.dart';

/// Tournament detail screen with redesigned layout
/// Main view: Teams Grid
/// Tabs: Group Stage (standings) and Playoffs (bracket)
/// Overflow menu: Tournament Info, Players, Schedule
class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return Scaffold(
      body: tournamentAsync.when(
        loading: () => const Scaffold(
          appBar: null,
          body: LoadingIndicator(),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Tournament Details')),
          body: app.AppErrorWidget(
            message: error.toString(),
            onRetry: () =>
                ref.invalidate(tournamentProvider(widget.tournamentId)),
          ),
        ),
        data: (tournament) => _buildContent(context, tournament),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Tournament tournament) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'info',
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Tournament Info'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'players',
                    child: ListTile(
                      leading: Icon(Icons.people),
                      title: Text('Players'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'schedule',
                    child: ListTile(
                      leading: Icon(Icons.schedule),
                      title: Text('Schedule'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                tournament.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: _buildHeaderBackground(context, tournament),
            ),
          ),
          // Teams Grid Section
          SliverToBoxAdapter(
            child: _TeamsGridSection(
              tournamentId: widget.tournamentId,
              onTeamTap: (team) => _showTeamRoster(context, team),
            ),
          ),
          // Tab Bar
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Group Stage'),
                  Tab(text: 'Playoffs'),
                ],
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          GroupStandingsTab(tournamentId: widget.tournamentId),
          PlayoffBracketTab(tournamentId: widget.tournamentId),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(BuildContext context, Tournament tournament) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  _buildStatusBadge(context, tournament),
                  const SizedBox(width: 8),
                  _buildTierBadge(context, tournament),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tournament.formattedPrizePool,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Tournament tournament) {
    Color statusColor;
    String statusText;

    switch (tournament.status) {
      case 'ongoing':
        statusColor = AppTheme.statusLive;
        statusText = 'LIVE';
        break;
      case 'upcoming':
        statusColor = AppTheme.statusUpcoming;
        statusText = 'UPCOMING';
        break;
      case 'completed':
        statusColor = AppTheme.statusCompleted;
        statusText = 'COMPLETED';
        break;
      default:
        statusColor = Colors.grey;
        statusText = tournament.status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTierBadge(BuildContext context, Tournament tournament) {
    Color badgeColor;
    switch (tournament.tier.toLowerCase()) {
      case 'ti':
        badgeColor = AppTheme.tierTI;
        break;
      case 'major':
        badgeColor = AppTheme.tierGold;
        break;
      case 'tier1':
        badgeColor = AppTheme.tierSilver;
        break;
      case 'tier2':
        badgeColor = AppTheme.tierBronze;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        tournament.tierDisplayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'info':
        context.push('/tournaments/${widget.tournamentId}/info');
        break;
      case 'players':
        context.push('/tournaments/${widget.tournamentId}/players');
        break;
      case 'schedule':
        context.push('/tournaments/${widget.tournamentId}/schedule');
        break;
    }
  }

  void _showTeamRoster(BuildContext context, Team team) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TeamRosterSheet(
        team: team,
        tournamentId: widget.tournamentId,
      ),
    );
  }
}

/// Sliver delegate for TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

/// Teams Grid Section widget
class _TeamsGridSection extends ConsumerWidget {
  final String tournamentId;
  final void Function(Team team) onTeamTap;

  const _TeamsGridSection({
    required this.tournamentId,
    required this.onTeamTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(tournamentTeamsProvider(tournamentId));

    return teamsAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Failed to load teams',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
      data: (teams) {
        if (teams.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'No teams announced yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }
        return TeamsGrid(
          teams: teams,
          onTeamTap: onTeamTap,
        );
      },
    );
  }
}
