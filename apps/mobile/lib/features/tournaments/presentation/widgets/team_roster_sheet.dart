import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/loading_indicator.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';

/// Bottom sheet displaying team roster
class TeamRosterSheet extends ConsumerWidget {
  final Team team;
  final String tournamentId;

  const TeamRosterSheet({
    super.key,
    required this.team,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersState = ref.watch(tournamentPlayersProvider(tournamentId));

    // Filter players for this team
    final teamPlayers = playersState.players
        .where((p) => p.team?.id == team.id || p.team?.name == team.name)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Team header
              _buildTeamHeader(context),
              const Divider(),
              // Players list
              Expanded(
                child: playersState.isLoading && teamPlayers.isEmpty
                    ? const LoadingIndicator()
                    : teamPlayers.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: teamPlayers.length,
                            itemBuilder: (context, index) {
                              return _PlayerListItem(
                                player: teamPlayers[index],
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push('/players/${teamPlayers[index].id}');
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Team logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: team.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      team.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildLogoPlaceholder(context),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (team.region != null)
                  Row(
                    children: [
                      Icon(
                        Icons.public,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        team.region!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Seed badge
          if (team.seed != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
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
    );
  }

  Widget _buildLogoPlaceholder(BuildContext context) {
    return Center(
      child: Text(
        team.shortName,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No roster information available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

/// Player list item for roster
class _PlayerListItem extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;

  const _PlayerListItem({
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Player avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getRoleColor(player.role).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: player.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(
                          player.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildAvatarPlaceholder(context),
                        ),
                      )
                    : _buildAvatarPlaceholder(context),
              ),
              const SizedBox(width: 12),
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.nickname,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (player.realName != null)
                      Text(
                        player.realName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                  ],
                ),
              ),
              // Role badge
              if (player.role != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(player.role).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    player.role!.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(player.role),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Country flag
              if (player.country != null)
                Text(
                  _getCountryFlag(player.country!),
                  style: const TextStyle(fontSize: 20),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(BuildContext context) {
    return Center(
      child: Text(
        player.nickname.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _getRoleColor(player.role),
        ),
      ),
    );
  }

  Color _getRoleColor(PlayerRole? role) {
    if (role == null) return Colors.grey;
    switch (role) {
      case PlayerRole.carry:
        return Colors.red.shade700;
      case PlayerRole.mid:
        return Colors.orange.shade700;
      case PlayerRole.offlane:
        return Colors.green.shade700;
      case PlayerRole.support4:
        return Colors.blue.shade700;
      case PlayerRole.support5:
        return Colors.purple.shade700;
    }
  }

  String _getCountryFlag(String countryCode) {
    // Convert country code to flag emoji
    final code = countryCode.toUpperCase();
    if (code.length != 2) return '';
    final firstChar = code.codeUnitAt(0) - 65 + 0x1F1E6;
    final secondChar = code.codeUnitAt(1) - 65 + 0x1F1E6;
    return String.fromCharCodes([firstChar, secondChar]);
  }
}
