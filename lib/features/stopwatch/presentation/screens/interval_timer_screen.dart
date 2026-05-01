import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/duration_utils.dart';
import '../../../templates/domain/entities/interval_template.dart';
import '../../../templates/presentation/providers/training_template_providers.dart';
import '../providers/interval_timer_provider.dart';

class IntervalTimerScreen extends ConsumerStatefulWidget {
  const IntervalTimerScreen({super.key});

  @override
  ConsumerState<IntervalTimerScreen> createState() =>
      _IntervalTimerScreenState();
}

class _IntervalTimerScreenState extends ConsumerState<IntervalTimerScreen> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _workController;
  late final TextEditingController _restController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(intervalTimerProvider);
    _setsController = TextEditingController(text: state.sets.toString());
    _repsController = TextEditingController(text: state.reps.toString());
    _workController =
        TextEditingController(text: state.workDuration.inSeconds.toString());
    _restController =
        TextEditingController(text: state.restDuration.inSeconds.toString());
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _workController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _applyConfig() {
    final sets = int.tryParse(_setsController.text);
    final reps = int.tryParse(_repsController.text);
    final workSeconds = int.tryParse(_workController.text);
    final restSeconds = int.tryParse(_restController.text);

    if (sets == null ||
        sets <= 0 ||
        reps == null ||
        reps <= 0 ||
        workSeconds == null ||
        workSeconds <= 0 ||
        restSeconds == null ||
        restSeconds < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid interval values.')),
      );
      return;
    }

    ref.read(intervalTimerProvider.notifier).configure(
          sets: sets,
          reps: reps,
          workDuration: Duration(seconds: workSeconds),
          restDuration: Duration(seconds: restSeconds),
        );
    FocusScope.of(context).unfocus();
  }

  void _applyTemplate(IntervalTemplate template) {
    _setsController.text = template.sets.toString();
    _repsController.text = template.reps.toString();
    _workController.text = template.workDuration.inSeconds.toString();
    _restController.text = template.restDuration.inSeconds.toString();
    ref.read(intervalTimerProvider.notifier).configure(
          sets: template.sets,
          reps: template.reps,
          workDuration: template.workDuration,
          restDuration: template.restDuration,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded ${template.name}.')),
    );
  }

  Future<void> _saveTemplate() async {
    final name = await _promptForTemplateName(context);
    if (name == null || name.trim().isEmpty) return;
    final template = await ref
        .read(intervalTemplatesProvider.notifier)
        .saveFromState(name, ref.read(intervalTimerProvider));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${template.name}.')),
    );
  }

  Future<String?> _promptForTemplateName(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save interval template'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Template name'),
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
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(intervalTimerProvider);
    final templatesAsync = ref.watch(intervalTemplatesProvider);
    final notifier = ref.read(intervalTimerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Interval Timer')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ConfigPanel(
              setsController: _setsController,
              repsController: _repsController,
              workController: _workController,
              restController: _restController,
              enabled: !state.isRunning,
              onApply: _applyConfig,
            ),
            const SizedBox(height: 24),
            _TimerPanel(state: state),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: notifier.reset,
                  icon: const Icon(Icons.stop),
                  label: const Text('Reset'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: state.phase == IntervalPhase.complete
                      ? null
                      : state.isRunning
                          ? notifier.pause
                          : notifier.start,
                  icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(state.isRunning ? 'Pause' : 'Start'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: state.phase == IntervalPhase.complete
                      ? null
                      : notifier.skipPhase,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: state.totalRounds == 0
                  ? 0
                  : state.currentRound / state.totalRounds,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              'Round ${state.currentRound} of ${state.totalRounds}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _TemplatePanel(
              templatesAsync: templatesAsync,
              enabled: !state.isRunning,
              onLoad: _applyTemplate,
              onSave: _saveTemplate,
              onDelete: (id) => ref
                  .read(intervalTemplatesProvider.notifier)
                  .deleteTemplate(id),
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
    required this.onLoad,
    required this.onSave,
    required this.onDelete,
  });

  final AsyncValue<List<IntervalTemplate>> templatesAsync;
  final bool enabled;
  final ValueChanged<IntervalTemplate> onLoad;
  final VoidCallback onSave;
  final Future<void> Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    final templates = templatesAsync.valueOrNull ?? const <IntervalTemplate>[];
    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<IntervalTemplate>(
            tooltip: 'Load interval template',
            enabled: enabled && templates.isNotEmpty,
            onSelected: onLoad,
            itemBuilder: (_) => [
              for (final template in templates)
                PopupMenuItem<IntervalTemplate>(
                  value: template,
                  child: Text(
                    '${template.name} · ${template.sets}x${template.reps}',
                  ),
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
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('Save Template'),
        ),
        if (templates.isNotEmpty) ...[
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Delete interval template',
            enabled: enabled,
            onSelected: onDelete,
            itemBuilder: (_) => [
              for (final template in templates)
                PopupMenuItem<String>(
                  value: template.id,
                  child: Text('Delete ${template.name}'),
                ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ],
    );
  }
}

class _ConfigPanel extends StatelessWidget {
  const _ConfigPanel({
    required this.setsController,
    required this.repsController,
    required this.workController,
    required this.restController,
    required this.enabled,
    required this.onApply,
  });

  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController workController;
  final TextEditingController restController;
  final bool enabled;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: setsController,
                    label: 'Sets',
                    enabled: enabled,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: repsController,
                    label: 'Reps',
                    enabled: enabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: workController,
                    label: 'Swim sec',
                    enabled: enabled,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: restController,
                    label: 'Rest sec',
                    enabled: enabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: enabled ? onApply : null,
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.enabled,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({required this.state});

  final IntervalTimerState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final phaseLabel = switch (state.phase) {
      IntervalPhase.ready => 'Ready',
      IntervalPhase.swim => 'Swim',
      IntervalPhase.rest => 'Rest',
      IntervalPhase.complete => 'Complete',
    };
    final phaseColor = switch (state.phase) {
      IntervalPhase.ready => colorScheme.secondaryContainer,
      IntervalPhase.swim => colorScheme.primaryContainer,
      IntervalPhase.rest => colorScheme.tertiaryContainer,
      IntervalPhase.complete => colorScheme.surfaceContainerHighest,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: phaseColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            phaseLabel,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            DurationUtils.formatDuration(state.remaining),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Set ${state.currentSet}/${state.sets}  Rep ${state.currentRep}/${state.reps}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
