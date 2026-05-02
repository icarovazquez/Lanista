import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app.dart';
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Player Messaging', () {
    testWidgets('Player can open a conversation with a coach from Search',
        (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));
      await loginAsPlayer(tester);

      // Go to Search tab (index 3)
      final navBar = find.byType(NavigationBar);
      await tester.tap(find.byWidget(
          tester.widget<NavigationBar>(navBar).destinations[3]));
      await tester.pumpAndSettle();

      // Search for North Carolina
      await tester.enterText(find.byType(TextField).first, 'North Carolina');
      await tester.pump();
      await tester.tap(find.text('Search'));
      await tester.pump();

      await waitFor(tester, find.text('Message Coach'));

      // Tap Message Coach on first result
      await tester.tap(find.text('Message Coach').first);
      await tester.pump();

      // Wait for conversation detail page to open
      await waitFor(tester, find.byType(AppBar),
          timeout: const Duration(seconds: 10));

      // AppBar should show coach name
      expect(find.textContaining('Coach'), findsAtLeastNWidgets(1));
    });

    testWidgets('Player can send a message', (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));
      await loginAsPlayer(tester);

      // Go to Search tab and open a conversation
      final navBar = find.byType(NavigationBar);
      await tester.tap(find.byWidget(
          tester.widget<NavigationBar>(navBar).destinations[3]));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'North Carolina');
      await tester.pump();
      await tester.tap(find.text('Search'));
      await tester.pump();
      await waitFor(tester, find.text('Message Coach'));
      await tester.tap(find.text('Message Coach').first);
      await tester.pump();
      await waitFor(tester, find.byType(AppBar));

      // Find message input and type
      const testMessage = 'Hello from automated test';
      final messageInputs = find.byType(TextField);
      // The message TextField is the last one on this page
      await tester.enterText(messageInputs.last, testMessage);
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(const Duration(seconds: 2));

      // Message should appear in the conversation
      expect(find.text(testMessage), findsAtLeastNWidgets(1));
    });

    testWidgets('Messages tab shows conversations list', (tester) async {
      appMain();
      await tester.pump(const Duration(seconds: 3));
      await loginAsPlayer(tester);

      // Go to Messages tab (index 4)
      final navBar = find.byType(NavigationBar);
      await tester.tap(find.byWidget(
          tester.widget<NavigationBar>(navBar).destinations[4]));
      await tester.pump();

      await waitFor(tester, find.byType(ListView),
          timeout: const Duration(seconds: 10));

      // Should show at least one conversation (we have Marcus Daniels from prior tests)
      expect(find.byType(ListView), findsAtLeastNWidgets(1));
    });
  });
}
