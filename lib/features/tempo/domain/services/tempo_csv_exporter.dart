import '../entities/tempo_session_result.dart';

class TempoCsvExporter {
  const TempoCsvExporter();

  String exportSession(TempoSessionResult result) {
    final rows = <List<String>>[
      [
        'session_id',
        'mode',
        'split_index',
        'target_split_ms',
        'actual_split_ms',
        'error_ms',
        'stroke_count',
      ],
    ];

    final targetSplit = result.targetDistanceMeters == 0
        ? Duration.zero
        : Duration(
            microseconds: (result.targetTime.inMicroseconds *
                    result.poolLengthMeters /
                    result.targetDistanceMeters)
                .round(),
          );
    final splitCount = result.actualSplits.length;
    for (var i = 0; i < splitCount; i++) {
      final actual = result.actualSplits[i];
      rows.add([
        result.id,
        result.mode.name,
        '${i + 1}',
        '${targetSplit.inMilliseconds}',
        '${actual.inMilliseconds}',
        '${actual.inMilliseconds - targetSplit.inMilliseconds}',
        i < result.strokeCounts.length ? '${result.strokeCounts[i]}' : '',
      ]);
    }

    return rows.map(_csvRow).join('\n');
  }

  String _csvRow(List<String> values) {
    return values.map(_csvCell).join(',');
  }

  String _csvCell(String value) {
    if (!value.contains(',') && !value.contains('"') && !value.contains('\n')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }
}
