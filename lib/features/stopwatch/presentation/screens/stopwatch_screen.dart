import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stopwatch_provider.dart';
import '../../../../core/utils/duration_utils.dart';

class StopwatchScreen extends ConsumerWidget {
  const StopwatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stopwatchProvider);
    final notifier = ref.read(stopwatchProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Stopwatch')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // ── Timer display ─────────────────────────────────────────────
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  DurationUtils.formatDurationWithCentiseconds(state.elapsed),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontFamily: 'monospace',
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Controls ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset / Stop
                _ControlButton(
                  onPressed: notifier.reset,
                  icon: Icons.stop,
                  label: 'Reset',
                  outlined: true,
                ),
                const SizedBox(width: 16),

                // Start / Pause (large)
                _ControlButton(
                  onPressed: state.isRunning ? notifier.pause : notifier.start,
                  icon: state.isRunning ? Icons.pause : Icons.play_arrow,
                  label: state.isRunning ? 'Pause' : 'Start',
                  large: true,
                ),
                const SizedBox(width: 16),

                // Lap
                _ControlButton(
                  onPressed: state.isRunning ? notifier.lap : null,
                  icon: Icons.flag_outlined,
                  label: 'Lap',
                  outlined: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Lap list ──────────────────────────────────────────────────
            if (state.lapTimes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Laps',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${state.lapTimes.length} laps',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.lapTimes.length,
                  itemBuilder: (context, i) {
                    final lapIndex = state.lapTimes.length - 1 - i;
                    final lapTime = state.lapTimes[lapIndex];
                    final splitTime = lapIndex == 0
                        ? lapTime
                        : lapTime - state.lapTimes[lapIndex - 1];
                    return _LapTile(
                      lapNumber: lapIndex + 1,
                      totalTime: lapTime,
                      splitTime: splitTime,
                    );
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    'Press Start, then Lap to record splits',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.outlined = false,
    this.large = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool outlined;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 80.0 : 60.0;
    final iconSize = large ? 32.0 : 24.0;
    final colorScheme = Theme.of(context).colorScheme;

    final button = outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              fixedSize: Size(size, size),
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: Icon(icon, size: iconSize),
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              fixedSize: Size(size, size),
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              backgroundColor: large ? colorScheme.primary : null,
            ),
            child: Icon(icon, size: iconSize),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _LapTile extends StatelessWidget {
  const _LapTile({
    required this.lapNumber,
    required this.totalTime,
    required this.splitTime,
  });

  final int lapNumber;
  final Duration totalTime;
  final Duration splitTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          child: Text('$lapNumber',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        title: Text(
          'Split: ${DurationUtils.formatDurationWithCentiseconds(splitTime)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          DurationUtils.formatDurationWithCentiseconds(totalTime),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
