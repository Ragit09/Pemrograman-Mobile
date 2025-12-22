import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forms_app/main.dart';

void main() {
  testWidgets('App starts with login page', (WidgetTester tester) async {
    // Build our app with const constructor
    await tester.pumpWidget(const MyApp()); // SEKARANG BISA PAKAI CONST

    // Verify that login page is shown
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('Login page has correct widgets', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify all main widgets are present
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
  });
}