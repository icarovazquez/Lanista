import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app.dart';
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth', () {
    testWidgets('Player can log in and sees 5-tab navigation',
        (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3)); // splash

      await loginAsPlayer(tester);

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 5,
          reason: 'Player dashboard should have 5 tabs');
    });

    testWidgets('Coach can log in and sees 6-tab navigation', (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));

      await loginAsCoach(tester);

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 6,
          reason: 'Coach dashboard should have 6 tabs');
    });

    testWidgets('Player can sign out and returns to login', (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));

      await loginAsPlayer(tester);
      await signOut(tester);

      expect(find.text('Sign In'), findsAtLeastNWidgets(1));
    });
  });
}
