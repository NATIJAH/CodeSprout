// student/test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student/main.dart';

void main() {
  testWidgets('Student app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp()); // REMOVED 'const'

    // Verify that our app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}