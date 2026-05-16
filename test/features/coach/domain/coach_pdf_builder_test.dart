import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_report.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';
import 'package:rep_swim/features/coach/domain/services/coach_pdf_builder.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';

void main() {
  test('builds a non-empty PDF for a report', () async {
    final report = CoachReport(
      profile: SwimmerProfile.defaultProfile,
      includedCategories: const {CoachShareCategory.profileDetails},
    );
    final bytes = await const CoachPdfBuilder().build(report);
    expect(bytes, isNotEmpty);
    // A PDF file starts with the "%PDF" magic bytes.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
