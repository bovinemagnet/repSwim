import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_report.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';

void main() {
  test('a report exposes exactly the categories it was built with', () {
    final report = CoachReport(
      profile: SwimmerProfile.defaultProfile,
      includedCategories: const {
        CoachShareCategory.goals,
        CoachShareCategory.swimSessions,
      },
      swimSessions: const [],
    );
    expect(report.includes(CoachShareCategory.goals), isTrue);
    expect(report.includes(CoachShareCategory.notes), isFalse);
  });
}
