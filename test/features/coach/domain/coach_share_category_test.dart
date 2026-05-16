import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';

void main() {
  group('CoachShareCategory', () {
    test('exposes eight categories', () {
      expect(CoachShareCategory.values.length, 8);
    });

    test('every category has a unique non-empty key and label', () {
      final keys = CoachShareCategory.values.map((c) => c.key).toSet();
      expect(keys.length, 8);
      for (final c in CoachShareCategory.values) {
        expect(c.key, isNotEmpty);
        expect(c.label, isNotEmpty);
      }
    });

    test('fromKey round-trips every category', () {
      for (final c in CoachShareCategory.values) {
        expect(CoachShareCategory.fromKey(c.key), c);
      }
    });

    test('fromKey returns null for an unknown key', () {
      expect(CoachShareCategory.fromKey('not_a_category'), isNull);
    });
  });
}
