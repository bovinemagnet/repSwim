import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_mode.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_session_result.dart';
import 'package:rep_swim/features/tempo/domain/services/tempo_csv_exporter.dart';

void main() {
  group('TempoCsvExporter', () {
    test('exports split errors and stroke counts', () {
      final csv = const TempoCsvExporter().exportSession(
        TempoSessionResult(
          id: 'tempo-1',
          mode: TempoMode.lapPace,
          startedAt: DateTime.utc(2024),
          targetDistanceMeters: 100,
          poolLengthMeters: 25,
          targetTime: const Duration(seconds: 88),
          targetStrokeRate: 70,
          actualSplits: const [
            Duration(milliseconds: 22000),
            Duration(milliseconds: 22500),
          ],
          strokeCounts: const [18, 19],
        ),
      );

      expect(
        csv,
        contains('session_id,mode,split_index,target_split_ms'),
      );
      expect(csv, contains('tempo-1,lapPace,1,22000,22000,0,18'));
      expect(csv, contains('tempo-1,lapPace,2,22000,22500,500,19'));
    });
  });
}
