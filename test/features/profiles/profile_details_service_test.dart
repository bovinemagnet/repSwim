import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';
import 'package:rep_swim/features/profiles/domain/services/profile_details_service.dart';

void main() {
  group('profile detail helpers', () {
    test('normalizes preferred strokes to known unique values', () {
      expect(
        normalizePreferredStrokes([
          ' Freestyle ',
          'Backstroke',
          'Freestyle',
          '',
          'Unknown',
        ]),
        ['Freestyle', 'Backstroke'],
      );
    });

    test('cleans blank optional details', () {
      expect(cleanProfileDetail(' Sprint focus '), 'Sprint focus');
      expect(cleanProfileDetail('   '), isNull);
      expect(cleanProfileDetail(null), isNull);
    });

    test('builds concise profile detail summaries', () {
      final profile = SwimmerProfile(
        id: 'profile-1',
        displayName: 'Sophie',
        preferredPoolLengthMeters: 50,
        preferredStrokes: const ['Freestyle', 'Butterfly'],
        primaryEvents: '50m free',
        clubName: 'Metro Swim',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      expect(profileDetailsSummary(profile), [
        '50m pool',
        'Metro Swim',
        'Freestyle, Butterfly',
        '50m free',
      ]);
    });
  });
}
