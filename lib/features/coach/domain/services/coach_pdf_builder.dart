import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../../analytics/presentation/providers/analytics_providers.dart';
import '../../../dryland/domain/entities/dryland_workout.dart';
import '../../../pb/domain/entities/personal_best.dart';
import '../../../race/domain/entities/race_time.dart';
import '../../../swim/domain/entities/swim_session.dart';
import '../entities/coach_report.dart';
import '../entities/coach_share_category.dart';

/// Builds a PDF document from a [CoachReport].
///
/// The resulting bytes begin with the standard `%PDF` magic header and
/// contain one section per included category.  Categories whose backing data
/// list is empty render a "No data" line rather than throwing.
class CoachPdfBuilder {
  const CoachPdfBuilder();

  /// Assembles the PDF and returns the raw bytes.
  Future<Uint8List> build(CoachReport report) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          _buildHeader(report),
          pw.SizedBox(height: 12),
          ..._buildSections(report),
        ],
      ),
    );

    return doc.save();
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  pw.Widget _buildHeader(CoachReport report) {
    final categoryLabels =
        report.includedCategories.map((c) => c.label).join(', ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          report.profile.displayName,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Included categories: $categoryLabels',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Divider(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sections — one per included category
  // ---------------------------------------------------------------------------

  List<pw.Widget> _buildSections(CoachReport report) {
    final widgets = <pw.Widget>[];

    for (final category in report.includedCategories) {
      widgets
        ..add(_sectionHeading(category.label))
        ..addAll(_sectionBody(category, report))
        ..add(pw.SizedBox(height: 10));
    }

    return widgets;
  }

  pw.Widget _sectionHeading(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  List<pw.Widget> _sectionBody(
    CoachShareCategory category,
    CoachReport report,
  ) {
    switch (category) {
      case CoachShareCategory.profileDetails:
        return _profileDetailsSection(report);
      case CoachShareCategory.goals:
        return _goalsSection(report);
      case CoachShareCategory.notes:
        return _notesSection(report);
      case CoachShareCategory.swimSessions:
        return _swimSessionsSection(report.swimSessions);
      case CoachShareCategory.raceTimes:
        return _raceTimesSection(report.raceTimes);
      case CoachShareCategory.personalBests:
        return _personalBestsSection(report.personalBests);
      case CoachShareCategory.dryland:
        return _drylandSection(report.drylandWorkouts);
      case CoachShareCategory.analytics:
        return _analyticsSection(report.analytics);
    }
  }

  // ---------------------------------------------------------------------------
  // Profile-backed category sections
  // ---------------------------------------------------------------------------

  List<pw.Widget> _profileDetailsSection(CoachReport report) {
    final profile = report.profile;
    final rows = <String>[
      'Name: ${profile.displayName}',
      if (profile.clubName != null) 'Club: ${profile.clubName}',
      if (profile.primaryEvents != null) 'Events: ${profile.primaryEvents}',
      'Pool length: ${profile.preferredPoolLengthMeters} m',
      if (profile.preferredStrokes.isNotEmpty)
        'Preferred strokes: ${profile.preferredStrokes.join(', ')}',
    ];
    return rows.map((r) => pw.Text(r)).toList();
  }

  List<pw.Widget> _goalsSection(CoachReport report) {
    final goals = report.profile.goals;
    if (goals == null || goals.isEmpty) {
      return [pw.Text('No data')];
    }
    return [pw.Text(goals)];
  }

  List<pw.Widget> _notesSection(CoachReport report) {
    final notes = report.profile.notes;
    if (notes == null || notes.isEmpty) {
      return [pw.Text('No data')];
    }
    return [pw.Text(notes)];
  }

  // ---------------------------------------------------------------------------
  // Data-backed category sections
  // ---------------------------------------------------------------------------

  List<pw.Widget> _swimSessionsSection(List<SwimSession>? sessions) {
    if (sessions == null || sessions.isEmpty) {
      return [pw.Text('No data')];
    }
    return sessions.map((s) {
      final date = _formatDate(s.date);
      final mins = s.totalTime.inMinutes;
      final secs = s.totalTime.inSeconds % 60;
      return pw.Text(
        '$date — ${s.stroke} ${s.totalDistance} m  '
        '${mins}m ${secs}s',
      );
    }).toList();
  }

  List<pw.Widget> _raceTimesSection(List<RaceTime>? raceTimes) {
    if (raceTimes == null || raceTimes.isEmpty) {
      return [pw.Text('No data')];
    }
    return raceTimes.map((r) {
      final date = _formatDate(r.eventDate);
      final mins = r.time.inMinutes;
      final secs = r.time.inSeconds % 60;
      final ms = r.time.inMilliseconds % 1000;
      return pw.Text(
        '$date — ${r.raceName}  ${r.distance} m ${r.stroke}  '
        '$mins:${secs.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}',
      );
    }).toList();
  }

  List<pw.Widget> _personalBestsSection(List<PersonalBest>? pbs) {
    if (pbs == null || pbs.isEmpty) {
      return [pw.Text('No data')];
    }
    return pbs.map((pb) {
      final date = _formatDate(pb.achievedAt);
      final mins = pb.bestTime.inMinutes;
      final secs = pb.bestTime.inSeconds % 60;
      final ms = pb.bestTime.inMilliseconds % 1000;
      return pw.Text(
        '${pb.stroke} ${pb.distance} m  '
        '$mins:${secs.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}  '
        '($date)',
      );
    }).toList();
  }

  List<pw.Widget> _drylandSection(List<DrylandWorkout>? workouts) {
    if (workouts == null || workouts.isEmpty) {
      return [pw.Text('No data')];
    }
    return workouts.map((w) {
      final date = _formatDate(w.date);
      return pw.Text(
        '$date — ${w.exercises.length} exercise(s)',
      );
    }).toList();
  }

  List<pw.Widget> _analyticsSection(AnalyticsData? analytics) {
    if (analytics == null) {
      return [pw.Text('No data')];
    }
    final paceMin = analytics.averagePacePerHundred.inMinutes;
    final paceSec = analytics.averagePacePerHundred.inSeconds % 60;
    return [
      pw.Text('Total sessions: ${analytics.totalSessions}'),
      pw.Text('Total distance: ${analytics.totalDistanceMeters} m'),
      pw.Text(
        'Average pace per 100 m: '
        '$paceMin:${paceSec.toString().padLeft(2, '0')}',
      ),
      pw.Text('Consistency score: ${analytics.consistencyScore}'),
    ];
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Formats a [DateTime] as `YYYY-MM-DD`.
  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
