import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart' as app;
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/widgets/player_card.dart';
import '../../../players/presentation/providers/player_provider.dart';

/// Tournament players screen with filtering capabilities
class TournamentPlayersScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentPlayersScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentPlayersScreen> createState() =>
      _TournamentPlayersScreenState();
}

class _TournamentPlayersScreenState
    extends ConsumerState<TournamentPlayersScreen> {
  String _searchQuery = '';
  PlayerRole? _selectedRole;
  String? _selectedCountry;
  String? _selectedTeam;

  @override
  Widget build(BuildContext context) {
    final playersState = ref.watch(tournamentPlayersProvider(widget.tournamentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, playersState.players),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search players...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Active filters chips
          if (_hasActiveFilters())
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_selectedRole != null)
                    _buildFilterChip(
                      label: _selectedRole!.displayName,
                      onDelete: () => setState(() => _selectedRole = null),
                    ),
                  if (_selectedCountry != null)
                    _buildFilterChip(
                      label: _selectedCountry!,
                      onDelete: () => setState(() => _selectedCountry = null),
                    ),
                  if (_selectedTeam != null)
                    _buildFilterChip(
                      label: _selectedTeam!,
                      onDelete: () => setState(() => _selectedTeam = null),
                    ),
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
          // Players list
          Expanded(
            child: _buildPlayersList(playersState),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(TournamentPlayersState playersState) {
    if (playersState.isLoading && playersState.players.isEmpty) {
      return const LoadingIndicator();
    }

    if (playersState.error != null && playersState.players.isEmpty) {
      return app.AppErrorWidget(
        message: playersState.error!,
        onRetry: () => ref
            .read(tournamentPlayersProvider(widget.tournamentId).notifier)
            .loadPlayers(refresh: true),
      );
    }

    final filteredPlayers = _filterPlayers(playersState.players);

    if (filteredPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No players found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (_hasActiveFilters()) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _clearAllFilters,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(tournamentPlayersProvider(widget.tournamentId).notifier)
            .loadPlayers(refresh: true);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPlayers.length,
        itemBuilder: (context, index) {
          final player = filteredPlayers[index];
          return PlayerCard(
            player: player,
            compact: false,
            showTeam: true,
            showFantasyPoints: false,
            onTap: () => context.push('/players/${player.id}'),
          );
        },
      ),
    );
  }

  List<Player> _filterPlayers(List<Player> players) {
    return players.where((player) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesNickname =
            player.nickname.toLowerCase().contains(query);
        final matchesName =
            player.realName?.toLowerCase().contains(query) ?? false;
        final matchesTeam = player.team?.name.toLowerCase().contains(query) ?? false;
        if (!matchesNickname && !matchesName && !matchesTeam) {
          return false;
        }
      }

      // Role filter
      if (_selectedRole != null && player.role != _selectedRole) {
        return false;
      }

      // Country filter
      if (_selectedCountry != null && player.country != _selectedCountry) {
        return false;
      }

      // Team filter
      if (_selectedTeam != null && player.team?.name != _selectedTeam) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _hasActiveFilters() {
    return _selectedRole != null ||
        _selectedCountry != null ||
        _selectedTeam != null;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedRole = null;
      _selectedCountry = null;
      _selectedTeam = null;
    });
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onDeleted: onDelete,
        deleteIcon: const Icon(Icons.close, size: 16),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _showFilterSheet(BuildContext context, List<Player> allPlayers) {
    // Extract unique values for filters
    final countries = allPlayers
        .where((p) => p.country != null)
        .map((p) => p.country!)
        .toSet()
        .toList()
      ..sort();

    final teams = allPlayers
        .where((p) => p.team != null)
        .map((p) => p.team!.name)
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        selectedRole: _selectedRole,
        selectedCountry: _selectedCountry,
        selectedTeam: _selectedTeam,
        countries: countries,
        teams: teams,
        onApply: (role, country, team) {
          setState(() {
            _selectedRole = role;
            _selectedCountry = country;
            _selectedTeam = team;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Filter bottom sheet
class _FilterSheet extends StatefulWidget {
  final PlayerRole? selectedRole;
  final String? selectedCountry;
  final String? selectedTeam;
  final List<String> countries;
  final List<String> teams;
  final void Function(PlayerRole?, String?, String?) onApply;

  const _FilterSheet({
    required this.selectedRole,
    required this.selectedCountry,
    required this.selectedTeam,
    required this.countries,
    required this.teams,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late PlayerRole? _role;
  late String? _country;
  late String? _team;

  @override
  void initState() {
    super.initState();
    _role = widget.selectedRole;
    _country = widget.selectedCountry;
    _team = widget.selectedTeam;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Players',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _role = null;
                          _country = null;
                          _team = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Filter options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Role filter
                    _buildSectionTitle(context, 'Role'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterOption(
                          label: 'All Roles',
                          isSelected: _role == null,
                          onTap: () => setState(() => _role = null),
                        ),
                        ...PlayerRole.values.map((role) => _buildFilterOption(
                              label: role.displayName,
                              isSelected: _role == role,
                              onTap: () => setState(() => _role = role),
                              color: _getRoleColor(role),
                            )),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Country filter
                    _buildSectionTitle(context, 'Country'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterOption(
                          label: 'All Countries',
                          isSelected: _country == null,
                          onTap: () => setState(() => _country = null),
                        ),
                        ...widget.countries.map((country) => _buildFilterOption(
                              label: '${_getCountryFlag(country)} $country',
                              isSelected: _country == country,
                              onTap: () => setState(() => _country = country),
                            )),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Team filter
                    _buildSectionTitle(context, 'Team'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterOption(
                          label: 'All Teams',
                          isSelected: _team == null,
                          onTap: () => setState(() => _team = null),
                        ),
                        ...widget.teams.map((team) => _buildFilterOption(
                              label: team,
                              isSelected: _team == team,
                              onTap: () => setState(() => _team = team),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              // Apply button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => widget.onApply(_role, _country, _team),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildFilterOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isSelected ? Colors.white : (color ?? null),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: color ?? Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
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

  String _getCountryFlag(String countryCode) {
    final code = countryCode.toUpperCase();
    if (code.length != 2) return '';
    final firstChar = code.codeUnitAt(0) - 65 + 0x1F1E6;
    final secondChar = code.codeUnitAt(1) - 65 + 0x1F1E6;
    return String.fromCharCodes([firstChar, secondChar]);
  }
}
