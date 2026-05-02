import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/swimmer_profile.dart';
import '../../domain/services/profile_details_service.dart';
import '../providers/profile_providers.dart';
import '../providers/profile_summary_providers.dart';
import '../widgets/profile_image_provider.dart';

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  Future<void> _showProfileDialog(
    BuildContext context,
    WidgetRef ref, {
    SwimmerProfile? profile,
  }) async {
    final result = await showDialog<_ProfileFormResult>(
      context: context,
      builder: (_) => _ProfileFormDialog(profile: profile),
    );
    if (result == null) return;

    if (profile == null) {
      final created =
          await ref.read(profilesProvider.notifier).addProfileDetails(
                displayName: result.displayName,
                preferredPoolLengthMeters: result.preferredPoolLengthMeters,
                photoUri: result.photoUri,
                preferredStrokes: result.preferredStrokes,
                primaryEvents: result.primaryEvents,
                clubName: result.clubName,
                goals: result.goals,
                notes: result.notes,
              );
      ref.read(selectedProfileIdProvider.notifier).state = created.id;
      return;
    }

    await ref.read(profilesProvider.notifier).updateProfile(
          profile.copyWith(
            displayName: result.displayName,
            preferredPoolLengthMeters: result.preferredPoolLengthMeters,
            photoUri: result.photoUri,
            preferredStrokes: result.preferredStrokes,
            primaryEvents: result.primaryEvents,
            clubName: result.clubName,
            goals: result.goals,
            clearPhotoUri: result.photoUri == null,
            clearPrimaryEvents: result.primaryEvents == null,
            clearClubName: result.clubName == null,
            clearGoals: result.goals == null,
            notes: result.notes,
            clearNotes: result.notes == null,
          ),
        );
  }

  Future<void> _archiveProfile(
    BuildContext context,
    WidgetRef ref,
    SwimmerProfile profile,
  ) async {
    final profiles = ref.read(profilesProvider).valueOrNull ?? const [];
    if (profile.id == kDefaultProfileId || profiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('At least one swimmer profile is required.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive swimmer?'),
        content: Text(
          'Archive ${profile.displayName}? Their data remains stored but the profile is hidden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final wasSelected = ref.read(currentProfileIdProvider) == profile.id;
    await ref.read(profilesProvider.notifier).archiveProfile(profile.id);

    if (wasSelected) {
      final remaining = ref.read(profilesProvider).valueOrNull ?? const [];
      ref.read(selectedProfileIdProvider.notifier).state =
          remaining.isEmpty ? kDefaultProfileId : remaining.first.id;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Swimmer archived.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final currentProfileId = ref.watch(currentProfileIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Swimmer Profiles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProfileDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Swimmer'),
      ),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('No swimmer profiles found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final isCurrent = profile.id == currentProfileId;
              return _ProfileTile(
                profile: profile,
                isCurrent: isCurrent,
                onSelect: () {
                  ref.read(selectedProfileIdProvider.notifier).state =
                      profile.id;
                },
                onEdit: () => _showProfileDialog(
                  context,
                  ref,
                  profile: profile,
                ),
                onArchive: () => _archiveProfile(context, ref, profile),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.isCurrent,
    required this.onSelect,
    required this.onEdit,
    required this.onArchive,
  });

  final SwimmerProfile profile;
  final bool isCurrent;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final details = profileDetailsSummary(profile).join(' · ');
    return Consumer(
      builder: (context, ref, _) {
        final summaryAsync = ref.watch(profileSummaryProvider(profile.id));
        return Card(
          child: ListTile(
            onTap: onSelect,
            leading: _ProfileAvatar(profile: profile, isCurrent: isCurrent),
            title: Text(profile.displayName),
            isThreeLine: true,
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.goals != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Goals: ${profile.goals}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (profile.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                summaryAsync.when(
                  data: (summary) => Text(
                    '${summary.sessionCount} swims · '
                    '${summary.totalDistance}m · '
                    '${summary.drylandWorkoutCount} dryland · '
                    '${summary.personalBestCount} PBs',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                  loading: () => Text(
                    'Loading summary...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                  error: (_, __) => Text(
                    'Summary unavailable',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit swimmer',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  tooltip: 'Archive swimmer',
                  onPressed: onArchive,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    required this.isCurrent,
  });

  final SwimmerProfile profile;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trimmedName = profile.displayName.trim();
    final initial =
        trimmedName.isEmpty ? '?' : trimmedName.substring(0, 1).toUpperCase();
    final imageProvider = profileImageProvider(profile.photoUri);
    return SizedBox.square(
      dimension: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: isCurrent
                ? colorScheme.primary
                : colorScheme.secondaryContainer,
            foregroundImage: imageProvider,
            onForegroundImageError: imageProvider == null ? null : (_, __) {},
            child: Text(
              initial,
              style: TextStyle(
                color: isCurrent
                    ? colorScheme.onPrimary
                    : colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isCurrent)
            Positioned(
              right: -2,
              bottom: -2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileFormResult {
  const _ProfileFormResult({
    required this.displayName,
    required this.preferredPoolLengthMeters,
    required this.preferredStrokes,
    this.photoUri,
    this.primaryEvents,
    this.clubName,
    this.goals,
    this.notes,
  });

  final String displayName;
  final int preferredPoolLengthMeters;
  final String? photoUri;
  final List<String> preferredStrokes;
  final String? primaryEvents;
  final String? clubName;
  final String? goals;
  final String? notes;
}

class _ProfileFormDialog extends StatefulWidget {
  const _ProfileFormDialog({this.profile});

  final SwimmerProfile? profile;

  @override
  State<_ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<_ProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _poolLengthController;
  late final TextEditingController _photoUriController;
  late final TextEditingController _primaryEventsController;
  late final TextEditingController _clubNameController;
  late final TextEditingController _goalsController;
  late final TextEditingController _notesController;
  late Set<String> _preferredStrokes;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _poolLengthController = TextEditingController(
      text: (profile?.preferredPoolLengthMeters ?? 25).toString(),
    );
    _photoUriController = TextEditingController(text: profile?.photoUri ?? '');
    _primaryEventsController =
        TextEditingController(text: profile?.primaryEvents ?? '');
    _clubNameController = TextEditingController(text: profile?.clubName ?? '');
    _goalsController = TextEditingController(text: profile?.goals ?? '');
    _notesController = TextEditingController(text: profile?.notes ?? '');
    _preferredStrokes = {...profile?.preferredStrokes ?? const <String>[]};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _poolLengthController.dispose();
    _photoUriController.dispose();
    _primaryEventsController.dispose();
    _clubNameController.dispose();
    _goalsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _ProfileFormResult(
        displayName: _nameController.text.trim(),
        preferredPoolLengthMeters: int.parse(_poolLengthController.text),
        photoUri: cleanProfileDetail(_photoUriController.text),
        preferredStrokes: normalizePreferredStrokes(_preferredStrokes),
        primaryEvents: cleanProfileDetail(_primaryEventsController.text),
        clubName: cleanProfileDetail(_clubNameController.text),
        goals: cleanProfileDetail(_goalsController.text),
        notes: cleanProfileDetail(_notesController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profile != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit swimmer' : 'Add swimmer'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _poolLengthController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Pool length (m)'),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a pool length';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _photoUriController,
                  decoration: const InputDecoration(
                    labelText: 'Photo path or URL',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Preferred strokes',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final stroke in kStrokes)
                        FilterChip(
                          label: Text(stroke),
                          selected: _preferredStrokes.contains(stroke),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _preferredStrokes.add(stroke);
                              } else {
                                _preferredStrokes.remove(stroke);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _primaryEventsController,
                  decoration: const InputDecoration(
                    labelText: 'Primary events',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clubNameController,
                  decoration: const InputDecoration(labelText: 'Club or team'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _goalsController,
                  decoration: const InputDecoration(labelText: 'Goals'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
