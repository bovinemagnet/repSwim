import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/duration_utils.dart';
import '../../domain/entities/tempo_mode.dart';
import '../../domain/entities/tempo_session_result.dart';
import '../../domain/entities/tempo_template.dart';
import '../../domain/services/tempo_calculator.dart';
import '../../domain/services/tempo_csv_exporter.dart';
import '../providers/tempo_template_providers.dart';
import '../providers/tempo_trainer_provider.dart';

class TempoTrainerScreen extends ConsumerStatefulWidget {
  const TempoTrainerScreen({super.key});

  @override
  ConsumerState<TempoTrainerScreen> createState() => _TempoTrainerScreenState();
}

class _TempoTrainerScreenState extends ConsumerState<TempoTrainerScreen> {
  late final TextEditingController _poolLengthController;
  late final TextEditingController _targetDistanceController;
  late final TextEditingController _targetTimeController;
  late final TextEditingController _strokeRateController;
  late final TextEditingController _breathEveryController;
  late final TextEditingController _accentEveryController;
  late final TextEditingController _splitsController;
  late final TextEditingController _strokeCountsController;
  late final TextEditingController _rpeController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(tempoTrainerProvider);
    _poolLengthController =
        TextEditingController(text: state.poolLengthMeters.toString());
    _targetDistanceController =
        TextEditingController(text: state.targetDistanceMeters.toString());
    _targetTimeController =
        TextEditingController(text: _secondsText(state.targetTime));
    _strokeRateController =
        TextEditingController(text: state.strokeRate.toStringAsFixed(0));
    _breathEveryController =
        TextEditingController(text: state.breathEveryStrokes.toString());
    _accentEveryController =
        TextEditingController(text: state.cueSettings.accentEvery.toString());
    _splitsController = TextEditingController();
    _strokeCountsController = TextEditingController();
    _rpeController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _poolLengthController.dispose();
    _targetDistanceController.dispose();
    _targetTimeController.dispose();
    _strokeRateController.dispose();
    _breathEveryController.dispose();
    _accentEveryController.dispose();
    _splitsController.dispose();
    _strokeCountsController.dispose();
    _rpeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _secondsText(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    return seconds == seconds.roundToDouble()
        ? seconds.toStringAsFixed(0)
        : seconds.toStringAsFixed(2);
  }

  void _applyConfig(TempoTrainerState state) {
    final poolLength = int.tryParse(_poolLengthController.text);
    final targetDistance = int.tryParse(_targetDistanceController.text);
    final targetSeconds = double.tryParse(_targetTimeController.text);
    final strokeRate = double.tryParse(_strokeRateController.text);
    final breathEvery = int.tryParse(_breathEveryController.text);
    final accentEvery = int.tryParse(_accentEveryController.text);

    if (poolLength == null ||
        poolLength <= 0 ||
        targetDistance == null ||
        targetDistance <= 0 ||
        targetSeconds == null ||
        targetSeconds <= 0 ||
        strokeRate == null ||
        strokeRate <= 0 ||
        breathEvery == null ||
        breathEvery <= 0 ||
        accentEvery == null ||
        accentEvery <= 0) {
      _showSnack('Enter valid tempo values.');
      return;
    }

    final targetTime = Duration(milliseconds: (targetSeconds * 1000).round());
    ref.read(tempoTrainerProvider.notifier).configure(
          mode: state.mode,
          poolLengthMeters: poolLength,
          targetDistanceMeters: targetDistance,
          targetTime: targetTime,
          strokeRate: strokeRate,
          breathEveryStrokes: breathEvery,
          cueSettings: state.cueSettings.copyWith(accentEvery: accentEvery),
          safetyWarningAcknowledged: state.safetyWarningAcknowledged,
        );
    FocusScope.of(context).unfocus();
  }

  void _syncControllers(TempoTrainerState state) {
    _poolLengthController.text = state.poolLengthMeters.toString();
    _targetDistanceController.text = state.targetDistanceMeters.toString();
    _targetTimeController.text = _secondsText(state.targetTime);
    _strokeRateController.text = state.strokeRate.toStringAsFixed(0);
    _breathEveryController.text = state.breathEveryStrokes.toString();
    _accentEveryController.text = state.cueSettings.accentEvery.toString();
  }

  Future<void> _saveTemplate() async {
    final name = await _promptForName(
      title: 'Save tempo template',
      label: 'Template name',
    );
    if (name == null || name.trim().isEmpty) return;
    final saved = await ref
        .read(tempoTemplatesProvider.notifier)
        .saveFromState(name, ref.read(tempoTrainerProvider));
    if (!mounted) return;
    _showSnack('Saved ${saved.name}.');
  }

  Future<void> _saveSessionResult(TempoTrainerState state) async {
    final splits = _parseDurationList(_splitsController.text);
    if (splits.isEmpty) {
      _showSnack('Enter at least one actual split in seconds.');
      return;
    }
    final strokeCounts = _parseIntList(_strokeCountsController.text);
    final rpe = _rpeController.text.trim().isEmpty
        ? null
        : int.tryParse(_rpeController.text);
    if (rpe != null && (rpe < 1 || rpe > 10)) {
      _showSnack('RPE must be between 1 and 10.');
      return;
    }

    final result =
        await ref.read(tempoSessionResultsProvider.notifier).saveResult(
              trainer: state,
              actualSplits: splits,
              strokeCounts: strokeCounts,
              rpe: rpe,
              notes: _notesController.text,
            );
    if (!mounted) return;
    _showSnack('Saved tempo result with ${result.actualSplits.length} splits.');
  }

  Future<void> _copyCsv(TempoTrainerState state) async {
    final splits = _parseDurationList(_splitsController.text);
    if (splits.isEmpty) {
      _showSnack('Enter actual splits before exporting CSV.');
      return;
    }
    final result = TempoSessionResult(
      id: 'preview',
      mode: state.mode,
      startedAt: DateTime.now().toUtc(),
      completedAt: DateTime.now().toUtc(),
      targetDistanceMeters: state.targetDistanceMeters,
      poolLengthMeters: state.poolLengthMeters,
      targetTime: state.targetTime,
      targetStrokeRate: state.strokeRate,
      actualSplits: splits,
      strokeCounts: _parseIntList(_strokeCountsController.text),
    );
    final csv = const TempoCsvExporter().exportSession(result);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    _showSnack('Copied tempo CSV.');
  }

  List<Duration> _parseDurationList(String value) {
    return value
        .split(',')
        .map((item) => double.tryParse(item.trim()))
        .whereType<double>()
        .where((seconds) => seconds > 0)
        .map((seconds) => Duration(milliseconds: (seconds * 1000).round()))
        .toList();
  }

  List<int> _parseIntList(String value) {
    return value
        .split(',')
        .map((item) => int.tryParse(item.trim()))
        .whereType<int>()
        .where((count) => count > 0)
        .toList();
  }

  Future<String?> _promptForName({
    required String title,
    required String label,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    return result;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tempoTrainerProvider);
    final notifier = ref.read(tempoTrainerProvider.notifier);
    final templatesAsync = ref.watch(tempoTemplatesProvider);
    final resultsAsync = ref.watch(tempoSessionResultsProvider);

    ref.listen(tempoTrainerProvider, (_, next) {
      if (!next.flashActive) return;
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        ref.read(tempoTrainerProvider.notifier).clearFlash();
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tempo Trainer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Tempo history',
            onPressed: () => context.push('/tempo/results'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ModeSelector(
              value: state.mode,
              enabled: !state.isRunning,
              onChanged: (mode) {
                ref.read(tempoTrainerProvider.notifier).configure(
                      mode: mode,
                      poolLengthMeters: state.poolLengthMeters,
                      targetDistanceMeters: state.targetDistanceMeters,
                      targetTime: state.targetTime,
                      strokeRate: state.strokeRate,
                      breathEveryStrokes: state.breathEveryStrokes,
                      cueSettings: state.cueSettings,
                      safetyWarningAcknowledged:
                          state.safetyWarningAcknowledged,
                    );
              },
            ),
            const SizedBox(height: 16),
            _TempoConfigPanel(
              state: state,
              poolLengthController: _poolLengthController,
              targetDistanceController: _targetDistanceController,
              targetTimeController: _targetTimeController,
              strokeRateController: _strokeRateController,
              breathEveryController: _breathEveryController,
              accentEveryController: _accentEveryController,
              onApply: () => _applyConfig(state),
              onCueSettingsChanged: (settings) {
                ref.read(tempoTrainerProvider.notifier).configure(
                      mode: state.mode,
                      poolLengthMeters: state.poolLengthMeters,
                      targetDistanceMeters: state.targetDistanceMeters,
                      targetTime: state.targetTime,
                      strokeRate: state.strokeRate,
                      breathEveryStrokes: state.breathEveryStrokes,
                      cueSettings: settings,
                      safetyWarningAcknowledged:
                          state.safetyWarningAcknowledged,
                    );
              },
              onSafetyChanged: (value) {
                ref.read(tempoTrainerProvider.notifier).configure(
                      mode: state.mode,
                      poolLengthMeters: state.poolLengthMeters,
                      targetDistanceMeters: state.targetDistanceMeters,
                      targetTime: state.targetTime,
                      strokeRate: state.strokeRate,
                      breathEveryStrokes: state.breathEveryStrokes,
                      cueSettings: state.cueSettings,
                      safetyWarningAcknowledged: value,
                    );
              },
            ),
            const SizedBox(height: 16),
            _RunPanel(
              state: state,
              onStartPause: state.isRunning ? notifier.pause : notifier.start,
              onStop: notifier.stop,
            ),
            const SizedBox(height: 16),
            _TemplatePanel(
              templatesAsync: templatesAsync,
              enabled: !state.isRunning,
              onSave: _saveTemplate,
              onLoad: (template) {
                notifier.loadTemplate(template);
                _syncControllers(ref.read(tempoTrainerProvider));
                _showSnack('Loaded ${template.name}.');
              },
              onDelete: (id) =>
                  ref.read(tempoTemplatesProvider.notifier).deleteTemplate(id),
            ),
            const SizedBox(height: 16),
            _ResultPanel(
              state: state,
              resultsAsync: resultsAsync,
              splitsController: _splitsController,
              strokeCountsController: _strokeCountsController,
              rpeController: _rpeController,
              notesController: _notesController,
              onSave: () => _saveSessionResult(state),
              onCopyCsv: () => _copyCsv(state),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final TempoMode value;
  final bool enabled;
  final ValueChanged<TempoMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TempoMode>(
      segments: [
        for (final mode in TempoMode.values)
          ButtonSegment<TempoMode>(
            value: mode,
            icon: Icon(_iconForMode(mode)),
            label: Text(mode.label),
          ),
      ],
      selected: {value},
      onSelectionChanged:
          enabled ? (selected) => onChanged(selected.single) : null,
    );
  }

  IconData _iconForMode(TempoMode mode) {
    return switch (mode) {
      TempoMode.strokeRate => Icons.speed,
      TempoMode.lapPace => Icons.flag_outlined,
      TempoMode.breathPattern => Icons.air,
    };
  }
}

class _TempoConfigPanel extends StatelessWidget {
  const _TempoConfigPanel({
    required this.state,
    required this.poolLengthController,
    required this.targetDistanceController,
    required this.targetTimeController,
    required this.strokeRateController,
    required this.breathEveryController,
    required this.accentEveryController,
    required this.onApply,
    required this.onCueSettingsChanged,
    required this.onSafetyChanged,
  });

  final TempoTrainerState state;
  final TextEditingController poolLengthController;
  final TextEditingController targetDistanceController;
  final TextEditingController targetTimeController;
  final TextEditingController strokeRateController;
  final TextEditingController breathEveryController;
  final TextEditingController accentEveryController;
  final VoidCallback onApply;
  final ValueChanged<TempoCueSettings> onCueSettingsChanged;
  final ValueChanged<bool> onSafetyChanged;

  @override
  Widget build(BuildContext context) {
    final cue = state.cueSettings;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Setup',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _NumberField(
                  controller: poolLengthController,
                  label: 'Pool m',
                  enabled: !state.isRunning,
                ),
                _NumberField(
                  controller: targetDistanceController,
                  label: 'Target m',
                  enabled: !state.isRunning,
                ),
                _NumberField(
                  controller: targetTimeController,
                  label: 'Target sec',
                  enabled: !state.isRunning,
                  decimal: true,
                ),
                _NumberField(
                  controller: strokeRateController,
                  label: 'Stroke/min',
                  enabled: !state.isRunning,
                  decimal: true,
                ),
                _NumberField(
                  controller: breathEveryController,
                  label: 'Breathe every',
                  enabled: !state.isRunning,
                ),
                _NumberField(
                  controller: accentEveryController,
                  label: 'Accent every',
                  enabled: !state.isRunning,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text('Sound'),
                  selected: cue.audible,
                  onSelected: state.isRunning
                      ? null
                      : (value) => onCueSettingsChanged(
                            cue.copyWith(audible: value),
                          ),
                ),
                FilterChip(
                  label: const Text('Vibration'),
                  selected: cue.vibration,
                  onSelected: state.isRunning
                      ? null
                      : (value) => onCueSettingsChanged(
                            cue.copyWith(vibration: value),
                          ),
                ),
                FilterChip(
                  label: const Text('Visual flash'),
                  selected: cue.visualFlash,
                  onSelected: state.isRunning
                      ? null
                      : (value) => onCueSettingsChanged(
                            cue.copyWith(visualFlash: value),
                          ),
                ),
                FilterChip(
                  label: const Text('Voice alert'),
                  selected: cue.spoken,
                  onSelected: state.isRunning
                      ? null
                      : (value) => onCueSettingsChanged(
                            cue.copyWith(spoken: value),
                          ),
                ),
              ],
            ),
            if (state.requiresSafetyWarning) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: state.safetyWarningAcknowledged,
                onChanged: state.isRunning
                    ? null
                    : (value) => onSafetyChanged(value ?? false),
                title: const Text('Breath safety acknowledged'),
                subtitle: const Text(
                  'Breath cues are for rhythm only. Do not use this for '
                  'max breath holds, underwater distance challenges, or '
                  'unsupervised hypoxic sets.',
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: state.isRunning ? null : onApply,
                icon: const Icon(Icons.check),
                label: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunPanel extends StatelessWidget {
  const _RunPanel({
    required this.state,
    required this.onStartPause,
    required this.onStop,
  });

  final TempoTrainerState state;
  final VoidCallback onStartPause;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const calculator = TempoCalculator();
    final pace = DurationUtils.formatDurationWithCentiseconds(
      state.pacePer100,
    );
    final split = DurationUtils.formatDurationWithCentiseconds(state.lapSplit);
    final interval = DurationUtils.formatDurationWithCentiseconds(
      state.cueInterval,
    );

    return Card(
      color: state.flashActive
          ? colorScheme.primaryContainer
          : colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              state.lastCueLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Cue $interval · Split $split · Pace $pace/100m',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Beat ${state.beatCount} · '
              '${DurationUtils.formatDuration(state.elapsed)} elapsed',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (state.mode == TempoMode.strokeRate) ...[
              const SizedBox(height: 8),
              Text(
                '${calculator.strokeRateForBeatInterval(state.cueInterval).toStringAsFixed(1)} strokes/min',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Reset'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: state.requiresSafetyWarning &&
                          !state.safetyWarningAcknowledged
                      ? null
                      : onStartPause,
                  icon: Icon(
                    state.isRunning ? Icons.pause : Icons.play_arrow,
                  ),
                  label: Text(state.isRunning ? 'Pause' : 'Start'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplatePanel extends StatelessWidget {
  const _TemplatePanel({
    required this.templatesAsync,
    required this.enabled,
    required this.onSave,
    required this.onLoad,
    required this.onDelete,
  });

  final AsyncValue<List<TempoTemplate>> templatesAsync;
  final bool enabled;
  final VoidCallback onSave;
  final ValueChanged<TempoTemplate> onLoad;
  final Future<void> Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    final templates = templatesAsync.valueOrNull ?? const <TempoTemplate>[];
    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<TempoTemplate>(
            tooltip: 'Load tempo template',
            enabled: enabled && templates.isNotEmpty,
            onSelected: onLoad,
            itemBuilder: (_) => [
              for (final template in templates)
                PopupMenuItem<TempoTemplate>(
                  value: template,
                  child: Text('${template.name} · ${template.mode.label}'),
                ),
            ],
            child: IgnorePointer(
              child: OutlinedButton.icon(
                onPressed: enabled && templates.isNotEmpty ? () {} : null,
                icon: const Icon(Icons.folder_open_outlined),
                label: Text(
                  templates.isEmpty ? 'No Templates' : 'Load Template',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: enabled ? onSave : null,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
        if (templates.isNotEmpty) ...[
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Delete tempo template',
            enabled: enabled,
            icon: const Icon(Icons.delete_outline),
            onSelected: onDelete,
            itemBuilder: (_) => [
              for (final template in templates)
                PopupMenuItem<String>(
                  value: template.id,
                  child: Text('Delete ${template.name}'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.state,
    required this.resultsAsync,
    required this.splitsController,
    required this.strokeCountsController,
    required this.rpeController,
    required this.notesController,
    required this.onSave,
    required this.onCopyCsv,
  });

  final TempoTrainerState state;
  final AsyncValue<List<TempoSessionResult>> resultsAsync;
  final TextEditingController splitsController;
  final TextEditingController strokeCountsController;
  final TextEditingController rpeController;
  final TextEditingController notesController;
  final VoidCallback onSave;
  final VoidCallback onCopyCsv;

  @override
  Widget build(BuildContext context) {
    final resultCount = resultsAsync.valueOrNull?.length ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session Result',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: splitsController,
              decoration: const InputDecoration(
                labelText: 'Actual splits sec',
                hintText: '22.5, 22.9, 23.1, 22.8',
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: strokeCountsController,
              decoration: const InputDecoration(
                labelText: 'Stroke counts',
                hintText: '18, 19, 20, 20',
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: rpeController,
              decoration: const InputDecoration(labelText: 'RPE 1-10'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$resultCount saved tempo sessions',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onCopyCsv,
                  icon: const Icon(Icons.copy),
                  label: const Text('CSV'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: state.isRunning ? null : onSave,
                  icon: const Icon(Icons.done),
                  label: const Text('Save Result'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      ),
    );
  }
}
