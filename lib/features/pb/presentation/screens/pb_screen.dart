import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pb_providers.dart';
import '../../domain/entities/personal_best.dart';
import '../../../../core/utils/duration_utils.dart';

class PbScreen extends ConsumerWidget {
  const PbScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pbsAsync = ref.watch(personalBestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Bests')),
      body: pbsAsync.when(
        data: (pbs) {
          if (pbs.isEmpty) {
            return const _EmptyState();
          }
          // Group by stroke
          final grouped = <String, List<PersonalBest>>{};
          for (final pb in pbs) {
            grouped.putIfAbsent(pb.stroke, () => []).add(pb);
          }
          final strokes = grouped.keys.toList()..sort();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: strokes.length,
            itemBuilder: (context, i) {
              final stroke = strokes[i];
              final strokePbs = grouped[stroke]!
                ..sort((a, b) => a.distance.compareTo(b.distance));
              return _StrokeGroup(stroke: stroke, pbs: strokePbs);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.amber),
          SizedBox(height: 16),
          Text(
            'No Personal Bests yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Save swim sessions with lap times to\ntrack your personal bests automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _StrokeGroup extends StatelessWidget {
  const _StrokeGroup({required this.stroke, required this.pbs});

  final String stroke;
  final List<PersonalBest> pbs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.waves, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                stroke,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        ...pbs.map((pb) => _PbTile(pb: pb)),
      ],
    );
  }
}

class _PbTile extends StatelessWidget {
  const _PbTile({required this.pb});

  final PersonalBest pb;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('d MMM yyyy').format(pb.achievedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${pb.distance}m',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        title: Text(
          DurationUtils.formatDuration(pb.bestTime),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 18),
        ),
        subtitle: Text(
          DurationUtils.formatPace(pb.bestTime, pb.distance),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
            const SizedBox(height: 2),
            Text(dateStr,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
