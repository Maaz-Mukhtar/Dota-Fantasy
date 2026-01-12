import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/entities/tournament.dart';
import '../providers/tournament_provider.dart';

/// Tournament detail screen
class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Details'),
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
          // Header
          _buildHeader(context, tournament),
          const SizedBox(height: 24),

          // Info cards
          _buildInfoSection(context, tournament),
          const SizedBox(height: 24),

          // Format
          if (tournament.format != null) ...[
            _buildSectionTitle(context, 'Format'),
            const SizedBox(height: 8),
            Text(
              tournament.format!,
              style: Theme.of(context).textTheme.bodyLarge,
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

  Widget _buildHeader(BuildContext context, Tournament tournament) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status badge
        _buildStatusBadge(context, tournament),
        const SizedBox(height: 12),

        // Tournament name
        Text(
          tournament.name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        // Tier badge
        _buildTierBadge(context, tournament),
      ],
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
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        tournament.tierDisplayName,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Tournament tournament) {
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
          Column(
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
              ),
            ],
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
