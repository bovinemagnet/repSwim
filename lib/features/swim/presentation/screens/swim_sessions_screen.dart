import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/duration_utils.dart';
import '../../domain/entities/swim_session.dart';
import '../providers/swim_providers.dart';

List<SwimSession> filterSessions(
  List<SwimSession> sessions, {
  String query = '',
  String? stroke,
  DateTimeRange? dateRange,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return sessions.where((session) {
    final matchesStroke = stroke == null || session.stroke == stroke;
    final searchable = [
      session.stroke,
      session.notes ?? '',
      DateFormat('yyyy-MM-dd').format(session.date),
    ].join(' ').toLowerCase();
    final matchesQuery =
        normalizedQuery.isEmpty || searchable.contains(normalizedQuery);
    final matchesDate = dateRange == null ||
        !_dateOnly(session.date).isBefore(_dateOnly(dateRange.start)) &&
            !_dateOnly(session.date).isAfter(_dateOnly(dateRange.end));
    return matchesStroke && matchesQuery && matchesDate;
  }).toList();
}

String sessionsToCsv(List<SwimSession> sessions) {
  final rows = [
    [
      'date',
      'stroke',
      'total_distance_meters',
      'total_time_seconds',
      'pace_per_100m',
      'laps',
      'notes',
    ],
    for (final session in sessions)
      [
        session.date.toUtc().toIso8601String(),
        session.stroke,
        session.totalDistance.toString(),
        session.totalTime.inSeconds.toString(),
        DurationUtils.formatPace(session.totalTime, session.totalDistance),
        session.laps.length.toString(),
        session.notes ?? '',
      ],
  ];
  return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _csvCell(String value) {
  final escaped = value.replaceAll('"', '""');
  if (escaped.contains(',') ||
      escaped.contains('"') ||
      escaped.contains('\n') ||
      escaped.contains('\r')) {
    return '"$escaped"';
  }
  return escaped;
}

class SwimSessionsScreen extends ConsumerStatefulWidget {
  const SwimSessionsScreen({super.key});

  @override
  ConsumerState<SwimSessionsScreen> createState() => _SwimSessionsScreenState();
}

class _SwimSessionsScreenState extends ConsumerState<SwimSessionsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _stroke;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (selected == null) return;
    setState(() => _dateRange = selected);
  }

  Future<void> _exportCsv(List<SwimSession> sessions) async {
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sessions to export.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: sessionsToCsv(sessions)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${sessions.length} sessions as CSV.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(swimSessionsProvider);
    return sessionsAsync.when(
      data: (sessions) {
        final filtered = filterSessions(
          sessions,
          query: _query,
          stroke: _stroke,
          dateRange: _dateRange,
        );
        return Scaffold(
          appBar: AppBar(
            title: const Text('Session History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share_outlined),
                tooltip: 'Export CSV',
                onPressed: () => _exportCsv(filtered),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Filters(
                    controller: _searchController,
                    queryChanged: (value) => setState(() => _query = value),
                    stroke: _stroke,
                    strokeChanged: (value) => setState(() => _stroke = value),
                    dateRange: _dateRange,
                    pickDateRange: _pickDateRange,
                    clearDateRange: () => setState(() => _dateRange = null),
                  ),
                  const SizedBox(height: 16),
                  _HistorySummary(
                    totalCount: sessions.length,
                    visibleCount: filtered.length,
                    sessions: filtered,
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    const _EmptySessions()
                  else if (isWide)
                    _DesktopSessionTable(sessions: filtered)
                  else
                    _MobileSessionList(sessions: filtered),
                ],
              );
            },
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Session History')),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Session History')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.controller,
    required this.queryChanged,
    required this.stroke,
    required this.strokeChanged,
    required this.dateRange,
    required this.pickDateRange,
    required this.clearDateRange,
  });

  final TextEditingController controller;
  final ValueChanged<String> queryChanged;
  final String? stroke;
  final ValueChanged<String?> strokeChanged;
  final DateTimeRange? dateRange;
  final VoidCallback pickDateRange;
  final VoidCallback clearDateRange;

  @override
  Widget build(BuildContext context) {
    final dateLabel = dateRange == null
        ? 'Date range'
        : '${DateFormat('d MMM').format(dateRange!.start)} - '
            '${DateFormat('d MMM').format(dateRange!.end)}';
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search sessions',
              border: OutlineInputBorder(),
            ),
            onChanged: queryChanged,
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String?>(
            initialValue: stroke,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.pool_outlined),
              labelText: 'Stroke',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All strokes'),
              ),
              for (final stroke in kStrokes)
                DropdownMenuItem<String?>(
                  value: stroke,
                  child: Text(stroke),
                ),
            ],
            onChanged: strokeChanged,
          ),
        ),
        OutlinedButton.icon(
          onPressed: pickDateRange,
          icon: const Icon(Icons.date_range),
          label: Text(dateLabel),
        ),
        if (dateRange != null)
          IconButton(
            tooltip: 'Clear date range',
            onPressed: clearDateRange,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.totalCount,
    required this.visibleCount,
    required this.sessions,
  });

  final int totalCount;
  final int visibleCount;
  final List<SwimSession> sessions;

  @override
  Widget build(BuildContext context) {
    final distance = sessions.fold<int>(
      0,
      (total, session) => total + session.totalDistance,
    );
    final time = sessions.fold<Duration>(
      Duration.zero,
      (total, session) => total + session.totalTime,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(label: '$visibleCount of $totalCount sessions'),
        _SummaryChip(label: '${distance}m'),
        _SummaryChip(label: DurationUtils.formatDuration(time)),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.insights_outlined, size: 16),
    );
  }
}

class _MobileSessionList extends StatelessWidget {
  const _MobileSessionList({required this.sessions});

  final List<SwimSession> sessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final session in sessions) _SessionCard(session: session),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final SwimSession session;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, d MMM yyyy').format(session.date);
    return Card(
      child: ListTile(
        onTap: () => context.push('/sessions/${session.id}'),
        leading: const Icon(Icons.pool_outlined),
        title: Text('${session.totalDistance}m ${session.stroke}'),
        subtitle: Text(
          '$date - ${DurationUtils.formatDuration(session.totalTime)}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _DesktopSessionTable extends StatelessWidget {
  const _DesktopSessionTable({required this.sessions});

  final List<SwimSession> sessions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Stroke')),
          DataColumn(label: Text('Distance')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Pace')),
          DataColumn(label: Text('Laps')),
          DataColumn(label: Text('Notes')),
        ],
        rows: [
          for (final session in sessions)
            DataRow(
              onSelectChanged: (_) => context.push('/sessions/${session.id}'),
              cells: [
                DataCell(Text(DateFormat('d MMM yyyy').format(session.date))),
                DataCell(Text(session.stroke)),
                DataCell(Text('${session.totalDistance}m')),
                DataCell(Text(DurationUtils.formatDuration(session.totalTime))),
                DataCell(Text(DurationUtils.formatPace(
                  session.totalTime,
                  session.totalDistance,
                ))),
                DataCell(Text('${session.laps.length}')),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      session.notes ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.pool_outlined, size: 56),
            SizedBox(height: 12),
            Text('No sessions match your filters'),
          ],
        ),
      ),
    );
  }
}
