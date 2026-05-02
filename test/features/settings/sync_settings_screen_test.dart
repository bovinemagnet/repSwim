import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/core/constants/app_constants.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/core/sync/sync_providers.dart';
import 'package:rep_swim/database/daos/app_settings_dao.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/features/profiles/presentation/providers/profile_providers.dart';
import 'package:rep_swim/features/settings/presentation/screens/sync_settings_screen.dart';
import 'package:rep_swim/features/stopwatch/presentation/providers/stopwatch_display_style_provider.dart';

class _MockAppSettingsDao extends Mock implements AppSettingsDao {}

void main() {
  test('bootstraps persisted sync mode', () async {
    final settings = _MockAppSettingsDao();
    when(() => settings.getString(any())).thenAnswer((_) async => 'automatic');

    final container = ProviderContainer(
      overrides: [
        appSettingsDaoProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);

    await container.read(syncModeBootstrapProvider.future);

    expect(container.read(syncModeProvider), SyncMode.automatic);
  });

  test('bootstraps persisted stopwatch display style', () async {
    final settings = _MockAppSettingsDao();
    when(() => settings.getString(any())).thenAnswer((_) async => 'numitron');

    final container = ProviderContainer(
      overrides: [
        appSettingsDaoProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);

    await container.read(stopwatchDisplayStyleBootstrapProvider.future);

    expect(
      container.read(stopwatchDisplayStyleProvider),
      StopwatchDisplayStyle.numitron,
    );
  });

  testWidgets('shows sync mode controls and queue summary', (tester) async {
    final settings = _MockAppSettingsDao();
    when(() => settings.setString(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsDaoProvider.overrideWithValue(settings),
          syncQueueSummaryProvider.overrideWith(
            (ref) async => const SyncQueueSummary(
              pending: 2,
              failed: 1,
              complete: 3,
            ),
          ),
        ],
        child: const MaterialApp(home: SyncSettingsScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Sync Settings'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    expect(find.text('No backend configured'), findsOneWidget);
    expect(find.text('Stopwatch Display'), findsOneWidget);
    expect(find.text('Timer display style'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('Pending: 2'), findsOneWidget);
    expect(find.text('Failed: 1'), findsOneWidget);
    expect(find.text('Complete: 3'), findsOneWidget);

    await tester.tap(find.text('Manual'));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SyncSettingsScreen)),
    );
    expect(container.read(syncModeProvider), SyncMode.manual);
    verify(() => settings.setString('sync_mode', 'manual')).called(1);

    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();
    expect(find.text('Split-flap'), findsOneWidget);
    await tester.tap(find.text('Numitron').last);
    await tester.pump();

    expect(
      container.read(stopwatchDisplayStyleProvider),
      StopwatchDisplayStyle.numitron,
    );
    verify(
      () => settings.setString(
        kStopwatchDisplayStyleSetting,
        StopwatchDisplayStyle.numitron.name,
      ),
    ).called(1);
  });

  testWidgets('shows and dismisses queue failure warning', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncQueueFailureProvider.overrideWith((ref) => 'disk full'),
          syncQueueSummaryProvider.overrideWith(
            (ref) async => const SyncQueueSummary(),
          ),
        ],
        child: const MaterialApp(home: SyncSettingsScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Some changes could not be queued'), findsOneWidget);
    expect(find.text('disk full'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss warning'));
    await tester.pump();

    expect(find.text('Some changes could not be queued'), findsNothing);
  });
}
