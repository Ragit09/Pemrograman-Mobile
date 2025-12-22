import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finflow/main.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/screens/settings_screen.dart';
import 'package:finflow/screens/add_edit_screen.dart';
import 'package:finflow/screens/transactions_screen.dart';
import 'package:finflow/screens/budgets_screen.dart';
import 'package:finflow/screens/home_screen.dart';
import 'package:finflow/models/transaction.dart' as model;
import 'package:finflow/models/budget.dart';
import 'package:finflow/utils/constants.dart';

// Mock SharedPreferences for testing
class MockSharedPreferences {
  static void setMockInitialValues(Map<String, Object> values) {
    SharedPreferences.setMockInitialValues(values);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI Overflow Fixes Tests', () {
    late ThemeProvider themeProvider;
    late TransactionProvider transactionProvider;

    setUp(() {
      // Mock SharedPreferences
      MockSharedPreferences.setMockInitialValues({
        'currency': 'IDR',
        'transactions_backup_v2': '[]',
        'budgets': '[]',
        'cached_exchange_rates': '{"IDR":15523.50}',
        'cached_exchange_time': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      themeProvider = ThemeProvider();
      transactionProvider = TransactionProvider();
    });

    testWidgets('Settings Screen Currency Dialog - No Bottom Overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Find and tap the currency selection tile
      final currencyTile = find.text('Mata Uang');
      expect(currencyTile, findsOneWidget);
      await tester.tap(currencyTile);
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Pilih Mata Uang'), findsOneWidget);

      // Verify all currencies are present in the dialog
      for (final currency in AppCurrencies.supportedCurrencies) {
        expect(find.text(currency), findsOneWidget);
      }

      // Verify the dialog content is scrollable (no overflow)
      final dialogContent = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SingleChildScrollView),
      );
      expect(dialogContent, findsOneWidget);

      // Verify dialog can be dismissed
      final cancelButton = find.text('Batal');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Pilih Mata Uang'), findsNothing);
    });

    testWidgets('Add/Edit Screen Currency Dropdown - Proper Width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: AddEditScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Find the currency dropdown
      final currencyDropdown = find.byType(DropdownButtonFormField<String>);
      expect(currencyDropdown, findsOneWidget);

      // Verify the dropdown has proper width (120 pixels)
      final dropdownContainer = find.ancestor(
        of: currencyDropdown,
        matching: find.byType(Container),
      ).first;

      final containerWidget = tester.widget<Container>(dropdownContainer);
      expect(containerWidget.constraints?.maxWidth, 120.0);

      // Test dropdown functionality
      await tester.tap(currencyDropdown);
      await tester.pumpAndSettle();

      // Verify dropdown menu appears
      expect(find.text('IDR'), findsWidgets); // Should find multiple instances
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);

      // Select a different currency
      await tester.tap(find.text('USD').last);
      await tester.pumpAndSettle();

      // Verify selection changed
      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('Settings Screen Currency Dialog - All Currencies Accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open currency dialog
      await tester.tap(find.text('Mata Uang'));
      await tester.pumpAndSettle();

      // Verify all supported currencies are displayed
      expect(AppCurrencies.supportedCurrencies.length, 10);
      for (final currency in AppCurrencies.supportedCurrencies) {
        expect(find.text(currency), findsOneWidget);
        // Verify currency flags are shown
        final flag = AppCurrencies.currencyFlags[currency];
        if (flag != null) {
          expect(find.text(flag), findsOneWidget);
        }
      }

      // Test scrolling functionality
      final scrollable = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SingleChildScrollView),
      );
      expect(scrollable, findsOneWidget);

      // Scroll to the bottom of the dialog
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify last currency is still visible
      final lastCurrency = AppCurrencies.supportedCurrencies.last;
      expect(find.text(lastCurrency), findsOneWidget);
    });

    testWidgets('Add/Edit Screen Layout - No Right Overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: AddEditScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the screen fits within bounds
      expect(tester.takeException(), isNull);

      // Test form fields are properly laid out
      expect(find.text('Judul Transaksi'), findsOneWidget);
      expect(find.text('Jumlah'), findsOneWidget);
      expect(find.text('Mata Uang'), findsOneWidget);

      // Verify Row containing amount and currency fields
      final amountRow = find.byType(Row);
      expect(amountRow, findsWidgets);

      // Verify no overflow pixels are reported
      final overflowErrors = tester.takeException();
      expect(overflowErrors, isNull);
    });
  });

  group('Transaction Management Tests', () {
    late ThemeProvider themeProvider;
    late TransactionProvider transactionProvider;

    setUp(() {
      // Mock SharedPreferences
      MockSharedPreferences.setMockInitialValues({
        'currency': 'IDR',
        'transactions_backup_v2': '[]',
        'budgets': '[]',
        'cached_exchange_rates': '{"IDR":15523.50}',
        'cached_exchange_time': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      themeProvider = ThemeProvider();
      transactionProvider = TransactionProvider();
    });

    testWidgets('Add Income Transaction', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: AddEditScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill in transaction details
      await tester.enterText(find.byType(TextFormField).first, 'Test Income');
      await tester.enterText(find.byType(TextFormField).at(1), '100000');
      await tester.enterText(find.byType(TextFormField).last, 'Salary payment');

      // Select income type
      await tester.tap(find.text('Pemasukan'));
      await tester.pumpAndSettle();

      // Select category
      await tester.tap(find.text('Gaji'));
      await tester.pumpAndSettle();

      // Save transaction
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      // Verify transaction was added (should navigate back)
      expect(find.text('Test Income'), findsNothing); // Should be back to home
    });

    testWidgets('Add Expense Transaction', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: AddEditScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill in transaction details
      await tester.enterText(find.byType(TextFormField).first, 'Test Expense');
      await tester.enterText(find.byType(TextFormField).at(1), '50000');
      await tester.enterText(find.byType(TextFormField).last, 'Lunch payment');

      // Select expense type (default)
      // Select category
      await tester.tap(find.text('Makanan'));
      await tester.pumpAndSettle();

      // Save transaction
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      // Verify transaction was added
      expect(find.text('Test Expense'), findsNothing);
    });

    testWidgets('Transaction List Display', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: TransactionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify transaction list is displayed
      expect(find.byType(ListView), findsOneWidget);

      // Check for filter tabs
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
    });
  });

  group('Budget Management Tests', () {
    late ThemeProvider themeProvider;
    late TransactionProvider transactionProvider;

    setUp(() {
      // Mock SharedPreferences
      MockSharedPreferences.setMockInitialValues({
        'currency': 'IDR',
        'transactions_backup_v2': '[]',
        'budgets': '[]',
        'cached_exchange_rates': '{"IDR":15523.50}',
        'cached_exchange_time': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      themeProvider = ThemeProvider();
      transactionProvider = TransactionProvider();
    });

    testWidgets('Budget Screen Display', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: BudgetsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify budget screen elements
      expect(find.text('Budget'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Add Budget Dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: BudgetsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap add budget button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Tambah Budget'), findsOneWidget);

      // Fill budget details
      await tester.enterText(find.byType(TextFormField).at(1), '1000000');

      // Save budget
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Verify dialog closes
      expect(find.text('Tambah Budget'), findsNothing);
    });
  });

  group('Settings and Theme Tests', () {
    late ThemeProvider themeProvider;
    late TransactionProvider transactionProvider;

    setUp(() {
      // Mock SharedPreferences
      MockSharedPreferences.setMockInitialValues({
        'currency': 'IDR',
        'transactions_backup_v2': '[]',
        'budgets': '[]',
        'cached_exchange_rates': '{"IDR":15523.50}',
        'cached_exchange_time': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      themeProvider = ThemeProvider();
      transactionProvider = TransactionProvider();
    });

    testWidgets('Theme Toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find theme toggle
      final themeSwitch = find.byType(SwitchListTile).first;
      expect(themeSwitch, findsOneWidget);

      // Toggle theme
      await tester.tap(themeSwitch);
      await tester.pumpAndSettle();

      // Verify theme changed
      expect(themeProvider.isDarkMode, isTrue);
    });

    testWidgets('Settings Screen Elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify settings elements
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Preferensi'), findsOneWidget);
      expect(find.text('Manajemen Data'), findsOneWidget);
      expect(find.text('Mode Gelap'), findsOneWidget);
      expect(find.text('Mata Uang'), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    late ThemeProvider themeProvider;
    late TransactionProvider transactionProvider;

    setUp(() {
      // Mock SharedPreferences
      MockSharedPreferences.setMockInitialValues({
        'currency': 'IDR',
        'transactions_backup_v2': '[]',
        'budgets': '[]',
        'cached_exchange_rates': '{"IDR":15523.50}',
        'cached_exchange_time': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      themeProvider = ThemeProvider();
      transactionProvider = TransactionProvider();
    });

    testWidgets('Bottom Navigation', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify bottom navigation exists
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Test navigation to transactions
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Test navigation to budgets
      await tester.tap(find.byIcon(Icons.account_balance_wallet));
      await tester.pumpAndSettle();

      // Test navigation to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan'), findsOneWidget);
    });
  });

  group('Currency Conversion Tests', () {
    late ThemeProvider themeProvider;
    late TransactionProvider transactionProvider;

    setUp(() {
      // Mock SharedPreferences
      MockSharedPreferences.setMockInitialValues({
        'currency': 'IDR',
        'transactions_backup_v2': '[]',
        'budgets': '[]',
        'cached_exchange_rates': '{"IDR":15523.50}',
        'cached_exchange_time': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      themeProvider = ThemeProvider();
      transactionProvider = TransactionProvider();
    });

    testWidgets('Currency Display in Transactions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: TransactionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify currency display elements exist
      // This test may need adjustment based on actual transaction data
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Display Currency Change Converts Transactions', (WidgetTester tester) async {
      // Create a transaction provider with mock data
      transactionProvider = TransactionProvider();

      // Pump a minimal widget tree to allow provider to work
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );

      // Wait for provider initialization
      await tester.pumpAndSettle();

      // Add a sample transaction in IDR
      final sampleTransaction = model.Transaction(
        title: 'Test Transaction',
        amount: 100000,
        category: 'Test',
        date: DateTime.now(),
        type: 'expense',
        originalCurrency: 'IDR',
        originalAmount: 100000,
        transactionCurrency: 'IDR',
      );

      await transactionProvider.addTransaction(sampleTransaction, skipBackup: true);
      await tester.pumpAndSettle();

      // Verify initial state
      expect(transactionProvider.displayCurrency, 'IDR');
      expect(transactionProvider.transactions.length, 1);
      expect(transactionProvider.transactions.first.amount, 100000);
      expect(transactionProvider.transactions.first.transactionCurrency, 'IDR');

      // Change display currency to USD
      await transactionProvider.setDisplayCurrency('USD');
      await tester.pumpAndSettle();

      // Verify transaction was converted
      expect(transactionProvider.displayCurrency, 'USD');
      expect(transactionProvider.transactions.length, 1);
      // Amount should be converted (approximately 100000 / 15523.50 ≈ 6.44)
      expect(transactionProvider.transactions.first.amount, closeTo(6.44, 0.1));
      expect(transactionProvider.transactions.first.transactionCurrency, 'USD');
      // Original currency and amount should remain unchanged
      expect(transactionProvider.transactions.first.originalCurrency, 'IDR');
      expect(transactionProvider.transactions.first.originalAmount, 100000);
    });
  });

  testWidgets('App Integration Test', (WidgetTester tester) async {
    // Test that the app builds and runs without errors
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify main screens are accessible
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Test navigation to settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan'), findsOneWidget);

    // Test currency dialog in settings
    await tester.tap(find.text('Mata Uang'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Mata Uang'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    // Navigate back to home
    await tester.tap(find.byIcon(Icons.dashboard));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('Error Handling Test', (WidgetTester tester) async {
    // Test error boundary
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify no errors are shown initially
    expect(find.text('Oops! Terjadi Kesalahan'), findsNothing);
  });
}
