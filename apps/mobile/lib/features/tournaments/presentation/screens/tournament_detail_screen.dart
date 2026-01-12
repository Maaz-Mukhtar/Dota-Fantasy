import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/entities/tournament.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../matches/domain/entities/match.dart';
import '../providers/tournament_provider.dart';

/// Tournament detail screen with tabbed interface
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
    _tabController = TabController(length: 3, vsync: this);
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
            expandedHeight: 200,
            floating: false,
            pinned: true,
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
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Teams'),
                  Tab(text: 'Schedule'),
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
          _OverviewTab(tournament: tournament),
          _TeamsTab(tournamentId: widget.tournamentId),
          _ScheduleTab(tournamentId: widget.tournamentId),
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
              _buildStatusBadge(context, tournament),
              const SizedBox(height: 8),
              _buildTierBadge(context, tournament),
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
        statusText = 'LIVE NOW';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        tournament.tierDisplayName,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
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

/// Overview tab content
class _OverviewTab extends StatelessWidget {
  final Tournament tournament;

  const _OverviewTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info cards
          _buildInfoSection(context),
          const SizedBox(height: 24),

          // Format
          if (tournament.format != null) ...[
            _buildSectionTitle(context, 'Format'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tournament.format!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Actions
          if (tournament.liquipediaUrl != null)
            _buildLiquipediaButton(context, tournament.liquipediaUrl!),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      children: [
        _buildInfoRow(
          context,
          Icons.calendar_today,
          'Dates',
          _formatDateRange(tournament),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          Icons.emoji_events,
          'Prize Pool',
          tournament.formattedPrizePool,
        ),
        if (tournament.region != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.public,
            'Region',
            tournament.region!,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildLiquipediaButton(BuildContext context, String url) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _launchUrl(url),
        icon: const Icon(Icons.open_in_new),
        label: const Text('View on Liquipedia'),
      ),
    );
  }

  String _formatDateRange(Tournament tournament) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final startStr = dateFormat.format(tournament.startDate);

    if (tournament.endDate != null) {
      final endStr = dateFormat.format(tournament.endDate!);
      return '$startStr - $endStr';
    }

    return startStr;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Teams tab content
class _TeamsTab extends ConsumerWidget {
  final String tournamentId;

  const _TeamsTab({required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(tournamentTeamsProvider(tournamentId));

    return teamsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, stack) => app.AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(tournamentTeamsProvider(tournamentId)),
      ),
      data: (teams) {
        if (teams.isEmpty) {
          return const Center(
            child: Text('No teams announced yet'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          itemBuilder: (context, index) => _TeamCard(team: teams[index]),
        );
      },
    );
  }
}

/// Team card widget
class _TeamCard extends StatelessWidget {
  final Team team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Team logo placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: team.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        team.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildLogoPlaceholder(context),
                      ),
                    )
                  : _buildLogoPlaceholder(context),
            ),
            const SizedBox(width: 16),
            // Team info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (team.tag != null)
                    Text(
                      team.tag!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  if (team.region != null)
                    Text(
                      team.region!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                ],
              ),
            ),
            // Seed badge
            if (team.seed != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Seed #${team.seed}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(BuildContext context) {
    return Center(
      child: Text(
        team.shortName,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Schedule tab content
class _ScheduleTab extends ConsumerWidget {
  final String tournamentId;

  const _ScheduleTab({required this.tournamentId});

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
        if (matches.isEmpty) {
          return const Center(
            child: Text('No matches scheduled yet'),
          );
        }

        // Group matches by status
        final liveMatches = matches.where((m) => m.isLive).toList();
        final upcomingMatches = matches.where((m) => m.isUpcoming).toList();
        final completedMatches = matches.where((m) => m.isCompleted).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (liveMatches.isNotEmpty) ...[
              _buildSectionHeader(context, 'Live Now', AppTheme.statusLive),
              ...liveMatches.map((m) => _MatchCard(match: m)),
              const SizedBox(height: 16),
            ],
            if (upcomingMatches.isNotEmpty) ...[
              _buildSectionHeader(context, 'Upcoming', AppTheme.statusUpcoming),
              ...upcomingMatches.map((m) => _MatchCard(match: m)),
              const SizedBox(height: 16),
            ],
            if (completedMatches.isNotEmpty) ...[
              _buildSectionHeader(context, 'Completed', AppTheme.statusCompleted),
              ...completedMatches.map((m) => _MatchCard(match: m)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (match.stage != null)
                      Text(
                        match.stage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    Text(
                      match.bestOfDisplay,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
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
                  child: Column(
                    children: [
                      _buildTeamLogo(context, match.team1),
                      const SizedBox(height: 4),
                      Text(
                        match.team1?.shortName ?? 'TBD',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Score or vs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: match.isCompleted || match.isLive
                      ? Column(
                          children: [
                            Text(
                              match.scoreDisplay,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (match.isLive)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
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
                        )
                      : Column(
                          children: [
                            Text(
                              'VS',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                            ),
                            if (match.scheduledAt != null)
                              Text(
                                _formatTime(match.scheduledAt!),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                          ],
                        ),
                ),
                // Team 2
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamLogo(context, match.team2),
                      const SizedBox(height: 4),
                      Text(
                        match.team2?.shortName ?? 'TBD',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Schedule date for upcoming
            if (match.isUpcoming && match.scheduledAt != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatDate(match.scheduledAt!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(BuildContext context, Team? team) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          team?.shortName ?? '?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • HH:mm').format(dateTime);
  }
}
