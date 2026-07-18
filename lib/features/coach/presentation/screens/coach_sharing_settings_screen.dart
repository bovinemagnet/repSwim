import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/coach_share_category.dart';
import '../providers/coach_providers.dart';

/// Settings screen that lets a swimmer configure what data is shared with a
/// coach.
class CoachSharingSettingsScreen extends ConsumerWidget {
  const CoachSharingSettingsScreen({required this.profileId, super.key});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareAsync = ref.watch(coachShareControllerProvider(profileId));

    return Scaffold(
      appBar: AppBar(title: const Text('Coach sharing')),
      body: shareAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (share) {
          final controller =
              ref.read(coachShareControllerProvider(profileId).notifier);

          final categoryTiles = CoachShareCategory.values
              .map(
                (category) => SwitchListTile(
                  title: Text(category.label),
                  value: share.sharedCategories.contains(category),
                  onChanged: (value) => controller.setCategory(category, value),
                ),
              )
              .toList();

          final sharedLabels = share.sharedCategories.isEmpty
              ? 'Nothing shared yet'
              : share.sharedCategories.map((c) => c.label).join(', ');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Share with coach'),
                value: share.enabled,
                onChanged: controller.setEnabled,
              ),
              if (share.enabled) ...[
                ...categoryTiles,
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Notes and personal details are shared only when their '
                    'switches are on.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Sharing: $sharedLabels'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: controller.stopSharing,
                    child: const Text('Stop sharing'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
