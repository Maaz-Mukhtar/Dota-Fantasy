import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/player.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;
  final bool showTeam;
  final bool showFantasyPoints;
  final bool compact;

  const PlayerCard({
    super.key,
    required this.player,
    this.onTap,
    this.showTeam = true,
    this.showFantasyPoints = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildFullCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Player avatar
              _buildAvatar(48),
              const SizedBox(width: 12),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.nickname,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.role != null) _buildRoleBadge(context),
                      ],
                    ),
                    if (player.realName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        player.realName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (showTeam && player.team != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (player.team!.logoUrl != null) ...[
                            CachedNetworkImage(
                              imageUrl: player.team!.logoUrl!,
                              width: 16,
                              height: 16,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.shield, size: 16),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            player.team!.name,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Stats column
              if (showFantasyPoints) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      player.avgFantasyPoints.toStringAsFixed(1),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'AVG FP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player.kdaString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],

              // Chevron
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _buildAvatar(36),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.nickname,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (player.team != null)
                      Text(
                        player.team!.tag ?? player.team!.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              if (player.role != null) _buildRoleBadge(context, small: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(double size) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: player.avatarUrl != null
          ? CachedNetworkImageProvider(player.avatarUrl!)
          : null,
      child: player.avatarUrl == null
          ? Icon(
              Icons.person,
              size: size * 0.5,
              color: Colors.grey.shade400,
            )
          : null,
    );
  }

  Widget _buildRoleBadge(BuildContext context, {bool small = false}) {
    final theme = Theme.of(context);
    final color = _getRoleColor(player.role!);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        small ? player.role!.shortName : player.role!.displayName,
        style: (small ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
            ?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRoleColor(PlayerRole role) {
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
}

/// Role filter chip widget
class RoleFilterChip extends StatelessWidget {
  final PlayerRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleFilterChip({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(role);

    return FilterChip(
      label: Text(role.displayName),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Color _getRoleColor(PlayerRole role) {
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
}
