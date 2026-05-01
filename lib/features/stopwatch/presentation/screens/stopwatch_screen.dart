import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/stopwatch_provider.dart';
import '../../../pb/domain/services/pb_service.dart';
import '../../../pb/presentation/providers/pb_providers.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../../swim/domain/entities/lap.dart';
import '../../../swim/domain/entities/swim_session.dart';
import '../../../swim/presentation/providers/swim_providers.dart';
import '../../../../core/utils/duration_utils.dart';

const _uuid = Uuid();

class StopwatchScreen extends ConsumerStatefulWidget {
  const StopwatchScreen({super.key});

  @override
  ConsumerState<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends ConsumerState<StopwatchScreen> {
  bool _saving = false;

  List<Duration> _splitDurations(StopwatchState state) {
    final markers = [...state.lapTimes];
    if (state.elapsed > Duration.zero &&
        (markers.isEmpty || state.elapsed > markers.last)) {
      markers.add(state.elapsed);
    }

    return List.generate(markers.length, (index) {
      if (index == 0) return markers[index];
      return markers[index] - markers[index - 1];
    });
  }

  Future<void> _saveSession(
    StopwatchState state,
    StopwatchNotifier notifier,
  ) async {
    if (state.elapsed == Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start the stopwatch before saving.')),
      );
      return;
    }

    if (state.isRunning) {
      notifier.pause();
    }

    final config = await showDialog<_StopwatchSaveConfig>(
      context: context,
      builder: (_) => const _SaveStopwatchDialog(),
    );
    if (config == null) return;

    final splits = _splitDurations(ref.read(stopwatchProvider));
    if (splits.isEmpty) return;

    setState(() => _saving = true);
    try {
      final sessionId = _uuid.v4();
      final profileId = ref.read(currentProfileIdProvider);
      final laps = splits
          .asMap()
          .entries
          .map(
            (entry) => Lap(
              id: _uuid.v4(),
              sessionId: sessionId,
              profileId: profileId,
              distance: config.lapDistance,
              time: entry.value,
              lapNumber: entry.key + 1,
            ),
          )
          .toList();

      final session = SwimSession(
        id: sessionId,
        profileId: profileId,
        date: DateTime.now(),
        totalDistance: config.lapDistance * laps.length,
        totalTime: ref.read(stopwatchProvider).elapsed,
        stroke: config.stroke,
        laps: laps,
        notes: config.notes,
      );

      await ref.read(swimSessionsProvider.notifier).addSession(session);

      final existingPbs = ref.read(personalBestsProvider).valueOrNull ?? [];
      final newPbs = PbService.detectNewPbs(session, existingPbs);
      for (final pb in newPbs) {
        await ref.read(personalBestsProvider.notifier).save(pb);
      }

      notifier.reset();

      if (!mounted) return;
      final pbText = newPbs.isEmpty ? '' : ' ${newPbs.length} PB updated.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stopwatch session saved.$pbText')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stopwatchProvider);
    final notifier = ref.read(stopwatchProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stopwatch'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: state.elapsed == Duration.zero
                  ? null
                  : () => _saveSession(state, notifier),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
        ],
      ),
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

class _StopwatchSaveConfig {
  const _StopwatchSaveConfig({
    required this.stroke,
    required this.lapDistance,
    this.notes,
  });

  final String stroke;
  final int lapDistance;
  final String? notes;
}

class _SaveStopwatchDialog extends StatefulWidget {
  const _SaveStopwatchDialog();

  @override
  State<_SaveStopwatchDialog> createState() => _SaveStopwatchDialogState();
}

class _SaveStopwatchDialogState extends State<_SaveStopwatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController(text: '50');
  final _notesController = TextEditingController();
  String _stroke = kStrokes.first;

  @override
  void dispose() {
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _StopwatchSaveConfig(
        stroke: _stroke,
        lapDistance: int.parse(_distanceController.text),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Swim Session'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _stroke,
              decoration: const InputDecoration(
                labelText: 'Stroke',
                prefixIcon: Icon(Icons.waves),
              ),
              items: kStrokes
                  .map((stroke) => DropdownMenuItem(
                        value: stroke,
                        child: Text(stroke),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _stroke = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _distanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Distance per lap (m)',
                prefixIcon: Icon(Icons.straighten),
              ),
              validator: (value) {
                final distance = int.tryParse(value ?? '');
                if (distance == null || distance <= 0) {
                  return 'Enter a lap distance';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
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
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
