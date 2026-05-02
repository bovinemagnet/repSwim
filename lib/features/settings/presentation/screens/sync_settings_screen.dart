import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_mode.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../../stopwatch/presentation/providers/stopwatch_display_style_provider.dart';

class SyncSettingsScreen extends ConsumerWidget {
  const SyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(syncModeProvider);
    final profileId = ref.watch(currentProfileIdProvider);
    final summaryAsync = ref.watch(syncQueueSummaryProvider);
    final service = ref.watch(syncServiceProvider);
    final queueFailure = ref.watch(syncQueueFailureProvider);
    final stopwatchDisplayStyle = ref.watch(stopwatchDisplayStyleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Mode',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<SyncMode>(
            segments: const [
              ButtonSegment(
                value: SyncMode.localOnly,
                icon: Icon(Icons.phone_android_outlined),
                label: Text('Local'),
              ),
              ButtonSegment(
                value: SyncMode.manual,
                icon: Icon(Icons.sync_outlined),
                label: Text('Manual'),
              ),
              ButtonSegment(
                value: SyncMode.automatic,
                icon: Icon(Icons.autorenew),
                label: Text('Auto'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) {
              setSyncMode(ref, selection.single);
            },
          ),
          const SizedBox(height: 16),
          if (queueFailure != null) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.warning_amber_outlined),
                title: const Text('Some changes could not be queued'),
                subtitle: Text(queueFailure),
                trailing: IconButton(
                  tooltip: 'Dismiss warning',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(syncQueueFailureProvider.notifier).state = null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: ListTile(
              leading: Icon(
                service.isEnabled
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
              ),
              title: Text(service.isEnabled
                  ? 'Backend sync available'
                  : 'No backend configured'),
              subtitle: const Text(
                'Core tracking remains available without login or network.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Queue Status',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          summaryAsync.when(
            data: (summary) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(label: 'Pending', value: summary.pending),
                _StatusChip(label: 'Processing', value: summary.processing),
                _StatusChip(label: 'Failed', value: summary.failed),
                _StatusChip(label: 'Complete', value: summary.complete),
                _StatusChip(label: 'Total', value: summary.total),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
            error: (error, _) => Text('Error: $error'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: service.isEnabled
                ? () async {
                    await service.syncNow(profileId: profileId);
                    ref.invalidate(syncQueueSummaryProvider);
                  }
                : null,
            icon: const Icon(Icons.sync),
            label: const Text('Sync now'),
          ),
          const SizedBox(height: 24),
          Text(
            'Stopwatch Display',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<StopwatchDisplayStyle>(
            initialValue: stopwatchDisplayStyle,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.timer_outlined),
              labelText: 'Timer display style',
            ),
            items: StopwatchDisplayStyle.values
                .map(
                  (style) => DropdownMenuItem(
                    value: style,
                    child: Text(style.label),
                  ),
                )
                .toList(),
            onChanged: (style) {
              if (style != null) {
                setStopwatchDisplayStyle(ref, style);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.circle, size: 12),
      label: Text('$label: $value'),
    );
  }
}
