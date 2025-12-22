import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crud_catatan/main.dart';
import 'package:crud_catatan/home_page.dart';

void main() {
  testWidgets('App renders HomePage', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Verify that HomePage is rendered
    expect(find.byType(HomePage), findsOneWidget);
    
    // Verify app title appears
    expect(find.text('Catatan Tugas'), findsOneWidget);
    
    // Verify floating action button exists
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Add new note flow', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Tap the FAB to add new note
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    
    // Verify AddEditPage is shown
    expect(find.text('Catatan Baru'), findsOneWidget);
    
    // Find form fields and enter text
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Filter chips work', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Check if filter chips exist
    expect(find.byType(FilterChip), findsWidgets);
    
    // Tap on a filter chip
    await tester.tap(find.text('Kuliah').first);
    await tester.pump();
  });

  testWidgets('Note cards are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Check if note cards are displayed
    expect(find.byType(Card), findsWidgets);
    
    // Check if dummy data appears
    expect(find.text('Tugas Matematika'), findsOneWidget);
    expect(find.text('Rapat Organisasi'), findsOneWidget);
  });
}