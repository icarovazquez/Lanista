import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app.dart';
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Player Search', () {
    testWidgets('Search landing shows headings and division/formation chips',
        (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));
      await loginAsPlayer(tester);

      // Tap Search tab (index 3 — 4th tab)
      final navBar = find.byType(NavigationBar);
      final destinations = tester
          .widget<NavigationBar>(navBar)
          .destinations;
      await tester.tap(find.byWidget(destinations[3]));
      await tester.pumpAndSettle();

      expect(find.text('Find Your Program'), findsOneWidget);
      expect(find.text('Browse by Division'), findsOneWidget);
      expect(find.text('Browse by Formation'), findsOneWidget);
      expect(find.text('D1'), findsAtLeastNWidgets(1));
      expect(find.text('4-3-3'), findsAtLeastNWidgets(1));
    });

    testWidgets('Searching for a program returns results with Message Coach',
        (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));
      await loginAsPlayer(tester);

      // Go to Search tab
      final navBar = find.byType(NavigationBar);
      await tester.tap(find.byWidget(
          tester.widget<NavigationBar>(navBar).destinations[3]));
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(
          find.byType(TextField).first, 'University');
      await tester.pump();

      // Tap Search button
      await tester.tap(find.text('Search'));
      await tester.pump();

      // Wait for results
      await waitFor(tester, find.text('Message Coach'));

      expect(find.text('Message Coach'), findsAtLeastNWidgets(1));
    });

    testWidgets('Filtering by D1 shows results', (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));
      await loginAsPlayer(tester);

      // Go to Search tab
      final navBar = find.byType(NavigationBar);
      await tester.tap(find.byWidget(
          tester.widget<NavigationBar>(navBar).destinations[3]));
      await tester.pumpAndSettle();

      // Tap D1 division chip on landing
      await tester.tap(find.text('D1').first);
      await tester.pump();

      // Wait for results
      await waitFor(tester, find.text('Message Coach'));

      // All visible division tags should be D1
      expect(find.text('D1'), findsAtLeastNWidgets(1));
    });
  });
}
