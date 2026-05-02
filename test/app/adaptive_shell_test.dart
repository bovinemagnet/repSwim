import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/app/adaptive_shell.dart';

void main() {
  group('getFormFactor', () {
    test('classifies phone, tablet, and desktop widths', () {
      expect(getFormFactor(599), FormFactor.phone);
      expect(getFormFactor(600), FormFactor.tablet);
      expect(getFormFactor(999), FormFactor.tablet);
      expect(getFormFactor(1000), FormFactor.desktop);
    });

    test('includes race time destination', () {
      expect(
        appDestinations.map((destination) => destination.path),
        contains('/races'),
      );
    });
  });

  group('AdaptiveShell', () {
    testWidgets('uses bottom navigation on phone widths', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdaptiveShell(location: '/', child: Text('Content')),
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('uses navigation rail on desktop widths', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdaptiveShell(location: '/', child: Text('Content')),
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Content'), findsOneWidget);
    });
  });
}
