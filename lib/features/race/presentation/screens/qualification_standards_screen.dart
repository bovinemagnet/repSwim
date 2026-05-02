import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/duration_utils.dart';
import '../../data/qualification_sources/victorian_metro_sc_2026.dart';
import '../../domain/entities/meet_qualification_standard.dart';
import '../../domain/entities/qualification_standard.dart';
import '../../domain/entities/race_time.dart';
import '../../domain/services/qualification_standard_service.dart';
import '../providers/qualification_standard_providers.dart';

class QualificationStandardsScreen extends ConsumerWidget {
  const QualificationStandardsScreen({super.key});

  Future<void> _showDialog(
    BuildContext context,
    WidgetRef ref, {
    QualificationStandard? standard,
  }) async {
    final result = await showDialog<QualificationStandardFormResult>(
      context: context,
      builder: (_) => QualificationStandardFormDialog(standard: standard),
    );
    if (result == null) return;

    if (standard == null) {
      await ref.read(qualificationStandardsProvider.notifier).addStandard(
            age: result.age,
            distance: result.distance,
            stroke: result.stroke,
            course: result.course,
            goldTime: result.goldTime,
            silverTime: result.silverTime,
            bronzeTime: result.bronzeTime,
          );
      return;
    }

    await ref.read(qualificationStandardsProvider.notifier).updateStandard(
          standard.copyWith(
            age: result.age,
            distance: result.distance,
            stroke: result.stroke,
            course: result.course,
            goldTime: result.goldTime,
            silverTime: result.silverTime,
            bronzeTime: result.bronzeTime,
          ),
        );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    QualificationStandard standard,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete qualification standard?'),
        content: Text('Delete age ${standard.age} ${standard.distance}m '
            '${standard.stroke} standard?'),
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
        .read(qualificationStandardsProvider.notifier)
        .deleteStandard(standard.id);
  }

  Future<void> _importVictorianMetroSc2026(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final count = await ref
          .read(meetQualificationStandardsProvider.notifier)
          .importVictorianMetroSc2026();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported $count standards from $victorianMetroSc2026SourceName.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standardsAsync = ref.watch(qualificationStandardsProvider);
    final meetStandardsAsync = ref.watch(meetQualificationStandardsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qualification Standards'),
        actions: [
          IconButton(
            tooltip: 'Import Victorian Metro SC standards',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => _importVictorianMetroSc2026(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Standard'),
      ),
      body: standardsAsync.when(
        data: (standards) {
          return meetStandardsAsync.when(
            data: (meetStandards) {
              if (standards.isEmpty && meetStandards.isEmpty) {
                return const Center(
                  child: Text('No qualification standards configured.'),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  if (standards.isNotEmpty) ...[
                    const _SectionHeader(title: 'Manual medal standards'),
                    for (final standard in standards)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _QualificationStandardCard(
                          standard: standard,
                          onEdit: () =>
                              _showDialog(context, ref, standard: standard),
                          onDelete: () => _delete(context, ref, standard),
                        ),
                      ),
                  ],
                  if (meetStandards.isNotEmpty) ...[
                    const _SectionHeader(title: 'Imported meet standards'),
                    for (final standard in meetStandards)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MeetQualificationStandardCard(
                          standard: standard,
                        ),
                      ),
                  ],
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator.adaptive()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _QualificationStandardCard extends StatelessWidget {
  const _QualificationStandardCard({
    required this.standard,
    required this.onEdit,
    required this.onDelete,
  });

  final QualificationStandard standard;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(standard.age.toString())),
        title: Text('Age ${standard.age} - '
            '${standard.distance}m ${standard.stroke}'),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(label: Text(standard.course.code)),
            _TierChip(tier: QualificationTier.gold, time: standard.goldTime),
            _TierChip(
                tier: QualificationTier.silver, time: standard.silverTime),
            _TierChip(
                tier: QualificationTier.bronze, time: standard.bronzeTime),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Edit qualification standard',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Delete qualification standard',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetQualificationStandardCard extends StatelessWidget {
  const _MeetQualificationStandardCard({required this.standard});

  final MeetQualificationStandard standard;

  @override
  Widget build(BuildContext context) {
    final title = standard.isRelay
        ? standard.relayEvent ?? 'Relay'
        : '${standard.sex?.label ?? 'Open'} ${standard.distance}m '
            '${standard.stroke}';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            standard.isRelay
                ? Icons.groups_outlined
                : Icons.workspace_premium_outlined,
          ),
        ),
        title: Text(title),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(label: Text(standard.ageGroupLabel)),
            Chip(label: Text(standard.course.code)),
            if (standard.qualifyingTime != null)
              Chip(
                label: Text(
                  DurationUtils.formatDurationWithCentiseconds(
                    standard.qualifyingTime!,
                  ),
                ),
              )
            else if (standard.mcPoints != null)
              Chip(label: Text('${standard.mcPoints} MC points'))
            else
              const Chip(label: Text('No qualifying time')),
          ],
        ),
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.tier, required this.time});

  final QualificationTier tier;
  final Duration time;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '${tier.label}: ${DurationUtils.formatDurationWithCentiseconds(time)}',
      ),
    );
  }
}

class QualificationStandardFormResult {
  const QualificationStandardFormResult({
    required this.age,
    required this.distance,
    required this.stroke,
    required this.course,
    required this.goldTime,
    required this.silverTime,
    required this.bronzeTime,
  });

  final int age;
  final int distance;
  final String stroke;
  final RaceCourse course;
  final Duration goldTime;
  final Duration silverTime;
  final Duration bronzeTime;
}

class QualificationStandardFormDialog extends StatefulWidget {
  const QualificationStandardFormDialog({super.key, this.standard});

  final QualificationStandard? standard;

  @override
  State<QualificationStandardFormDialog> createState() =>
      _QualificationStandardFormDialogState();
}

class _QualificationStandardFormDialogState
    extends State<QualificationStandardFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _distanceController;
  late final TextEditingController _goldController;
  late final TextEditingController _silverController;
  late final TextEditingController _bronzeController;
  late String _stroke;
  late RaceCourse _course;

  @override
  void initState() {
    super.initState();
    final standard = widget.standard;
    _ageController =
        TextEditingController(text: standard?.age.toString() ?? '12');
    _distanceController =
        TextEditingController(text: standard?.distance.toString() ?? '100');
    _goldController = TextEditingController(
      text: _formatCentisecondsForInput(standard?.goldTime),
    );
    _silverController = TextEditingController(
      text: _formatCentisecondsForInput(standard?.silverTime),
    );
    _bronzeController = TextEditingController(
      text: _formatCentisecondsForInput(standard?.bronzeTime),
    );
    _stroke = standard?.stroke ?? kStrokes.first;
    _course = standard?.course ?? RaceCourse.shortCourseMeters;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _distanceController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    _bronzeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final result = QualificationStandardFormResult(
      age: int.parse(_ageController.text),
      distance: int.parse(_distanceController.text),
      stroke: _stroke,
      course: _course,
      goldTime: _parseCentiseconds(_goldController.text),
      silverTime: _parseCentiseconds(_silverController.text),
      bronzeTime: _parseCentiseconds(_bronzeController.text),
    );
    final standard = QualificationStandard(
      id: widget.standard?.id ?? 'draft',
      profileId: widget.standard?.profileId ?? 'draft',
      age: result.age,
      distance: result.distance,
      stroke: result.stroke,
      course: result.course,
      goldTime: result.goldTime,
      silverTime: result.silverTime,
      bronzeTime: result.bronzeTime,
      createdAt: widget.standard?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (!hasValidQualificationOrder(standard)) {
      setState(() {});
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.standard != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit standard' : 'Add standard'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age'),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed < 1 || parsed > 120) {
                            return 'Enter age';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _distanceController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Distance (m)'),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter distance';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _stroke,
                        decoration: const InputDecoration(labelText: 'Stroke'),
                        items: [
                          for (final stroke in kStrokes)
                            DropdownMenuItem(
                                value: stroke, child: Text(stroke)),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _stroke = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<RaceCourse>(
                        isExpanded: true,
                        initialValue: _course,
                        decoration: const InputDecoration(labelText: 'Course'),
                        items: [
                          for (final course in RaceCourse.values)
                            DropdownMenuItem(
                              value: course,
                              child: Text(
                                course.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _course = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _goldController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Gold time (csec)'),
                  validator: _timeValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _silverController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Silver time (csec)'),
                  validator: _timeValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bronzeController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Bronze time (csec)'),
                  validator: (value) {
                    final error = _timeValidator(value);
                    if (error != null) return error;
                    final gold = int.tryParse(_goldController.text) ?? 0;
                    final silver = int.tryParse(_silverController.text) ?? 0;
                    final bronze = int.tryParse(_bronzeController.text) ?? 0;
                    if (gold > silver || silver > bronze) {
                      return 'Gold must be fastest';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

String? _timeValidator(String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed <= 0) return 'Enter csec';
  return null;
}

Duration _parseCentiseconds(String value) {
  return Duration(milliseconds: int.parse(value) * 10);
}

String _formatCentisecondsForInput(Duration? value) {
  if (value == null) return '';
  return (value.inMilliseconds ~/ 10).toString();
}
