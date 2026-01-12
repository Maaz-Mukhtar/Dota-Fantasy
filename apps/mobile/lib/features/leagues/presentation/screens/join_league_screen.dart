import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/league_repository.dart';
import '../../domain/entities/league.dart';
import '../providers/league_provider.dart';

/// Join league screen
class JoinLeagueScreen extends ConsumerStatefulWidget {
  const JoinLeagueScreen({super.key});

  @override
  ConsumerState<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends ConsumerState<JoinLeagueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _teamNameController = TextEditingController(text: 'My Team');

  bool _isSearching = false;
  bool _isJoining = false;
  League? _foundLeague;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _teamNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join League'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Invite code input
            Text(
              'Enter Invite Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'e.g., ABC12345',
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchLeague,
                      ),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                UpperCaseTextFormatter(),
              ],
              maxLength: 8,
              onChanged: (_) {
                if (_foundLeague != null) {
                  setState(() {
                    _foundLeague = null;
                    _error = null;
                  });
                }
              },
              onFieldSubmitted: (_) => _searchLeague(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an invite code';
                }
                if (value.length < 6) {
                  return 'Code must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Found league preview
            if (_foundLeague != null) ...[
              const SizedBox(height: 24),
              _buildLeaguePreview(_foundLeague!),
              const SizedBox(height: 24),

              // Team name input
              Text(
                'Your Team Name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _teamNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your team name',
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a team name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Join button
              FilledButton(
                onPressed: _isJoining || !_foundLeague!.canJoin
                    ? null
                    : _joinLeague,
                child: _isJoining
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_foundLeague!.canJoin
                        ? 'Join League'
                        : _foundLeague!.isFull
                            ? 'League is Full'
                            : 'Draft Already Started'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguePreview(League league) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'League Found!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            league.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (league.tournament != null) ...[
            const SizedBox(height: 4),
            Text(
              league.tournament!.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.people,
                league.memberCountDisplay,
              ),
              const SizedBox(width: 16),
              _buildInfoChip(
                Icons.schedule,
                league.draftStatusDisplay,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _searchLeague() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length < 6) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _foundLeague = null;
    });

    try {
      final repository = ref.read(leagueRepositoryProvider);
      final league = await repository.findByInviteCode(code);
      setState(() => _foundLeague = league);
    } catch (e) {
      setState(() => _error = 'No league found with this invite code');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _joinLeague() async {
    if (_foundLeague == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isJoining = true);

    try {
      final request = JoinLeagueRequest(
        inviteCode: _codeController.text.trim(),
        teamName: _teamNameController.text.trim(),
      );

      final league =
          await ref.read(myLeaguesProvider.notifier).joinLeague(request);

      if (league != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined "${league.name}"!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join league: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
