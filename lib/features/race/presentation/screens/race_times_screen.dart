import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/duration_utils.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../domain/entities/race_time.dart';
import '../../domain/services/race_time_service.dart';
import '../providers/race_time_providers.dart';

class RaceTimesScreen extends ConsumerStatefulWidget {
  const RaceTimesScreen({super.key});

  @override
  ConsumerState<RaceTimesScreen> createState() => _RaceTimesScreenState();
}

class _RaceTimesScreenState extends ConsumerState<RaceTimesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int? _distance;
  RaceCourse? _course;
  RaceTimeSort _sort = RaceTimeSort.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showRaceDialog({RaceTime? raceTime}) async {
    final profile = ref.read(currentProfileProvider);
    final result = await showDialog<RaceTimeFormResult>(
      context: context,
      builder: (_) => RaceTimeFormDialog(
        profileName: profile.displayName,
        raceTime: raceTime,
      ),
    );
    if (result == null) return;

    if (raceTime == null) {
      await ref.read(raceTimesProvider.notifier).addRaceTime(
            raceName: result.raceName,
            eventDate: result.eventDate,
            distance: result.distance,
            stroke: result.stroke,
            course: result.course,
            time: result.time,
            notes: result.notes,
            placement: result.placement,
            location: result.location,
          );
    } else {
      await ref.read(raceTimesProvider.notifier).updateRaceTime(
            raceTime.copyWith(
              raceName: result.raceName,
              eventDate: result.eventDate,
              distance: result.distance,
              stroke: result.stroke,
              course: result.course,
              time: result.time,
              notes: result.notes,
              clearNotes: result.notes == null,
              placement: result.placement,
              clearPlacement: result.placement == null,
              location: result.location,
              clearLocation: result.location == null,
            ),
          );
    }
  }

  Future<void> _deleteRaceTime(RaceTime raceTime) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete race time?'),
        content: Text('Delete ${raceTime.raceName} ${raceTime.distance}m?'),
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
    await ref.read(raceTimesProvider.notifier).deleteRaceTime(raceTime.id);
  }

  @override
  Widget build(BuildContext context) {
    final raceTimesAsync = ref.watch(raceTimesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Race Times')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRaceDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Race'),
      ),
      body: raceTimesAsync.when(
        data: (raceTimes) {
          final filtered = filterRaceTimes(
            raceTimes,
            query: _query,
            distance: _distance,
            course: _course,
            sort: _sort,
          );
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _RaceFilters(
                    searchController: _searchController,
                    onQueryChanged: (value) => setState(() => _query = value),
                    distance: _distance,
                    onDistanceChanged: (value) =>
                        setState(() => _distance = value),
                    course: _course,
                    onCourseChanged: (value) => setState(() => _course = value),
                    sort: _sort,
                    onSortChanged: (value) => setState(() => _sort = value),
                  ),
                  const SizedBox(height: 12),
                  _RaceSummary(
                    visibleCount: filtered.length,
                    totalCount: raceTimes.length,
                    raceTimes: filtered,
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    const _EmptyRaceTimes()
                  else if (isWide)
                    _RaceTimesTable(
                      raceTimes: filtered,
                      onEdit: (raceTime) => _showRaceDialog(raceTime: raceTime),
                      onDelete: _deleteRaceTime,
                    )
                  else
                    for (final raceTime in filtered)
                      _RaceTimeCard(
                        raceTime: raceTime,
                        onEdit: () => _showRaceDialog(raceTime: raceTime),
                        onDelete: () => _deleteRaceTime(raceTime),
                      ),
                ],
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _RaceFilters extends StatelessWidget {
  const _RaceFilters({
    required this.searchController,
    required this.onQueryChanged,
    required this.distance,
    required this.onDistanceChanged,
    required this.course,
    required this.onCourseChanged,
    required this.sort,
    required this.onSortChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final int? distance;
  final ValueChanged<int?> onDistanceChanged;
  final RaceCourse? course;
  final ValueChanged<RaceCourse?> onCourseChanged;
  final RaceTimeSort sort;
  final ValueChanged<RaceTimeSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search race times',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: onQueryChanged,
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<int?>(
            isExpanded: true,
            initialValue: distance,
            decoration: const InputDecoration(
              labelText: 'Distance',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All'),
              ),
              for (final distance in kStandardDistances)
                DropdownMenuItem<int?>(
                  value: distance,
                  child: Text('${distance}m'),
                ),
            ],
            onChanged: onDistanceChanged,
          ),
        ),
        SizedBox(
          width: 230,
          child: DropdownButtonFormField<RaceCourse?>(
            isExpanded: true,
            initialValue: course,
            decoration: const InputDecoration(
              labelText: 'Course',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<RaceCourse?>(
                value: null,
                child: Text('All courses'),
              ),
              for (final course in RaceCourse.values)
                DropdownMenuItem<RaceCourse?>(
                  value: course,
                  child: Text(
                    course.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: onCourseChanged,
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<RaceTimeSort>(
            isExpanded: true,
            initialValue: sort,
            decoration: const InputDecoration(
              labelText: 'Sort',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: RaceTimeSort.newest,
                child: Text('Newest'),
              ),
              DropdownMenuItem(
                value: RaceTimeSort.oldest,
                child: Text('Oldest'),
              ),
              DropdownMenuItem(
                value: RaceTimeSort.fastest,
                child: Text('Fastest'),
              ),
              DropdownMenuItem(
                value: RaceTimeSort.distance,
                child: Text('Distance'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onSortChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _RaceSummary extends StatelessWidget {
  const _RaceSummary({
    required this.visibleCount,
    required this.totalCount,
    required this.raceTimes,
  });

  final int visibleCount;
  final int totalCount;
  final List<RaceTime> raceTimes;

  @override
  Widget build(BuildContext context) {
    final best = bestRaceTimesByEventCourse(raceTimes).length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(label: Text('$visibleCount of $totalCount race times')),
        Chip(label: Text('$best course-specific bests')),
      ],
    );
  }
}

class _RaceTimeCard extends StatelessWidget {
  const _RaceTimeCard({
    required this.raceTime,
    required this.onEdit,
    required this.onDelete,
  });

  final RaceTime raceTime;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy').format(raceTime.eventDate);
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(raceTime.course.code)),
        title: Text('${raceTime.distance}m ${raceTime.stroke}'),
        subtitle:
            Text('${raceTime.raceName} - ${raceTime.course.label}\n$date'),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              DurationUtils.formatDurationWithCentiseconds(raceTime.time),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              tooltip: 'Edit race time',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Delete race time',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _RaceTimesTable extends StatelessWidget {
  const _RaceTimesTable({
    required this.raceTimes,
    required this.onEdit,
    required this.onDelete,
  });

  final List<RaceTime> raceTimes;
  final ValueChanged<RaceTime> onEdit;
  final ValueChanged<RaceTime> onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Race')),
          DataColumn(label: Text('Event')),
          DataColumn(label: Text('Course')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Place')),
          DataColumn(label: Text('Actions')),
        ],
        rows: [
          for (final raceTime in raceTimes)
            DataRow(
              cells: [
                DataCell(
                    Text(DateFormat('d MMM yyyy').format(raceTime.eventDate))),
                DataCell(Text(raceTime.raceName)),
                DataCell(Text('${raceTime.distance}m ${raceTime.stroke}')),
                DataCell(Text(raceTime.course.code)),
                DataCell(Text(DurationUtils.formatDurationWithCentiseconds(
                  raceTime.time,
                ))),
                DataCell(Text(raceTime.placement?.toString() ?? '-')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit race time',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(raceTime),
                      ),
                      IconButton(
                        tooltip: 'Delete race time',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDelete(raceTime),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyRaceTimes extends StatelessWidget {
  const _EmptyRaceTimes();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.flag_outlined, size: 56),
            SizedBox(height: 12),
            Text('No race times match your filters'),
          ],
        ),
      ),
    );
  }
}

class RaceTimeFormResult {
  const RaceTimeFormResult({
    required this.raceName,
    required this.eventDate,
    required this.distance,
    required this.stroke,
    required this.course,
    required this.time,
    this.notes,
    this.placement,
    this.location,
  });

  final String raceName;
  final DateTime eventDate;
  final int distance;
  final String stroke;
  final RaceCourse course;
  final Duration time;
  final String? notes;
  final int? placement;
  final String? location;
}

class RaceTimeFormDialog extends StatefulWidget {
  const RaceTimeFormDialog({
    super.key,
    required this.profileName,
    this.raceTime,
  });

  final String profileName;
  final RaceTime? raceTime;

  @override
  State<RaceTimeFormDialog> createState() => _RaceTimeFormDialogState();
}

class _RaceTimeFormDialogState extends State<RaceTimeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _raceNameController;
  late final TextEditingController _distanceController;
  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;
  late final TextEditingController _centisecondsController;
  late final TextEditingController _placementController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  late DateTime _eventDate;
  late String _stroke;
  late RaceCourse _course;

  @override
  void initState() {
    super.initState();
    final raceTime = widget.raceTime;
    _eventDate = raceTime?.eventDate ?? DateTime.now();
    _stroke = raceTime?.stroke ?? kStrokes.first;
    _course = raceTime?.course ?? RaceCourse.shortCourseMeters;
    _raceNameController = TextEditingController(text: raceTime?.raceName ?? '');
    _distanceController =
        TextEditingController(text: raceTime?.distance.toString() ?? '100');
    _minutesController = TextEditingController(
      text: raceTime == null
          ? ''
          : raceTime.time.inMinutes.remainder(60).toString(),
    );
    _secondsController = TextEditingController(
      text: raceTime == null
          ? ''
          : raceTime.time.inSeconds.remainder(60).toString(),
    );
    _centisecondsController = TextEditingController(
      text: raceTime == null
          ? ''
          : (raceTime.time.inMilliseconds.remainder(1000) ~/ 10).toString(),
    );
    _placementController =
        TextEditingController(text: raceTime?.placement?.toString() ?? '');
    _locationController = TextEditingController(text: raceTime?.location ?? '');
    _notesController = TextEditingController(text: raceTime?.notes ?? '');
  }

  @override
  void dispose() {
    _raceNameController.dispose();
    _distanceController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _centisecondsController.dispose();
    _placementController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(_eventDate.year - 10),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Duration _enteredTime() {
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    final centiseconds = int.tryParse(_centisecondsController.text) ?? 0;
    return Duration(
      minutes: minutes,
      seconds: seconds,
      milliseconds: centiseconds * 10,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final placement = _placementController.text.trim().isEmpty
        ? null
        : int.parse(_placementController.text);
    Navigator.of(context).pop(
      RaceTimeFormResult(
        raceName: _raceNameController.text.trim(),
        eventDate: _eventDate,
        distance: int.parse(_distanceController.text),
        stroke: _stroke,
        course: _course,
        time: _enteredTime(),
        placement: placement,
        location: _cleanFormText(_locationController.text),
        notes: _cleanFormText(_notesController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.raceTime != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit race time' : 'Add race time'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.person_outline, size: 16),
                    label: Text(widget.profileName),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _raceNameController,
                  decoration: const InputDecoration(labelText: 'Race or meet'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Event date'),
                  subtitle: Text(DateFormat('d MMM yyyy').format(_eventDate)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _distanceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Distance (m)',
                        ),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter distance';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _stroke,
                        decoration: const InputDecoration(labelText: 'Stroke'),
                        items: [
                          for (final stroke in kStrokes)
                            DropdownMenuItem(
                              value: stroke,
                              child: Text(
                                stroke,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _stroke = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RaceCourse>(
                  isExpanded: true,
                  initialValue: _course,
                  decoration: const InputDecoration(labelText: 'Course type'),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min'),
                        validator: _timePartValidator,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _secondsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sec'),
                        validator: (value) {
                          final partError = _timePartValidator(value);
                          if (partError != null) return partError;
                          final parsed = int.tryParse(value ?? '') ?? 0;
                          if (parsed > 59) return '0-59';
                          if (_enteredTime() == Duration.zero) {
                            return 'Enter time';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _centisecondsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Csec'),
                        validator: (value) {
                          final partError = _timePartValidator(value);
                          if (partError != null) return partError;
                          final parsed = int.tryParse(value ?? '') ?? 0;
                          if (parsed > 99) return '0-99';
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
                      child: TextFormField(
                        controller: _placementController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Place'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final parsed = int.tryParse(value);
                          if (parsed == null || parsed <= 0) {
                            return 'Enter place';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration:
                            const InputDecoration(labelText: 'Location'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
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

String? _timePartValidator(String? value) {
  final raw = value ?? '';
  if (raw.isEmpty) return null;
  final parsed = int.tryParse(raw);
  if (parsed == null || parsed < 0) return '>= 0';
  return null;
}

String? _cleanFormText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
