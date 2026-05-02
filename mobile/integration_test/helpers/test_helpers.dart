import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const kTestPlayerEmail = 'kieran.ross@lanista.test';
const kTestCoachEmail = 'coach.marcus@lanista.test';
const kTestPassword = 'Lanista2026!';

/// Waits until [finder] is visible, polling every 500ms up to [timeout].
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsAtLeastNWidgets(1),
      reason: 'Timed out waiting for: $finder');
}

/// Enters email + password and taps Sign In. Waits for NavigationBar to appear.
Future<void> loginAsPlayer(WidgetTester tester) async {
  await _login(tester, kTestPlayerEmail, kTestPassword);
}

Future<void> loginAsCoach(WidgetTester tester) async {
  await _login(tester, kTestCoachEmail, kTestPassword);
}

Future<void> _login(
    WidgetTester tester, String email, String password) async {
  // Wait for login page to load
  await waitFor(tester, find.text('Sign In'));

  // Enter email
  final emailField = find.byWidgetPredicate((w) =>
      w is TextField &&
      (w.decoration?.labelText?.toLowerCase().contains('email') ?? false));
  await tester.enterText(emailField, email);
  await tester.pump();

  // Enter password
  final passwordField = find.byWidgetPredicate((w) =>
      w is TextField &&
      (w.decoration?.labelText?.toLowerCase().contains('password') ??
          w.obscureText));
  await tester.enterText(passwordField, password);
  await tester.pump();

  // Tap Sign In button
  await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
  await tester.pump();

  // Wait for NavigationBar (dashboard) to appear — Supabase auth takes ~3–5s
  await waitFor(tester, find.byType(NavigationBar),
      timeout: const Duration(seconds: 20));
}

/// Taps the profile avatar → Sign Out → waits for login page.
Future<void> signOut(WidgetTester tester) async {
  // Open profile menu (top-right avatar / circular button)
  final avatar = find.byType(CircleAvatar).last;
  await tester.tap(avatar);
  await tester.pumpAndSettle();

  // Tap Sign Out
  await tester.tap(find.text('Sign Out'));
  await tester.pumpAndSettle();

  await waitFor(tester, find.text('Sign In'));
}
