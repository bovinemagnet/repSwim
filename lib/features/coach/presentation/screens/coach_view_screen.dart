import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../domain/entities/coach_report.dart';
import '../../domain/entities/coach_share_category.dart';
import '../../domain/services/coach_pdf_builder.dart';
import '../providers/coach_providers.dart';
import '../providers/coach_report_providers.dart';

/// A sealed, read-only view of the data shared with a coach.
///
/// The screen contains no edit, add or delete affordances.  A swimmer selects
/// which profile to view when more than one profile is shared, and can export
/// the report to PDF via the app-bar action.
class CoachViewScreen extends ConsumerStatefulWidget {
  const CoachViewScreen({super.key});

  @override
  ConsumerState<CoachViewScreen> createState() => _CoachViewScreenState();
}

class _CoachViewScreenState extends ConsumerState<CoachViewScreen> {
  /// The profile id currently selected for display, or null when the picker
  /// has not yet been resolved (zero or multiple shared profiles).
  String? _selectedProfileId;

  @override
  Widget build(BuildContext context) {
    final sharedAsync = ref.watch(sharedProfileIdsProvider);

    return sharedAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Coach view')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Coach view')),
        body: Center(child: Text('Error: $err')),
      ),
      data: (ids) {
        if (ids.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(context, null),
            body: const Center(
              child: Text('No profiles are shared with a coach'),
            ),
          );
        }

        if (ids.length == 1) {
          return _reportScaffold(context, ids.first);
        }

        // Multiple profiles: show a picker unless one is already selected.
        final selected = _selectedProfileId;
        if (selected != null && ids.contains(selected)) {
          return _reportScaffold(context, selected);
        }

        final profilesAsync = ref.watch(profilesProvider);
        final profiles = profilesAsync.valueOrNull ?? const [];

        return Scaffold(
          appBar: _buildAppBar(context, null),
          body: ListView.builder(
            itemCount: ids.length,
            itemBuilder: (context, index) {
              final id = ids[index];
              final match = profiles.where((p) => p.id == id);
              final label = match.isNotEmpty ? match.first.displayName : id;
              return ListTile(
                title: Text(label),
                onTap: () => setState(() => _selectedProfileId = id),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Report scaffold
  // ---------------------------------------------------------------------------

  Widget _reportScaffold(BuildContext context, String profileId) {
    final reportAsync = ref.watch(coachReportProvider(profileId));

    return reportAsync.when(
      loading: () => Scaffold(
        appBar: _buildAppBar(context, null),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: _buildAppBar(context, null),
        body: Center(child: Text('Error: $err')),
      ),
      data: (report) => Scaffold(
        appBar: _buildAppBar(context, report),
        body: _ReportBody(report: report),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------

  AppBar _buildAppBar(BuildContext context, CoachReport? report) {
    return AppBar(
      title: const Text('Coach view'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Exit coach view',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        if (report != null)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () => _exportPdf(report),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PDF export
  // ---------------------------------------------------------------------------

  Future<void> _exportPdf(CoachReport report) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final Uint8List bytes = await const CoachPdfBuilder().build(report);
      if (!context.mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${report.profile.displayName}_coach_report.pdf',
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not export PDF')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Read-only report body
// ---------------------------------------------------------------------------

/// Renders one read-only section per category included in [report].
///
/// Categories not present in [report.includedCategories] produce no widget.
class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final CoachReport report;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];

    for (final category in CoachShareCategory.values) {
      if (!report.includes(category)) continue;
      sections.add(_CategoryPanel(category: category, report: report));
    }

    if (sections.isEmpty) {
      return const Center(child: Text('No data shared'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sections,
    );
  }
}

// ---------------------------------------------------------------------------
// Single category panel (private, read-only)
// ---------------------------------------------------------------------------

class _CategoryPanel extends StatelessWidget {
  const _CategoryPanel({required this.category, required this.report});

  final CoachShareCategory category;
  final CoachReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category.label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        _body(context),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _body(BuildContext context) {
    switch (category) {
      case CoachShareCategory.profileDetails:
        return _ProfileDetailsBody(report: report);
      case CoachShareCategory.goals:
        return _TextBody(text: report.profile.goals);
      case CoachShareCategory.notes:
        return _TextBody(text: report.profile.notes);
      case CoachShareCategory.swimSessions:
        return _SwimSessionsBody(sessions: report.swimSessions);
      case CoachShareCategory.raceTimes:
        return _RaceTimesBody(raceTimes: report.raceTimes);
      case CoachShareCategory.personalBests:
        return _PersonalBestsBody(pbs: report.personalBests);
      case CoachShareCategory.dryland:
        return _DrylandBody(workouts: report.drylandWorkouts);
      case CoachShareCategory.analytics:
        return _AnalyticsBody(analytics: report.analytics);
    }
  }
}

// ---------------------------------------------------------------------------
// Per-category body widgets (private, read-only)
// ---------------------------------------------------------------------------

class _TextBody extends StatelessWidget {
  const _TextBody({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) {
      return const Text('No data');
    }
    return Text(text!);
  }
}

class _ProfileDetailsBody extends StatelessWidget {
  const _ProfileDetailsBody({required this.report});

  final CoachReport report;

  @override
  Widget build(BuildContext context) {
    final p = report.profile;
    final rows = <String>[
      'Name: ${p.displayName}',
      if (p.clubName != null) 'Club: ${p.clubName}',
      if (p.primaryEvents != null) 'Events: ${p.primaryEvents}',
      'Pool length: ${p.preferredPoolLengthMeters} m',
      if (p.preferredStrokes.isNotEmpty)
        'Preferred strokes: ${p.preferredStrokes.join(', ')}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((r) => Text(r)).toList(),
    );
  }
}

class _SwimSessionsBody extends StatelessWidget {
  const _SwimSessionsBody({required this.sessions});

  final List<dynamic>? sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions == null || sessions!.isEmpty) {
      return const Text('No data');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sessions!
          .map<Widget>(
              (s) => Text('${s.date} — ${s.stroke} ${s.totalDistance} m'))
          .toList(),
    );
  }
}

class _RaceTimesBody extends StatelessWidget {
  const _RaceTimesBody({required this.raceTimes});

  final List<dynamic>? raceTimes;

  @override
  Widget build(BuildContext context) {
    if (raceTimes == null || raceTimes!.isEmpty) {
      return const Text('No data');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: raceTimes!
          .map<Widget>((r) => Text('${r.raceName} — ${r.distance} m'))
          .toList(),
    );
  }
}

class _PersonalBestsBody extends StatelessWidget {
  const _PersonalBestsBody({required this.pbs});

  final List<dynamic>? pbs;

  @override
  Widget build(BuildContext context) {
    if (pbs == null || pbs!.isEmpty) {
      return const Text('No data');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: pbs!
          .map<Widget>((pb) => Text('${pb.stroke} ${pb.distance} m'))
          .toList(),
    );
  }
}

class _DrylandBody extends StatelessWidget {
  const _DrylandBody({required this.workouts});

  final List<dynamic>? workouts;

  @override
  Widget build(BuildContext context) {
    if (workouts == null || workouts!.isEmpty) {
      return const Text('No data');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: workouts!
          .map<Widget>(
              (w) => Text('${w.date} — ${w.exercises.length} exercise(s)'))
          .toList(),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.analytics});

  final dynamic analytics;

  @override
  Widget build(BuildContext context) {
    if (analytics == null) {
      return const Text('No data');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total sessions: ${analytics.totalSessions}'),
        Text('Total distance: ${analytics.totalDistanceMeters} m'),
        Text('Consistency score: ${analytics.consistencyScore}'),
      ],
    );
  }
}
