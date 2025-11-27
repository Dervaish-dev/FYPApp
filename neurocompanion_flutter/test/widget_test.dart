// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neurocompanion_flutter/main.dart';

void main() {
  testWidgets('NeuroCompanion app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeuroCompanionApp());

    // Verify that our login screen appears.
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to your NeuroCompanion account'), findsOneWidget);

    // Verify that email and password fields are present.
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
