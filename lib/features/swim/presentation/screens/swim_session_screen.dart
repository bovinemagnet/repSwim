import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/swim_session.dart';
import '../../domain/entities/lap.dart';
import '../../presentation/providers/swim_providers.dart';
import '../../../pb/presentation/providers/pb_providers.dart';
import '../../../pb/domain/services/pb_service.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/duration_utils.dart';

const _uuid = Uuid();

class SwimSessionScreen extends ConsumerStatefulWidget {
  const SwimSessionScreen({
    super.key,
    this.initialSession,
  });

  final SwimSession? initialSession;

  @override
  ConsumerState<SwimSessionScreen> createState() => _SwimSessionScreenState();
}

class SwimSessionEditorScreen extends ConsumerWidget {
  const SwimSessionEditorScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(swimSessionsProvider);
    return sessionsAsync.when(
      data: (sessions) {
        final matches = sessions.where((session) => session.id == sessionId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Swim Session')),
            body: const Center(child: Text('Session not found')),
          );
        }
        return SwimSessionScreen(initialSession: matches.first);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit Swim Session')),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit Swim Session')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _SwimSessionScreenState extends ConsumerState<SwimSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _stroke = kStrokes.first;
  final _notesController = TextEditingController();
  final _laps = <_LapEntry>[];
  bool _saving = false;
  late DateTime _sessionDate;
  bool get _isEditing => widget.initialSession != null;

  @override
  void initState() {
    super.initState();
    final session = widget.initialSession;
    _sessionDate = session?.date ?? DateTime.now();
    if (session != null) {
      _stroke = session.stroke;
      _notesController.text = session.notes ?? '';
      _laps.addAll(
        session.laps.map(
          (lap) => _LapEntry(
            id: lap.id,
            distance: lap.distance,
            duration: lap.time,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _totalDistance => _laps.fold(0, (sum, l) => sum + (l.distance ?? 0));

  Duration get _totalTime => _laps.fold(
      Duration.zero, (sum, l) => sum + (l.duration ?? Duration.zero));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_laps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one lap.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final sessionId = widget.initialSession?.id ?? _uuid.v4();
      final profileId = ref.read(currentProfileIdProvider);
      final laps = _laps
          .asMap()
          .entries
          .map(
            (e) => Lap(
              id: e.value.id ?? _uuid.v4(),
              sessionId: sessionId,
              profileId: profileId,
              distance: e.value.distance!,
              time: e.value.duration!,
              lapNumber: e.key + 1,
            ),
          )
          .toList();

      final session = SwimSession(
        id: sessionId,
        profileId: profileId,
        date: _sessionDate,
        totalDistance: _totalDistance,
        totalTime: _totalTime,
        stroke: _stroke,
        laps: laps,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_isEditing) {
        await ref.read(swimSessionsProvider.notifier).updateSession(session);
      } else {
        await ref.read(swimSessionsProvider.notifier).addSession(session);
      }

      final sessions =
          ref.read(swimSessionsProvider).valueOrNull ?? const <SwimSession>[];
      final rebuiltPbs = PbService.rebuildFromSessions(sessions);
      await ref.read(personalBestsProvider.notifier).replaceAll(rebuiltPbs);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isEditing ? 'Session updated!' : 'Session saved!')),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(_sessionDate.year - 10),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_sessionDate),
    );
    if (time == null) return;
    setState(() {
      _sessionDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _addLap() {
    final poolLength =
        ref.read(currentProfileProvider).preferredPoolLengthMeters;
    setState(() => _laps.add(_LapEntry(distance: poolLength)));
  }

  void _removeLap(int index) {
    setState(() => _laps.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Swim Session' : 'New Swim Session'),
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
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stroke selector
                    DropdownButtonFormField<String>(
                      initialValue: _stroke,
                      decoration: const InputDecoration(
                        labelText: 'Stroke',
                        prefixIcon: Icon(Icons.waves),
                      ),
                      items: kStrokes
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _stroke = v!),
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Date and time'),
                      subtitle: Text(
                        DateFormat('EEE, d MMM yyyy h:mm a')
                            .format(_sessionDate),
                      ),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: _pickDateTime,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Totals
                    if (_laps.isNotEmpty)
                      _TotalsBanner(
                        totalDistance: _totalDistance,
                        totalTime: _totalTime,
                      ),

                    // Laps header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Laps (${_laps.length})',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _addLap,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Lap'),
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
                itemCount: _laps.length,
                itemBuilder: (context, i) => _LapCard(
                  key: ValueKey(i),
                  lapNumber: i + 1,
                  entry: _laps[i],
                  onRemove: () => _removeLap(i),
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _LapEntry {
  _LapEntry({this.id, this.distance, this.duration});

  String? id;
  int? distance;
  Duration? duration;
}

class _TotalsBanner extends StatelessWidget {
  const _TotalsBanner({
    required this.totalDistance,
    required this.totalTime,
  });

  final int totalDistance;
  final Duration totalTime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TotalItem(
            label: 'Distance',
            value: '${totalDistance}m',
            icon: Icons.straighten,
          ),
          _TotalItem(
            label: 'Time',
            value: DurationUtils.formatDuration(totalTime),
            icon: Icons.timer_outlined,
          ),
          _TotalItem(
            label: 'Pace',
            value: DurationUtils.formatPace(totalTime, totalDistance),
            icon: Icons.speed,
          ),
        ],
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  const _TotalItem(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSecondaryContainer),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                )),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                )),
      ],
    );
  }
}

class _LapCard extends StatefulWidget {
  const _LapCard({
    super.key,
    required this.lapNumber,
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });

  final int lapNumber;
  final _LapEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<_LapCard> createState() => _LapCardState();
}

class _LapCardState extends State<_LapCard> {
  late final TextEditingController _distController;
  late final TextEditingController _minController;
  late final TextEditingController _secController;

  @override
  void initState() {
    super.initState();
    _distController =
        TextEditingController(text: widget.entry.distance?.toString() ?? '');
    _minController = TextEditingController(
        text: widget.entry.duration != null
            ? widget.entry.duration!.inMinutes.remainder(60).toString()
            : '');
    _secController = TextEditingController(
        text: widget.entry.duration != null
            ? widget.entry.duration!.inSeconds.remainder(60).toString()
            : '');
  }

  @override
  void dispose() {
    _distController.dispose();
    _minController.dispose();
    _secController.dispose();
    super.dispose();
  }

  void _updateEntry() {
    final dist = int.tryParse(_distController.text);
    final mins = int.tryParse(_minController.text) ?? 0;
    final secs = int.tryParse(_secController.text) ?? 0;
    widget.entry.distance = dist;
    widget.entry.duration = Duration(minutes: mins, seconds: secs);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lap ${widget.lapNumber}',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove lap',
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _distController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Distance (m)',
                      isDense: true,
                    ),
                    validator: (v) => (v == null ||
                            int.tryParse(v) == null ||
                            int.parse(v) <= 0)
                        ? 'Enter distance'
                        : null,
                    onChanged: (_) => _updateEntry(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min',
                      isDense: true,
                    ),
                    validator: (v) {
                      final raw = v ?? '';
                      final parsed = int.tryParse(raw);
                      final mins = parsed ?? 0;
                      final secs = int.tryParse(_secController.text) ?? 0;
                      if (raw.isNotEmpty && (parsed == null || mins < 0)) {
                        return '>= 0';
                      }
                      if (mins == 0 && secs == 0) {
                        return 'Enter time';
                      }
                      return null;
                    },
                    onChanged: (_) => _updateEntry(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _secController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sec',
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final val = int.tryParse(v);
                        if (val == null || val < 0 || val > 59) {
                          return '0-59';
                        }
                      }
                      return null;
                    },
                    onChanged: (_) => _updateEntry(),
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
