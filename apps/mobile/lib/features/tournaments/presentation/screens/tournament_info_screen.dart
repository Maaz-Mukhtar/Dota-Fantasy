import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart' as app;
import '../../domain/entities/tournament.dart';
import '../providers/tournament_provider.dart';

/// Tournament info screen showing detailed tournament information
class TournamentInfoScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentInfoScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Info'),
      ),
      body: tournamentAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, stack) => app.AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(tournamentProvider(tournamentId)),
        ),
        data: (tournament) => _buildContent(context, tournament),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Tournament tournament) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament header card
          _buildHeaderCard(context, tournament),
          const SizedBox(height: 24),

          // Details section
          _buildSectionTitle(context, 'Details'),
          const SizedBox(height: 12),
          _buildInfoCard(context, tournament),
          const SizedBox(height: 24),

          // Format section
          if (tournament.format != null) ...[
            _buildSectionTitle(context, 'Format'),
            const SizedBox(height: 12),
            _buildFormatCard(context, tournament.format!),
            const SizedBox(height: 24),
          ],

          // Actions
          if (tournament.liquipediaUrl != null)
            _buildLiquipediaButton(context, tournament.liquipediaUrl!),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Tournament tournament) {
    Color tierColor;
    switch (tournament.tier.toLowerCase()) {
      case 'ti':
        tierColor = AppTheme.tierTI;
        break;
      case 'major':
        tierColor = AppTheme.tierGold;
        break;
      case 'tier1':
        tierColor = AppTheme.tierSilver;
        break;
      case 'tier2':
        tierColor = AppTheme.tierBronze;
        break;
      default:
        tierColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor.withOpacity(0.2),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tierColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusBadge(context, tournament),
              _buildTierBadge(context, tournament, tierColor),
            ],
          ),
          const SizedBox(height: 16),
          // Tournament name
          Text(
            tournament.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          // Prize pool
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: 20,
                color: Colors.amber[700],
              ),
              const SizedBox(width: 8),
              Text(
                tournament.formattedPrizePool,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(6),
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

  Widget _buildTierBadge(
      BuildContext context, Tournament tournament, Color tierColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tierColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tierColor, width: 1),
      ),
      child: Text(
        tournament.tierDisplayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: tierColor,
        ),
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

  Widget _buildInfoCard(BuildContext context, Tournament tournament) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Dates',
              _formatDateRange(tournament),
            ),
            const Divider(),
            if (tournament.region != null) ...[
              _buildInfoRow(
                context,
                Icons.public,
                'Region',
                tournament.region!,
              ),
              const Divider(),
            ],
            _buildInfoRow(
              context,
              Icons.category,
              'Tier',
              tournament.tierDisplayName,
            ),
            const Divider(),
            _buildInfoRow(
              context,
              Icons.emoji_events,
              'Prize Pool',
              tournament.formattedPrizePool,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard(BuildContext context, String format) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_tree,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tournament Format',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              format,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
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
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
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
