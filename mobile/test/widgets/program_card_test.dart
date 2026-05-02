// NOTE: _ProgramCard is a private class in player_search_page.dart.
// These tests verify the AuthTextField widget (public) and basic app smoke tests.
// To test _ProgramCard directly, extract it to its own file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanista/features/auth/presentation/widgets/auth_text_field.dart';

void main() {
  group('AuthTextField', () {
    testWidgets('Renders with label text', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AuthTextField(
            controller: controller,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
        ),
      ));
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('Renders password field with obscured text', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AuthTextField(
            controller: controller,
            label: 'Password',
            obscureText: true,
          ),
        ),
      ));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
    });

    testWidgets('Accepts and displays entered text', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AuthTextField(
            controller: controller,
            label: 'Email',
          ),
        ),
      ));
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(controller.text, 'test@example.com');
    });

    testWidgets('Validator is called on invalid input', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AuthTextField(
              controller: controller,
              label: 'Email',
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Invalid email' : null,
            ),
          ),
        ),
      ));
      await tester.enterText(find.byType(TextFormField), 'notanemail');
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Invalid email'), findsOneWidget);
    });
  });
}
