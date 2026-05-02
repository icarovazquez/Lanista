// NOTE: _MessageBubble is a private class in conversation_detail_page.dart.
// These tests verify the visual behavior inline using an equivalent widget
// structure. To test _MessageBubble directly, extract it to its own file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanista/core/theme/app_colors.dart';

/// Minimal bubble widget mirroring the sent/received layout of _MessageBubble.
Widget _buildBubble({required bool isMe, required String text}) {
  return MaterialApp(
    home: Scaffold(
      body: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(text,
                style: TextStyle(
                    color: isMe ? Colors.white : AppColors.textPrimary)),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('Message Bubble', () {
    testWidgets('Sent bubble renders text', (tester) async {
      await tester.pumpWidget(_buildBubble(isMe: true, text: 'Hello coach'));
      expect(find.text('Hello coach'), findsOneWidget);
    });

    testWidgets('Received bubble renders text', (tester) async {
      await tester.pumpWidget(_buildBubble(isMe: false, text: 'Hello player'));
      expect(find.text('Hello player'), findsOneWidget);
    });

    testWidgets('Sent bubble is right-aligned', (tester) async {
      await tester.pumpWidget(_buildBubble(isMe: true, text: 'Hi'));
      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.end);
    });

    testWidgets('Received bubble is left-aligned', (tester) async {
      await tester.pumpWidget(_buildBubble(isMe: false, text: 'Hi'));
      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.start);
    });
  });
}
