import '../../domain/entities/meet_qualification_standard.dart';
import '../../domain/entities/race_time.dart';

const victorianMetroSc2026SourceName =
    '2026/27 Uncloud Victorian Metro SC Championships';

final victorianMetroSc2026ValidFrom = DateTime.utc(2025, 7, 26);
final victorianMetroSc2026CompetitionStart = DateTime.utc(2026, 8);
final victorianMetroSc2026CompetitionEnd = DateTime.utc(2026, 8, 2);

const _age11Under = _AgeBand('11 / Under', maxAge: 11);
const _age12To13 = _AgeBand('12 - 13 Years', minAge: 12, maxAge: 13);
const _age14To15 = _AgeBand('14 - 15 Years', minAge: 14, maxAge: 15);
const _age16To17 = _AgeBand('16 - 17 Years', minAge: 16, maxAge: 17);
const _age18Over = _AgeBand('18 / Over', minAge: 18);
const _ageOpen = _AgeBand('Open', isOpen: true);
const _age13Under = _AgeBand('13 / Under', maxAge: 13);
const _age14Over = _AgeBand('14 / Over', minAge: 14);
const _ageOpenParaAbleBodied = _AgeBand('Open Para Able Bodied', isOpen: true);

/// Structured source data extracted from docs/qualify/qualify_time.pdf.
///
/// The PDF publishes single qualifying thresholds, MC point thresholds, and
/// relay standards. It is intentionally separate from user-managed
/// gold/silver/bronze qualification standards.
List<MeetQualificationStandard> victorianMetroSc2026QualifyingStandards() {
  return [
    ..._individual(
      QualificationSex.male,
      'Butterfly',
      50,
      {_age11Under: '44.30', _age18Over: '31.92'},
      mcPoints: 20,
    ),
    ..._individual(QualificationSex.male, 'Butterfly', 100, {
      _age12To13: '1:21.80',
      _age14To15: '1:11.53',
      _age16To17: '1:08.12',
    }),
    ..._individual(
      QualificationSex.male,
      'Butterfly',
      200,
      {_ageOpen: '2:30.06'},
    ),
    ..._individual(
      QualificationSex.male,
      'Backstroke',
      50,
      {_age11Under: '44.19', _age18Over: '34.64'},
      mcPoints: 20,
    ),
    ..._individual(QualificationSex.male, 'Backstroke', 100, {
      _age12To13: '1:17.04',
      _age14To15: '1:12.71',
      _age16To17: '1:08.42',
    }),
    ..._individual(
      QualificationSex.male,
      'Backstroke',
      200,
      {_ageOpen: '2:30.62'},
    ),
    ..._individual(
      QualificationSex.male,
      'Breaststroke',
      50,
      {_age11Under: '48.05', _age18Over: '34.64'},
      mcPoints: 20,
    ),
    ..._individual(QualificationSex.male, 'Breaststroke', 100, {
      _age12To13: '1:30.13',
      _age14To15: '1:22.74',
      _age16To17: '1:16.79',
    }),
    ..._individual(
      QualificationSex.male,
      'Breaststroke',
      200,
      {_ageOpen: '2:42.62'},
    ),
    ..._individual(
      QualificationSex.male,
      'Freestyle',
      50,
      {_age11Under: '36.12', _age18Over: '25.75'},
      mcPoints: 20,
    ),
    ..._individual(
      QualificationSex.male,
      'Freestyle',
      100,
      {
        _age11Under: '1:21.72',
        _age12To13: '1:07.51',
        _age14To15: '59.62',
        _age16To17: '57.51',
        _age18Over: '57.59',
      },
      mcPoints: 20,
    ),
    ..._individual(QualificationSex.male, 'Freestyle', 200, {
      _age12To13: '2:33.46',
      _age14To15: '2:21.30',
      _age16To17: '2:09.76',
      _age18Over: '2:08.56',
    }),
    ..._individual(
      QualificationSex.male,
      'Freestyle',
      400,
      {_ageOpen: '4:38.23'},
    ),
    ..._individual(
      QualificationSex.male,
      'Individual Medley',
      100,
      {
        _age11Under: '1:31.60',
        _age12To13: '1:20.34',
        _age14To15: '1:08.52',
        _age16To17: '1:07.86',
        _age18Over: '1:07.10',
      },
      mcPoints: 20,
    ),
    ..._individual(
      QualificationSex.male,
      'Individual Medley',
      200,
      {_ageOpen: '2:27.87'},
    ),
    ..._individual(
      QualificationSex.male,
      'Individual Medley',
      400,
      {_ageOpen: '5:18.76'},
    ),
    ..._individual(
      QualificationSex.female,
      'Butterfly',
      50,
      {_age11Under: '42.14', _age18Over: '35.91'},
      mcPoints: 20,
    ),
    ..._individual(QualificationSex.female, 'Butterfly', 100, {
      _age12To13: '1:20.97',
      _age14To15: '1:18.86',
      _age16To17: '1:18.11',
    }),
    ..._individual(
      QualificationSex.female,
      'Butterfly',
      200,
      {_ageOpen: '2:45.14'},
    ),
    ..._individual(
      QualificationSex.female,
      'Backstroke',
      50,
      {_age11Under: '41.85', _age18Over: '38.75'},
      mcPoints: 20,
    ),
    ..._individual(QualificationSex.female, 'Backstroke', 100, {
      _age12To13: '1:17.50',
      _age14To15: '1:16.06',
      _age16To17: '1:15.50',
    }),
    ..._individual(
      QualificationSex.female,
      'Backstroke',
      200,
      {_ageOpen: '2:40.92'},
    ),
    ..._individual(
      QualificationSex.female,
      'Breaststroke',
      50,
      {_age11Under: '48.90', _age18Over: '43.31'},
      mcPoints: 20,
    ),
    ..._individual(QualificationSex.female, 'Breaststroke', 100, {
      _age12To13: '1:29.60',
      _age14To15: '1:28.21',
      _age16To17: '1:26.81',
    }),
    ..._individual(
      QualificationSex.female,
      'Breaststroke',
      200,
      {_ageOpen: '3:05.23'},
    ),
    ..._individual(
      QualificationSex.female,
      'Freestyle',
      50,
      {_age11Under: '34.80', _age18Over: '29.56'},
      mcPoints: 20,
    ),
    ..._individual(
      QualificationSex.female,
      'Freestyle',
      100,
      {
        _age11Under: '1:21.77',
        _age12To13: '1:08.68',
        _age14To15: '1:05.88',
        _age16To17: '1:05.15',
        _age18Over: '1:04.69',
      },
      mcPoints: 20,
    ),
    ..._individual(QualificationSex.female, 'Freestyle', 200, {
      _age12To13: '2:35.56',
      _age14To15: '2:24.80',
      _age16To17: '2:22.93',
      _age18Over: '2:22.20',
    }),
    ..._individual(
      QualificationSex.female,
      'Freestyle',
      400,
      {_ageOpen: '5:08.09'},
    ),
    ..._individual(
      QualificationSex.female,
      'Individual Medley',
      100,
      {
        _age11Under: '1:29.11',
        _age12To13: '1:17.13',
        _age14To15: '1:14.92',
        _age16To17: '1:14.31',
        _age18Over: '1:14.18',
      },
      mcPoints: 20,
    ),
    ..._individual(
      QualificationSex.female,
      'Individual Medley',
      200,
      {_ageOpen: '2:43.39'},
    ),
    ..._individual(
      QualificationSex.female,
      'Individual Medley',
      400,
      {_ageOpen: '5:50.03'},
    ),
    ..._relay(
      'Freestyle Relay',
      {
        _age13Under: '2:10.00',
        _age14Over: '2:00.00',
        _ageOpenParaAbleBodied: null,
      },
    ),
    ..._relay(
      'Medley Relay',
      {
        _age13Under: '2:35.00',
        _age14Over: '2:15.00',
        _ageOpenParaAbleBodied: null,
      },
    ),
  ];
}

List<MeetQualificationStandard> _individual(
  QualificationSex sex,
  String stroke,
  int distance,
  Map<_AgeBand, String> times, {
  int? mcPoints,
}) {
  final standards = <MeetQualificationStandard>[
    for (final entry in times.entries)
      _standard(
        sex: sex,
        ageBand: entry.key,
        stroke: stroke,
        distance: distance,
        qualifyingTime: _parseQualifyingTime(entry.value),
      ),
  ];

  if (mcPoints != null) {
    standards.add(
      _standard(
        sex: sex,
        ageBand: const _AgeBand('MC', isOpen: true),
        stroke: stroke,
        distance: distance,
        mcPoints: mcPoints,
      ),
    );
  }

  return standards;
}

List<MeetQualificationStandard> _relay(
  String event,
  Map<_AgeBand, String?> times,
) {
  return [
    for (final entry in times.entries)
      _standard(
        ageBand: entry.key,
        stroke: event.replaceAll(' Relay', ''),
        qualifyingTime:
            entry.value == null ? null : _parseQualifyingTime(entry.value!),
        isRelay: true,
        relayEvent: event,
      ),
  ];
}

MeetQualificationStandard _standard({
  required _AgeBand ageBand,
  QualificationSex? sex,
  String? stroke,
  int? distance,
  Duration? qualifyingTime,
  int? mcPoints,
  bool isRelay = false,
  String? relayEvent,
}) {
  return MeetQualificationStandard(
    id: _id([
      victorianMetroSc2026SourceName,
      if (sex != null) sex.name,
      ageBand.label,
      if (distance != null) '${distance}m',
      if (stroke != null) stroke,
      if (isRelay) 'relay',
      if (mcPoints != null) 'mc-$mcPoints',
    ]),
    sourceName: victorianMetroSc2026SourceName,
    sex: sex,
    ageGroupLabel: ageBand.label,
    minAge: ageBand.minAge,
    maxAge: ageBand.maxAge,
    isOpen: ageBand.isOpen,
    distance: distance,
    stroke: stroke,
    course: RaceCourse.shortCourseMeters,
    qualifyingTime: qualifyingTime,
    mcPoints: mcPoints,
    isRelay: isRelay,
    relayEvent: relayEvent,
    validFrom: victorianMetroSc2026ValidFrom,
    competitionStart: victorianMetroSc2026CompetitionStart,
    competitionEnd: victorianMetroSc2026CompetitionEnd,
  );
}

Duration _parseQualifyingTime(String value) {
  final parts = value.split(':');
  if (parts.length == 1) {
    return _durationFromSeconds(parts.single);
  }
  if (parts.length == 2) {
    final minutes = int.parse(parts.first);
    return Duration(minutes: minutes) + _durationFromSeconds(parts.last);
  }
  throw FormatException('Unsupported qualifying time format', value);
}

Duration _durationFromSeconds(String value) {
  final seconds = double.parse(value);
  return Duration(milliseconds: (seconds * 1000).round());
}

String _id(List<String> parts) {
  return parts
      .join('-')
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('(^-|-\$)'), '');
}

class _AgeBand {
  const _AgeBand(
    this.label, {
    this.minAge,
    this.maxAge,
    this.isOpen = false,
  });

  final String label;
  final int? minAge;
  final int? maxAge;
  final bool isOpen;
}
