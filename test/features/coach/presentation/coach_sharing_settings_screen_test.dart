import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/core/constants/app_constants.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';
import 'package:rep_swim/features/coach/presentation/providers/coach_providers.dart';
import 'package:rep_swim/features/coach/presentation/screens/coach_sharing_settings_screen.dart';

/// A fake [CoachShareController] backed by an in-memory store so widget tests
/// don't need real SQLite I/O and [WidgetTester.pumpAndSettle] doesn't time out.
class _FakeCoachShareController extends CoachShareController {
  _FakeCoachShareController(CoachShare initial) {
    _store = initial;
  }

  late CoachShare _store;

  // Expose the current share so tests can inspect state after interactions.
  CoachShare get current => _store;

  @override
  Future<CoachShare> build(String profileId) async => _store;

  @override
  Future<void> setEnabled(bool enabled) async {
    _store = _store.copyWith(enabled: enabled);
    state = AsyncData(_store);
  }

  @override
  Future<void> setCategory(CoachShareCategory category, bool shared) async {
    _store = shared
        ? _store.withCategory(category)
        : _store.withoutCategory(category);
    state = AsyncData(_store);
  }

  @override
  Future<void> stopSharing() async {
    _store = _store.copyWith(enabled: false);
    state = AsyncData(_store);
  }
}

void main() {
  testWidgets('enabling sharing reveals the category toggles', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        coachShareControllerProvider.overrideWith(
          () => _FakeCoachShareController(
            const CoachShare(profileId: kDefaultProfileId),
          ),
        ),
      ],
      child: const MaterialApp(
        home: CoachSharingSettingsScreen(profileId: kDefaultProfileId),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Goals'), findsNothing);
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Goals'), findsOneWidget);
  });

  testWidgets('Stop sharing turns the master switch off', (tester) async {
    late _FakeCoachShareController controller;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        coachShareControllerProvider.overrideWith(() {
          controller = _FakeCoachShareController(
            const CoachShare(
              profileId: kDefaultProfileId,
              enabled: true,
              sharedCategories: {CoachShareCategory.goals},
            ),
          );
          return controller;
        }),
      ],
      child: const MaterialApp(
        home: CoachSharingSettingsScreen(profileId: kDefaultProfileId),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Stop sharing'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Stop sharing'));
    await tester.pumpAndSettle();

    expect(controller.current.enabled, isFalse);
  });
}
