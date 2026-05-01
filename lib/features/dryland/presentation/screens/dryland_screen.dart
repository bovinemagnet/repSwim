import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/dryland_providers.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../../templates/domain/entities/dryland_routine_template.dart';
import '../../../templates/presentation/providers/training_template_providers.dart';
import '../../domain/entities/dryland_workout.dart';
import '../../domain/entities/exercise.dart';

const _uuid = Uuid();

class DrylandScreen extends ConsumerWidget {
  const DrylandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(drylandWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dryland Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: 'Routine templates',
            onPressed: () => _showRoutineTemplatesSheet(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWorkoutSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Workout'),
      ),
      body: workoutsAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: workouts.length,
            itemBuilder: (context, i) => _WorkoutCard(
              workout: workouts[i],
              onEdit: () => _showEditWorkoutSheet(context, ref, workouts[i]),
              onSaveTemplate: () =>
                  _showSaveRoutineTemplateDialog(context, ref, workouts[i]),
              onDelete: () => ref
                  .read(drylandWorkoutsProvider.notifier)
                  .deleteWorkout(workouts[i].id),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddWorkoutSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddWorkoutSheet(
        profileId: ref.read(currentProfileIdProvider),
        onSave: (workout) =>
            ref.read(drylandWorkoutsProvider.notifier).addWorkout(workout),
      ),
    );
  }

  void _showEditWorkoutSheet(
    BuildContext context,
    WidgetRef ref,
    DrylandWorkout workout,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddWorkoutSheet(
        profileId: ref.read(currentProfileIdProvider),
        initialWorkout: workout,
        onSave: (updatedWorkout) => ref
            .read(drylandWorkoutsProvider.notifier)
            .updateWorkout(updatedWorkout),
      ),
    );
  }

  Future<void> _showSaveRoutineTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    DrylandWorkout workout,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save routine template'),
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
    if (name == null || name.trim().isEmpty) return;

    final template = await ref
        .read(drylandRoutineTemplatesProvider.notifier)
        .saveFromWorkout(name, workout);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${template.name}.')),
    );
  }

  void _showRoutineTemplatesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _RoutineTemplatesSheet(
        profileId: ref.read(currentProfileIdProvider),
        onUseTemplate: (template) async {
          final workoutId = _uuid.v4();
          final workout = DrylandWorkout(
            id: workoutId,
            profileId: ref.read(currentProfileIdProvider),
            date: DateTime.now(),
            notes: template.notes,
            exercises: [
              for (final exercise in template.exercises)
                Exercise(
                  id: _uuid.v4(),
                  workoutId: workoutId,
                  profileId: ref.read(currentProfileIdProvider),
                  name: exercise.name,
                  sets: exercise.sets,
                  reps: exercise.reps,
                  weight: exercise.weight,
                ),
            ],
          );
          await ref.read(drylandWorkoutsProvider.notifier).addWorkout(workout);
        },
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
          Icon(Icons.fitness_center, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No dryland workouts yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text(
            'Tap the button below to add your first workout.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _RoutineTemplatesSheet extends ConsumerWidget {
  const _RoutineTemplatesSheet({
    required this.profileId,
    required this.onUseTemplate,
  });

  final String profileId;
  final Future<void> Function(DrylandRoutineTemplate) onUseTemplate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(drylandRoutineTemplatesProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return templatesAsync.when(
          data: (templates) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Row(
                children: [
                  Text(
                    'Routine Templates',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (templates.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text('Save a dryland workout as a routine first.'),
                  ),
                )
              else
                for (final template in templates)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.bookmarks_outlined),
                      title: Text(template.name),
                      subtitle: Text(
                        '${template.exercises.length} exercise'
                        '${template.exercises.length == 1 ? '' : 's'}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.playlist_add),
                            tooltip: 'Use routine',
                            onPressed: () async {
                              await onUseTemplate(template);
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Created ${template.name} workout.'),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete routine',
                            onPressed: () => ref
                                .read(drylandRoutineTemplatesProvider.notifier)
                                .deleteTemplate(template.id),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.workout,
    required this.onEdit,
    required this.onSaveTemplate,
    required this.onDelete,
  });

  final DrylandWorkout workout;
  final VoidCallback onEdit;
  final VoidCallback onSaveTemplate;
  final Future<void> Function() onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete workout?'),
        content: const Text('This removes the workout and its exercises.'),
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
    await onDelete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('EEE, d MMM yyyy').format(workout.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(Icons.fitness_center,
              color: colorScheme.onSecondaryContainer, size: 20),
        ),
        title:
            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${workout.exercises.length} exercise${workout.exercises.length == 1 ? '' : 's'}'),
        trailing: PopupMenuButton<String>(
          tooltip: 'Workout actions',
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'template':
                onSaveTemplate();
              case 'delete':
                _confirmDelete(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit'),
              ),
            ),
            PopupMenuItem(
              value: 'template',
              child: ListTile(
                leading: Icon(Icons.bookmark_add_outlined),
                title: Text('Save as routine'),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (workout.notes != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(workout.notes!,
                  style: TextStyle(color: colorScheme.outline)),
            ),
          if (workout.notes != null) const SizedBox(height: 8),
          ...workout.exercises.map((e) => _ExerciseRow(exercise: e)),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final weight = exercise.weight != null
        ? ' · ${exercise.weight!.toStringAsFixed(exercise.weight! % 1 == 0 ? 0 : 1)}kg'
        : '';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.chevron_right, size: 18),
      title: Text(exercise.name),
      trailing: Text(
        '${exercise.sets}×${exercise.reps}$weight',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Add workout bottom sheet ────────────────────────────────────────────────

class _AddWorkoutSheet extends StatefulWidget {
  const _AddWorkoutSheet({
    required this.onSave,
    required this.profileId,
    this.initialWorkout,
  });

  final Future<void> Function(DrylandWorkout) onSave;
  final String profileId;
  final DrylandWorkout? initialWorkout;

  @override
  State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notesController;
  late DateTime _date;
  final _exercises = <_ExerciseEntry>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final workout = widget.initialWorkout;
    _date = workout?.date ?? DateTime.now();
    _notesController = TextEditingController(text: workout?.notes ?? '');
    if (workout != null) {
      _exercises.addAll(workout.exercises.map(_ExerciseEntry.fromExercise));
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final workoutId = widget.initialWorkout?.id ?? _uuid.v4();
      final exercises = _exercises
          .map((e) => Exercise(
                id: e.id ?? _uuid.v4(),
                workoutId: workoutId,
                profileId: widget.profileId,
                name: e.nameController.text.trim(),
                sets: int.parse(e.setsController.text),
                reps: int.parse(e.repsController.text),
                weight: double.tryParse(e.weightController.text),
              ))
          .toList();

      final workout = DrylandWorkout(
        id: workoutId,
        profileId: widget.profileId,
        date: _date,
        exercises: exercises,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await widget.onSave(workout);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Form(
          key: _formKey,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(
                  widget.initialWorkout == null
                      ? 'New Workout'
                      : 'Edit Workout',
                ),
                automaticallyImplyLeading: false,
                actions: [
                  if (_saving)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator.adaptive(strokeWidth: 2),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Date picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title:
                            Text(DateFormat('EEEE, d MMM yyyy').format(_date)),
                        trailing: const Icon(Icons.edit_calendar),
                        onTap: _pickDate,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Exercises (${_exercises.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => setState(
                                () => _exercises.add(_ExerciseEntry())),
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: _exercises.length,
                  itemBuilder: (context, i) => _ExerciseFormCard(
                    key: ValueKey(i),
                    index: i,
                    entry: _exercises[i],
                    onRemove: () => setState(() {
                      final removed = _exercises.removeAt(i);
                      removed.dispose();
                    }),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseEntry {
  _ExerciseEntry({
    this.id,
    String name = '',
    String sets = '3',
    String reps = '10',
    String weight = '',
  })  : nameController = TextEditingController(text: name),
        setsController = TextEditingController(text: sets),
        repsController = TextEditingController(text: reps),
        weightController = TextEditingController(text: weight);

  factory _ExerciseEntry.fromExercise(Exercise exercise) {
    final weight = exercise.weight == null
        ? ''
        : exercise.weight!.toStringAsFixed(exercise.weight! % 1 == 0 ? 0 : 1);
    return _ExerciseEntry(
      id: exercise.id,
      name: exercise.name,
      sets: exercise.sets.toString(),
      reps: exercise.reps.toString(),
      weight: weight,
    );
  }

  final String? id;
  final TextEditingController nameController;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;

  void dispose() {
    nameController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
  }
}

class _ExerciseFormCard extends StatelessWidget {
  const _ExerciseFormCard({
    super.key,
    required this.index,
    required this.entry,
    required this.onRemove,
  });

  final int index;
  final _ExerciseEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Exercise ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            TextFormField(
              controller: entry.nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise name',
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sets',
                      isDense: true,
                    ),
                    validator: (v) {
                      final value = int.tryParse(v ?? '');
                      return value == null || value <= 0 ? 'Required' : null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: entry.repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      isDense: true,
                    ),
                    validator: (v) {
                      final value = int.tryParse(v ?? '');
                      return value == null || value <= 0 ? 'Required' : null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: entry.weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
