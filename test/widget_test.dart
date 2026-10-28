import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymvibe/main.dart';

void main() {
  testWidgets('GymVibe app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GymVibeApp());

    // Verify the app renders without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
