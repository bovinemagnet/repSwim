import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/duration_utils.dart';
import '../../domain/entities/tempo_mode.dart';
import '../../domain/entities/tempo_session_result.dart';
import '../../domain/services/tempo_calculator.dart';
import '../providers/tempo_template_providers.dart';

class TempoResultsScreen extends ConsumerWidget {
  const TempoResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(tempoSessionResultsProvider);

    return resultsAsync.when(
      data: (results) => Scaffold(
        appBar: AppBar(title: const Text('Tempo History')),
        body: results.isEmpty
            ? const Center(child: Text('No tempo sessions yet'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final result = results[index];
                  return _TempoResultTile(result: result);
                },
              ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Tempo History')),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Tempo History')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class TempoResultDetailScreen extends ConsumerWidget {
  const TempoResultDetailScreen({
    super.key,
    required this.resultId,
  });

  final String resultId;

  Future<void> _deleteResult(
    BuildContext context,
    WidgetRef ref,
    TempoSessionResult result,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete tempo result?'),
        content: const Text('This removes the saved tempo session result.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref
        .read(tempoSessionResultsProvider.notifier)
        .deleteResult(result.id);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Tempo result deleted.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(tempoSessionResultsProvider);

    return resultsAsync.when(
      data: (results) {
        final matches = results.where((result) => result.id == resultId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tempo Result')),
            body: const Center(child: Text('Tempo result not found')),
          );
        }

        final result = matches.first;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tempo Result'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete tempo result',
                onPressed: () => _deleteResult(context, ref, result),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TempoResultSummary(result: result),
              const SizedBox(height: 16),
              if (result.notes != null && result.notes!.isNotEmpty) ...[
                _NotesCard(notes: result.notes!),
                const SizedBox(height: 16),
              ],
              Text(
                'Splits',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._splitRows(result),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Tempo Result')),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Tempo Result')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  List<Widget> _splitRows(TempoSessionResult result) {
    final targetSplit = const TempoCalculator().splitForDistance(
      targetTime: result.targetTime,
      targetDistanceMeters: result.targetDistanceMeters,
      splitDistanceMeters: result.poolLengthMeters,
    );
    final splitResults = const TempoCalculator().compareSplits(
      actualSplits: result.actualSplits,
      targetSplit: targetSplit,
      strokeCounts: result.strokeCounts,
    );
    return [
      for (final split in splitResults) _SplitTile(split: split),
    ];
  }
}

class _TempoResultTile extends StatelessWidget {
  const _TempoResultTile({required this.result});

  final TempoSessionResult result;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy, h:mm a').format(result.startedAt);
    final pace = DurationUtils.formatPace(
      result.targetTime,
      result.targetDistanceMeters,
    );
    return Card(
      child: ListTile(
        onTap: () => context.push('/tempo/results/${result.id}'),
        leading: CircleAvatar(
          child: Icon(_modeIcon(result)),
        ),
        title: Text('${result.mode.label} - ${result.targetDistanceMeters}m'),
        subtitle: Text(
          '$date - ${result.actualSplits.length} splits - $pace'
          '${result.rpe == null ? '' : ' - RPE ${result.rpe}'}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _TempoResultSummary extends StatelessWidget {
  const _TempoResultSummary({required this.result});

  final TempoSessionResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateFormat('EEEE, d MMM yyyy').format(result.startedAt);
    final time = DateFormat('h:mm a').format(result.startedAt);
    final pace = DurationUtils.formatPace(
      result.targetTime,
      result.targetDistanceMeters,
    );

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.mode.label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$date at $time',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  icon: Icons.straighten,
                  label: '${result.targetDistanceMeters}m',
                ),
                _SummaryChip(
                  icon: Icons.pool_outlined,
                  label: '${result.poolLengthMeters}m pool',
                ),
                _SummaryChip(
                  icon: Icons.timer_outlined,
                  label: DurationUtils.formatDuration(result.targetTime),
                ),
                _SummaryChip(
                  icon: Icons.speed,
                  label: pace,
                ),
                _SummaryChip(
                  icon: Icons.graphic_eq,
                  label: '${result.targetStrokeRate.toStringAsFixed(1)} spm',
                ),
                if (result.rpe != null)
                  _SummaryChip(
                    icon: Icons.monitor_heart_outlined,
                    label: 'RPE ${result.rpe}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitTile extends StatelessWidget {
  const _SplitTile({required this.split});

  final TempoSplitResult split;

  @override
  Widget build(BuildContext context) {
    final onPace = split.isOnPace;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${split.index}')),
        title: Text(
          DurationUtils.formatDurationWithCentiseconds(split.actualSplit),
        ),
        subtitle: Text(
          'Target ${DurationUtils.formatDurationWithCentiseconds(split.targetSplit)}'
          ' - Error ${_formatSignedDuration(split.error)}'
          ' - Strokes ${split.strokeCount?.toString() ?? '-'}',
        ),
        trailing: Chip(
          label: Text(onPace ? 'On pace' : 'Off pace'),
          avatar: Icon(
            onPace ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(notes),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: colorScheme.surface,
      side: BorderSide.none,
    );
  }
}

IconData _modeIcon(TempoSessionResult result) {
  return switch (result.mode) {
    TempoMode.strokeRate => Icons.speed,
    TempoMode.lapPace => Icons.flag_outlined,
    TempoMode.breathPattern => Icons.air,
  };
}

String _formatSignedDuration(Duration duration) {
  final sign = duration.isNegative ? '-' : '+';
  final absolute = duration.isNegative ? -duration : duration;
  return '$sign${DurationUtils.formatDurationWithCentiseconds(absolute)}';
}
