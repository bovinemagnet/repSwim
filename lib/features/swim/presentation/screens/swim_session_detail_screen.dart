import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/duration_utils.dart';
import '../../../pb/domain/services/pb_service.dart';
import '../../../pb/presentation/providers/pb_providers.dart';
import '../../domain/entities/lap.dart';
import '../../domain/entities/swim_session.dart';
import '../providers/swim_providers.dart';

class SwimSessionDetailScreen extends ConsumerWidget {
  const SwimSessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    SwimSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete session?'),
        content: const Text('This removes the swim session and all lap data.'),
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
    await ref.read(swimSessionsProvider.notifier).deleteSession(session.id);
    final remainingSessions =
        ref.read(swimSessionsProvider).valueOrNull ?? const <SwimSession>[];
    final rebuiltPbs = PbService.rebuildFromSessions(remainingSessions);
    await ref.read(personalBestsProvider.notifier).replaceAll(rebuiltPbs);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Session deleted.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(swimSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        final matches = sessions.where((session) => session.id == sessionId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Session Details')),
            body: const Center(child: Text('Session not found')),
          );
        }

        final session = matches.first;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Session Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete session',
                onPressed: () => _deleteSession(context, ref, session),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SessionSummary(session: session),
              const SizedBox(height: 16),
              if (session.notes != null && session.notes!.isNotEmpty) ...[
                _NotesCard(notes: session.notes!),
                const SizedBox(height: 16),
              ],
              Text(
                'Laps',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...session.laps.map((lap) => _LapTile(lap: lap)),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Session Details')),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Session Details')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.session});

  final SwimSession session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateFormat('EEEE, d MMM yyyy').format(session.date);
    final time = DateFormat('h:mm a').format(session.date);

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.stroke,
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
                  label: '${session.totalDistance}m',
                ),
                _SummaryChip(
                  icon: Icons.timer_outlined,
                  label: DurationUtils.formatDuration(session.totalTime),
                ),
                _SummaryChip(
                  icon: Icons.speed,
                  label: DurationUtils.formatPace(
                    session.totalTime,
                    session.totalDistance,
                  ),
                ),
                _SummaryChip(
                  icon: Icons.flag_outlined,
                  label: '${session.laps.length} laps',
                ),
              ],
            ),
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

class _LapTile extends StatelessWidget {
  const _LapTile({required this.lap});

  final Lap lap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${lap.lapNumber}'),
        ),
        title: Text('${lap.distance}m'),
        subtitle: Text(DurationUtils.formatPace(lap.time, lap.distance)),
        trailing: Text(
          DurationUtils.formatDuration(lap.time),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
