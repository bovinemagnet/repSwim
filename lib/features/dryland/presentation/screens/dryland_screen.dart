import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/dryland_providers.dart';
import '../../domain/entities/dryland_workout.dart';
import '../../domain/entities/exercise.dart';

const _uuid = Uuid();

class DrylandScreen extends ConsumerWidget {
  const DrylandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(drylandWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dryland Workouts')),
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
            itemBuilder: (context, i) => _WorkoutCard(workout: workouts[i]),
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
        onSave: (workout) =>
            ref.read(drylandWorkoutsProvider.notifier).addWorkout(workout),
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

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.workout});

  final DrylandWorkout workout;

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
        title: Text(dateStr,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${workout.exercises.length} exercise${workout.exercises.length == 1 ? '' : 's'}'),
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
  const _AddWorkoutSheet({required this.onSave});

  final Future<void> Function(DrylandWorkout) onSave;

  @override
  State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  final _exercises = <_ExerciseEntry>[];
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
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
      final workoutId = _uuid.v4();
      final exercises = _exercises
          .map((e) => Exercise(
                id: _uuid.v4(),
                workoutId: workoutId,
                name: e.nameController.text.trim(),
                sets: int.parse(e.setsController.text),
                reps: int.parse(e.repsController.text),
                weight: double.tryParse(e.weightController.text),
              ))
          .toList();

      final workout = DrylandWorkout(
        id: workoutId,
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
                title: const Text('New Workout'),
                automaticallyImplyLeading: false,
                actions: [
                  if (_saving)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2),
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
                        title: Text(
                            DateFormat('EEEE, d MMM yyyy').format(_date)),
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
                            onPressed: () =>
                                setState(() => _exercises.add(_ExerciseEntry())),
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
                    onRemove: () =>
                        setState(() => _exercises.removeAt(i)),
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
  final nameController = TextEditingController();
  final setsController = TextEditingController(text: '3');
  final repsController = TextEditingController(text: '10');
  final weightController = TextEditingController();

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
                    validator: (v) =>
                        int.tryParse(v ?? '') == null ? 'Required' : null,
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
                    validator: (v) =>
                        int.tryParse(v ?? '') == null ? 'Required' : null,
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
