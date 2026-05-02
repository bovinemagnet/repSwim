import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/stopwatch_display_style_provider.dart';
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
    final displayStyle = ref.watch(stopwatchDisplayStyleProvider);

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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StopwatchDisplay(
                elapsed: state.elapsed,
                style: displayStyle,
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

class _StopwatchDisplay extends StatelessWidget {
  const _StopwatchDisplay({
    required this.elapsed,
    required this.style,
  });

  final Duration elapsed;
  final StopwatchDisplayStyle style;

  @override
  Widget build(BuildContext context) {
    final value = DurationUtils.formatDurationWithCentiseconds(elapsed);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (style) {
        StopwatchDisplayStyle.standard => _StandardStopwatchDisplay(
            key: const ValueKey('standard'),
            value: value,
          ),
        StopwatchDisplayStyle.nixieTube => _NixieStopwatchDisplay(
            key: const ValueKey('nixie'),
            value: value,
          ),
        StopwatchDisplayStyle.vacuumFluorescent => _VfdStopwatchDisplay(
            key: const ValueKey('vfd'),
            value: value,
          ),
        StopwatchDisplayStyle.numitron => _NumitronStopwatchDisplay(
            key: const ValueKey('numitron'),
            value: value,
          ),
        StopwatchDisplayStyle.splitFlap => _SplitFlapStopwatchDisplay(
            key: const ValueKey('split-flap'),
            value: value,
          ),
      },
    );
  }
}

class _StandardStopwatchDisplay extends StatelessWidget {
  const _StandardStopwatchDisplay({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          value,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
        ),
      ),
    );
  }
}

class _NixieStopwatchDisplay extends StatelessWidget {
  const _NixieStopwatchDisplay({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Nixie stopwatch display $value',
      child: Container(
        key: const ValueKey('nixie-stopwatch-display'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF160C08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF5E2D14), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x661E0B04),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final character in value.split(''))
                character == ':' || character == '.'
                    ? _NixieSeparator(character: character)
                    : _NixieTubeDigit(character: character),
            ],
          ),
        ),
      ),
    );
  }
}

class _NixieTubeDigit extends StatelessWidget {
  const _NixieTubeDigit({required this.character});

  final String character;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 68,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF24120B),
            Color(0xFF070302),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF9B4D1B), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAAFF6A00),
            blurRadius: 12,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '8',
            style: _nixieTextStyle(const Color(0x22FF9A2F)),
          ),
          Text(
            character,
            style: _nixieTextStyle(const Color(0xFFFFB14A)).copyWith(
              shadows: const [
                Shadow(color: Color(0xFFFF7A00), blurRadius: 12),
                Shadow(color: Color(0xFFFFD18A), blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NixieSeparator extends StatelessWidget {
  const _NixieSeparator({required this.character});

  final String character;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: character == ':' ? 18 : 14,
      height: 68,
      child: Center(
        child: Text(
          character,
          style: _nixieTextStyle(const Color(0xFFFF9A2F)).copyWith(
            fontSize: 34,
            shadows: const [
              Shadow(color: Color(0xFFFF7A00), blurRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _VfdStopwatchDisplay extends StatelessWidget {
  const _VfdStopwatchDisplay({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Vacuum fluorescent stopwatch display $value',
      child: Container(
        key: const ValueKey('vfd-stopwatch-display'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF031315),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0E6D6F), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x7719F6FF),
              blurRadius: 20,
              spreadRadius: -6,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final character in value.split(''))
                character == ':' || character == '.'
                    ? _PhosphorSeparator(
                        character: character,
                        color: const Color(0xFF8FFBFF),
                      )
                    : _VfdDigit(character: character),
            ],
          ),
        ),
      ),
    );
  }
}

class _VfdDigit extends StatelessWidget {
  const _VfdDigit({required this.character});

  final String character;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF021719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x3326F6FF)),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('8', style: _vfdTextStyle(const Color(0x1626F6FF))),
          Text(
            character,
            style: _vfdTextStyle(const Color(0xFFB8FFFF)).copyWith(
              shadows: const [
                Shadow(color: Color(0xFF22F7FF), blurRadius: 14),
                Shadow(color: Color(0xFFBAFFFF), blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumitronStopwatchDisplay extends StatelessWidget {
  const _NumitronStopwatchDisplay({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Numitron stopwatch display $value',
      child: Container(
        key: const ValueKey('numitron-stopwatch-display'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF120E0A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF6F5537), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55FFB25E),
              blurRadius: 22,
              spreadRadius: -8,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final character in value.split(''))
                character == ':' || character == '.'
                    ? _PhosphorSeparator(
                        character: character,
                        color: const Color(0xFFFFC078),
                      )
                    : _NumitronDigit(character: character),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumitronDigit extends StatelessWidget {
  const _NumitronDigit({required this.character});

  final String character;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 68,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2B2219),
            Color(0xFF0C0906),
          ],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF8D6A43), width: 1.1),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('8', style: _numitronTextStyle(const Color(0x22F2A95C))),
          Text(
            character,
            style: _numitronTextStyle(const Color(0xFFFFD8A3)).copyWith(
              shadows: const [
                Shadow(color: Color(0xFFFFA13A), blurRadius: 10),
                Shadow(color: Color(0xFFFFE5BC), blurRadius: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhosphorSeparator extends StatelessWidget {
  const _PhosphorSeparator({
    required this.character,
    required this.color,
  });

  final String character;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: character == ':' ? 18 : 14,
      height: 64,
      child: Center(
        child: Text(
          character,
          style: _nixieTextStyle(color).copyWith(
            fontSize: 32,
            shadows: [Shadow(color: color, blurRadius: 10)],
          ),
        ),
      ),
    );
  }
}

class _SplitFlapStopwatchDisplay extends StatelessWidget {
  const _SplitFlapStopwatchDisplay({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Split-flap stopwatch display $value',
      child: Container(
        key: const ValueKey('split-flap-stopwatch-display'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF17191C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF4C535B), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final character in value.split(''))
                character == ':' || character == '.'
                    ? _SplitFlapSeparator(character: character)
                    : _SplitFlapCharacter(character: character),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitFlapCharacter extends StatelessWidget {
  const _SplitFlapCharacter({required this.character});

  final String character;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 66,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF343A40), width: 1.1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF262A2F), Color(0xFF181B1F)],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF101215), Color(0xFF23272C)],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ],
          ),
          Container(
            height: 1.4,
            color: const Color(0xCC050607),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 30,
            child: Container(
              height: 1,
              color: const Color(0xFF59616A),
            ),
          ),
          Text(
            character,
            style: _splitFlapTextStyle(),
          ),
        ],
      ),
    );
  }
}

class _SplitFlapSeparator extends StatelessWidget {
  const _SplitFlapSeparator({required this.character});

  final String character;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: character == ':' ? 18 : 14,
      height: 66,
      child: Center(
        child: Text(
          character,
          style: _splitFlapTextStyle().copyWith(fontSize: 30),
        ),
      ),
    );
  }
}

TextStyle _nixieTextStyle(Color color) {
  return TextStyle(
    fontFamily: 'monospace',
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 44,
    height: 1,
    fontWeight: FontWeight.w700,
    color: color,
  );
}

TextStyle _vfdTextStyle(Color color) {
  return TextStyle(
    fontFamily: 'monospace',
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 42,
    height: 1,
    fontWeight: FontWeight.w500,
    color: color,
  );
}

TextStyle _numitronTextStyle(Color color) {
  return TextStyle(
    fontFamily: 'monospace',
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 42,
    height: 1,
    fontWeight: FontWeight.w600,
    color: color,
  );
}

TextStyle _splitFlapTextStyle() {
  return const TextStyle(
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 40,
    height: 1,
    fontWeight: FontWeight.w700,
    color: Color(0xFFECEFF1),
  );
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
