import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tournaments/domain/entities/tournament.dart';
import '../../../tournaments/presentation/providers/tournament_provider.dart';
import '../../data/league_repository.dart';
import '../providers/league_provider.dart';

/// Create league screen
class CreateLeagueScreen extends ConsumerStatefulWidget {
  final String? preselectedTournamentId;

  const CreateLeagueScreen({
    super.key,
    this.preselectedTournamentId,
  });

  @override
  ConsumerState<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends ConsumerState<CreateLeagueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedTournamentId;
  int _maxMembers = 10;
  bool _isPublic = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTournamentId = widget.preselectedTournamentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsState = ref.watch(tournamentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create League'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // League name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'League Name',
                hintText: 'Enter a name for your league',
                prefixIcon: Icon(Icons.emoji_events),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a league name';
                }
                if (value.length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Tournament selection
            Text(
              'Select Tournament',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildTournamentSelector(tournamentsState.tournaments),
            const SizedBox(height: 24),

            // Max members
            Text(
              'Maximum Members',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildMaxMembersSelector(),
            const SizedBox(height: 24),

            // Public/Private toggle
            SwitchListTile(
              title: const Text('Public League'),
              subtitle: const Text(
                'Public leagues can be discovered by anyone',
              ),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
            const SizedBox(height: 32),

            // Create button
            FilledButton(
              onPressed: _isLoading ? null : _createLeague,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create League'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentSelector(List<Tournament> tournaments) {
    // Filter to ongoing and upcoming tournaments
    final availableTournaments = tournaments
        .where((t) => t.status == 'ongoing' || t.status == 'upcoming')
        .toList();

    if (availableTournaments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No active tournaments available'),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedTournamentId,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.sports_esports),
        border: OutlineInputBorder(),
      ),
      hint: const Text('Select a tournament'),
      items: availableTournaments.map((tournament) {
        return DropdownMenuItem(
          value: tournament.id,
          child: Text(tournament.name),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedTournamentId = value),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a tournament';
        }
        return null;
      },
    );
  }

  Widget _buildMaxMembersSelector() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 4, label: Text('4')),
        ButtonSegment(value: 6, label: Text('6')),
        ButtonSegment(value: 8, label: Text('8')),
        ButtonSegment(value: 10, label: Text('10')),
        ButtonSegment(value: 12, label: Text('12')),
      ],
      selected: {_maxMembers},
      onSelectionChanged: (selected) {
        setState(() => _maxMembers = selected.first);
      },
    );
  }

  Future<void> _createLeague() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = CreateLeagueRequest(
        name: _nameController.text.trim(),
        tournamentId: _selectedTournamentId!,
        maxMembers: _maxMembers,
        isPublic: _isPublic,
      );

      final league =
          await ref.read(myLeaguesProvider.notifier).createLeague(request);

      if (league != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('League "${league.name}" created!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create league: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
