import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/core/sync/sync_providers.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/features/settings/presentation/screens/sync_settings_screen.dart';

void main() {
  testWidgets('shows sync mode controls and queue summary', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
    expect(find.text('Pending: 2'), findsOneWidget);
    expect(find.text('Failed: 1'), findsOneWidget);
    expect(find.text('Complete: 3'), findsOneWidget);

    await tester.tap(find.text('Manual'));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SyncSettingsScreen)),
    );
    expect(container.read(syncModeProvider), SyncMode.manual);
  });
}
