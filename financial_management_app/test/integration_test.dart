import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finflow/main.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/models/transaction.dart' as model;
import 'package:finflow/models/budget.dart';
import 'package:finflow/services/database_service.dart';
import 'package:finflow/services/shared_prefs_service.dart';
import 'package:finflow/utils/constants.dart';

void main() {
  group('Database Persistence Tests', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService();
      // Clear any existing data
      await dbService.clearAllData();
    });

    tearDown(() async {
      await dbService.close();
    });

    test('Database initialization and table creation', () async {
      final db = await dbService.database;

      // Verify database is initialized
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);

      // Check if tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );

      final tableNames = tables.map((t) => t['name'] as String).toList();

      expect(tableNames, contains('transactions'));
      expect(tableNames, contains('budgets'));
      expect(tableNames, contains('categories'));
    });

    test('Insert and retrieve transaction with currency', () async {
      final transaction = model.Transaction(
        title: 'Test Transaction',
        amount: 100000,
        category: 'Makanan',
        date: DateTime.now(),
        type: 'expense',
        description: 'Test description',
        isFavorite: false,
        icon: '🍔',
        color: '#EF4444',
        transactionCurrency: 'IDR',
        originalCurrency: 'IDR',
        originalAmount: 100000,
      );

      // Insert transaction
      final id = await dbService.insertTransaction(transaction);
      expect(id, isNotNull);
      expect(id, greaterThan(0));

      // Retrieve transactions
      final transactions = await dbService.getTransactions();
      expect(transactions.length, greaterThan(0));

      final retrieved = transactions.firstWhere((t) => t.id == id);
      expect(retrieved.title, equals('Test Transaction'));
      expect(retrieved.amount, equals(100000));
      expect(retrieved.transactionCurrency, equals('IDR'));
      expect(retrieved.originalCurrency, equals('IDR'));
    });

    test('Insert and retrieve budget', () async {
      final budget = Budget(
        category: 'Makanan',
        amountLimit: 1000000,
        currentAmount: 0.0,
        monthYear: '2024-01',
        icon: '🍔',
        color: '#EF4444',
      );

      // Insert budget
      final id = await dbService.insertBudget(budget);
      expect(id, isNotNull);
      expect(id, greaterThan(0));

      // Retrieve budgets
      final budgets = await dbService.getBudgets();
      expect(budgets.length, greaterThan(0));

      final retrieved = budgets.firstWhere((b) => b.id == id);
      expect(retrieved.category, equals('Makanan'));
      expect(retrieved.amountLimit, equals(1000000));
      expect(retrieved.currentAmount, equals(0.0));
    });

    test('Budget auto-update on expense transaction', () async {
      // Create budget
      final budget = Budget(
        category: 'Makanan',
        amountLimit: 1000000,
        currentAmount: 0.0,
        monthYear: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
        icon: '🍔',
        color: '#EF4444',
      );

      final budgetId = await dbService.insertBudget(budget);

      // Create expense transaction
      final transaction = model.Transaction(
        title: 'Lunch',
        amount: 50000,
        category: 'Makanan',
        date: DateTime.now(),
        type: 'expense',
        description: 'Lunch payment',
        isFavorite: false,
        icon: '🍔',
        color: '#EF4444',
        transactionCurrency: 'IDR',
        originalCurrency: 'IDR',
        originalAmount: 50000,
      );

      await dbService.insertTransaction(transaction);

      // Check if budget was updated
      final budgets = await dbService.getBudgets();
      final updatedBudget = budgets.firstWhere((b) => b.id == budgetId);

      expect(updatedBudget.currentAmount, equals(50000));
    });

    test('Currency statistics calculation', () async {
      // Insert transactions in different currencies
      final idrTransaction = model.Transaction(
        title: 'IDR Transaction',
        amount: 100000,
        category: 'Makanan',
        date: DateTime.now(),
        type: 'expense',
        transactionCurrency: 'IDR',
        originalCurrency: 'IDR',
        originalAmount: 100000,
      );

      final usdTransaction = model.Transaction(
        title: 'USD Transaction',
        amount: 1552300, // 100 USD * 15523 rate
        category: 'Belanja',
        date: DateTime.now(),
        type: 'expense',
        transactionCurrency: 'USD',
        originalCurrency: 'USD',
        originalAmount: 100,
      );

      await dbService.insertTransaction(idrTransaction);
      await dbService.insertTransaction(usdTransaction);

      // Get currency stats
      final stats = await dbService.getCurrencyStats();

      expect(stats.containsKey('IDR_expense'), isTrue);
      expect(stats.containsKey('USD_expense'), isTrue);
      expect(stats['IDR_expense'], equals(100000));
      expect(stats['USD_expense'], equals(1552300));
    });
  });

  group('SharedPreferences Persistence Tests', () {
    late SharedPrefsService prefsService;

    setUp(() {
      prefsService = SharedPrefsService();
    });

    test('Currency preference persistence', () async {
      // Set currency
      await prefsService.setCurrency('USD');

      // Retrieve currency
      final currency = await prefsService.getCurrency();
      expect(currency, equals('USD'));

      // Change currency
      await prefsService.setCurrency('EUR');
      final newCurrency = await prefsService.getCurrency();
      expect(newCurrency, equals('EUR'));
    });

    test('Budget alert preference persistence', () async {
      // Set budget alert
      await prefsService.setBudgetAlert(true);

      // Retrieve budget alert
      final alert = await prefsService.getBudgetAlert();
      expect(alert, isTrue);

      // Change budget alert
      await prefsService.setBudgetAlert(false);
      final newAlert = await prefsService.getBudgetAlert();
      expect(newAlert, isFalse);
    });

    test('User name preference persistence', () async {
      // Set user name
      await prefsService.setUserName('Test User');

      // Retrieve user name
      final name = await prefsService.getUserName();
      expect(name, equals('Test User'));

      // Change user name
      await prefsService.setUserName('New User');
      final newName = await prefsService.getUserName();
      expect(newName, equals('New User'));
    });
  });

  group('Edge Cases and Error Handling Tests', () {
    late TransactionProvider transactionProvider;

    setUp(() {
      transactionProvider = TransactionProvider();
    });

    testWidgets('Invalid transaction data handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: ThemeProvider()),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test with empty title
      final invalidTransaction = model.Transaction(
        title: '',
        amount: 100000,
        category: 'Makanan',
        date: DateTime.now(),
        type: 'expense',
        transactionCurrency: 'IDR',
      );

      // This should throw an error
      expect(
        () async => await transactionProvider.addTransaction(invalidTransaction),
        throwsA(isA<Exception>()),
      );

      // Test with negative amount
      final negativeTransaction = model.Transaction(
        title: 'Negative Amount',
        amount: -1000,
        category: 'Makanan',
        date: DateTime.now(),
        type: 'expense',
        transactionCurrency: 'IDR',
      );

      expect(
        () async => await transactionProvider.addTransaction(negativeTransaction),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('Currency conversion edge cases', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: ThemeProvider()),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test same currency conversion
      final result = await transactionProvider.convertCurrency(
        amount: 100,
        fromCurrency: 'IDR',
        toCurrency: 'IDR',
      );

      expect(result, equals(100));

      // Test unsupported currency conversion (should return original amount)
      final unsupportedResult = await transactionProvider.convertCurrency(
        amount: 100,
        fromCurrency: 'XYZ',
        toCurrency: 'IDR',
      );

      expect(unsupportedResult, equals(100));
    });

    testWidgets('Budget calculation edge cases', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: ThemeProvider()),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test expense for category with no budget
      final expenseWithoutBudget = model.Transaction(
        title: 'Expense without budget',
        amount: 50000,
        category: 'NonExistentCategory',
        date: DateTime.now(),
        type: 'expense',
        transactionCurrency: 'IDR',
      );

      await transactionProvider.addTransaction(expenseWithoutBudget);

      // Should not crash, just no budget update
      expect(transactionProvider.error, isEmpty);
    });
  });

  group('Performance Tests', () {
    late TransactionProvider transactionProvider;

    setUp(() {
      transactionProvider = TransactionProvider();
    });

    testWidgets('Large dataset handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: ThemeProvider()),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add multiple transactions
      final startTime = DateTime.now();

      for (int i = 0; i < 50; i++) {
        final transaction = model.Transaction(
          title: 'Bulk Transaction $i',
          amount: 10000 + i * 1000,
          category: 'Makanan',
          date: DateTime.now().subtract(Duration(days: i)),
          type: i % 2 == 0 ? 'expense' : 'income',
          transactionCurrency: 'IDR',
        );

        await transactionProvider.addTransaction(transaction);
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Should complete within reasonable time (less than 30 seconds)
      expect(duration.inSeconds, lessThan(30));

      // Verify all transactions were added
      expect(transactionProvider.transactions.length, greaterThanOrEqualTo(50));
    });

    testWidgets('Currency formatting performance', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: ThemeProvider()),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test currency formatting for various amounts
      final startTime = DateTime.now();

      for (int i = 0; i < 100; i++) {
        final formatted = transactionProvider.formatCurrency(i * 1000.0);
        expect(formatted, isNotNull);
        expect(formatted, isNotEmpty);
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Should complete quickly (less than 1 second)
      expect(duration.inMilliseconds, lessThan(1000));
    });
  });

  group('Cross-platform Compatibility Tests', () {
    test('Constants availability', () {
      // Test that all required constants are available
      expect(AppCurrencies.supportedCurrencies, isNotEmpty);
      expect(AppCurrencies.currencySymbols, isNotEmpty);
      expect(AppCurrencies.currencyFlags, isNotEmpty);
      expect(AppCurrencies.fallbackRates, isNotEmpty);

      // Test that IDR is included
      expect(AppCurrencies.supportedCurrencies, contains('IDR'));
      expect(AppCurrencies.currencySymbols['IDR'], equals('Rp'));
    });

    test('Color constants', () {
      expect(AppColors.primary, isNotNull);
      expect(AppColors.secondary, isNotNull);
      expect(AppColors.accent, isNotNull);
      expect(AppColors.incomeColor, isNotNull);
      expect(AppColors.expenseColor, isNotNull);
    });

    test('Theme constants', () {
      expect(AppTheme.lightTheme, isNotNull);
      expect(AppTheme.darkTheme, isNotNull);
    });
  });

  group('Network and API Tests', () {
    late TransactionProvider transactionProvider;

    setUp(() {
      transactionProvider = TransactionProvider();
    });

    testWidgets('Exchange rate loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: ThemeProvider()),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test that exchange rates are loaded
      await Future.delayed(const Duration(seconds: 2)); // Wait for API call

      // Should have some exchange rates loaded (either from API or fallback)
      expect(transactionProvider.exchangeRates, isNotEmpty);

      // Should have USD to IDR rate
      expect(transactionProvider.exchangeRates.containsKey('IDR'), isTrue);
      expect(transactionProvider.usdToIdrRate, greaterThan(0));
    });

    testWidgets('Exchange rate refresh', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: ThemeProvider()),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialRates = Map<String, double>.from(transactionProvider.exchangeRates);
      final initialUpdateTime = transactionProvider.lastRateUpdate;

      // Refresh rates
      await transactionProvider.refreshExchangeRates();

      // Rates should be updated (or at least attempted)
      expect(transactionProvider.isLoadingRates, isFalse);
    });
  });

  group('Data Integrity Tests', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService();
      await dbService.clearAllData();
    });

    tearDown(() async {
      await dbService.close();
    });

    test('Transaction data integrity', () async {
      // Insert transaction with all required fields
      final transaction = model.Transaction(
        title: 'Integrity Test',
        amount: 100000,
        category: 'Makanan',
        date: DateTime.now(),
        type: 'expense',
        description: 'Testing data integrity',
        isFavorite: true,
        icon: '🍔',
        color: '#EF4444',
        transactionCurrency: 'IDR',
        originalCurrency: 'IDR',
        originalAmount: 100000,
      );

      final id = await dbService.insertTransaction(transaction);

      // Retrieve and verify all fields
      final transactions = await dbService.getTransactions();
      final retrieved = transactions.firstWhere((t) => t.id == id);

      expect(retrieved.title, equals(transaction.title));
      expect(retrieved.amount, equals(transaction.amount));
      expect(retrieved.category, equals(transaction.category));
      expect(retrieved.type, equals(transaction.type));
      expect(retrieved.description, equals(transaction.description));
      expect(retrieved.isFavorite, equals(transaction.isFavorite));
      expect(retrieved.icon, equals(transaction.icon));
      expect(retrieved.color, equals(transaction.color));
      expect(retrieved.transactionCurrency, equals(transaction.transactionCurrency));
      expect(retrieved.originalCurrency, equals(transaction.originalCurrency));
      expect(retrieved.originalAmount, equals(transaction.originalAmount));
    });

    test('Budget data integrity', () async {
      final budget = Budget(
        category: 'Transportasi',
        amountLimit: 500000,
        currentAmount: 250000,
        monthYear: '2024-01',
        icon: '🚗',
        color: '#3B82F6',
      );

      final id = await dbService.insertBudget(budget);

      final budgets = await dbService.getBudgets();
      final retrieved = budgets.firstWhere((b) => b.id == id);

      expect(retrieved.category, equals(budget.category));
      expect(retrieved.amountLimit, equals(budget.amountLimit));
      expect(retrieved.currentAmount, equals(budget.currentAmount));
      expect(retrieved.monthYear, equals(budget.monthYear));
      expect(retrieved.icon, equals(budget.icon));
      expect(retrieved.color, equals(budget.color));
    });
  });
}
