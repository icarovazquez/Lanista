import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app.dart';
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Coach Navigation', () {
    testWidgets('All 6 coach tabs load without crashing', (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));
      await loginAsCoach(tester);

      final navBar = find.byType(NavigationBar);
      final count =
          tester.widget<NavigationBar>(navBar).destinations.length;
      expect(count, 6);

      // Tap each tab and verify no crash
      for (int i = 0; i < count; i++) {
        await tester.tap(find.byWidget(
            tester.widget<NavigationBar>(navBar).destinations[i]));
        await tester.pump(const Duration(seconds: 2));
        // Verify the app is still alive (NavigationBar still present)
        expect(find.byType(NavigationBar), findsOneWidget,
            reason: 'App crashed on tab $i');
      }
    });

    testWidgets('Coach Search tab shows "Find Recruits"', (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));
      await loginAsCoach(tester);

      // Search tab is index 4 on coach side
      final navBar = find.byType(NavigationBar);
      await tester.tap(find.byWidget(
          tester.widget<NavigationBar>(navBar).destinations[4]));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Find Recruits'), findsOneWidget);
    });

    testWidgets('Coach Matches tab loads', (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));
      await loginAsCoach(tester);

      // Matches tab is index 1
      final navBar = find.byType(NavigationBar);
      await tester.tap(find.byWidget(
          tester.widget<NavigationBar>(navBar).destinations[1]));
      await tester.pump(const Duration(seconds: 3));

      // Just verify no crash — app still running
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Coach Pipeline tab loads', (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));
      await loginAsCoach(tester);

      // Pipeline tab is index 3
      final navBar = find.byType(NavigationBar);
      await tester.tap(find.byWidget(
          tester.widget<NavigationBar>(navBar).destinations[3]));
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
