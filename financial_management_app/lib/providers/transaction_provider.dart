import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // TAMBAHKAN IMPORT
import 'package:intl/intl.dart';
import '../models/transaction.dart' as model;
import '../models/budget.dart';
import '../services/database_service.dart';
import '../utils/constants.dart'; // IMPORT CONSTANTS

class TransactionProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<model.Transaction> _transactions = [];
  List<Budget> _budgets = [];
  bool _isLoading = false;
  String _error = '';
  
  // TAMBAHKAN CURRENCY-RELATED FIELDS
  String _displayCurrency = 'IDR';
  Map<String, double> _exchangeRates = {};
  bool _isLoadingRates = false;
  DateTime? _lastRateUpdate;
  
  // Cache untuk statistik
  double? _cachedTotalIncome;
  double? _cachedTotalExpense;

  List<model.Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // TAMBAHKAN GETTERS UNTUK CURRENCY
  String get displayCurrency => _displayCurrency;
  Map<String, double> get exchangeRates => _exchangeRates;
  bool get isLoadingRates => _isLoadingRates;
  DateTime? get lastRateUpdate => _lastRateUpdate;
  
  String get formattedLastRateUpdate {
    if (_lastRateUpdate == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(_lastRateUpdate!);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
  
  // TAMBAHKAN METHOD UNTUK FORMAT CURRENCY
  String formatCurrency(double amount, [String? currencyCode]) {
    final code = currencyCode ?? _displayCurrency;
    final symbol = AppCurrencies.currencySymbols[code] ?? code;
    final decimalDigits = code == 'IDR' ? 0 : 2;
    
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    
    return formatter.format(amount);
  }
  
  // TAMBAHKAN METHOD UNTUK GET CURRENCY FLAG
  String getCurrencyFlag(String currencyCode) {
    return AppCurrencies.currencyFlags[currencyCode] ?? '🏳️';
  }
  
  double get totalIncome {
    if (_cachedTotalIncome != null && !_isLoading) {
      return _cachedTotalIncome!;
    }

    try {
      double total = 0;
      for (var t in _transactions) {
        if (t.type == 'income') {
          // Convert amount ke display currency jika berbeda
          if (t.transactionCurrency != _displayCurrency) {
            final convertedAmount = convertAmountToDisplayCurrency(t.amount, t.transactionCurrency);
            total += convertedAmount;
          } else {
            total += t.amount;
          }
        }
      }
      _cachedTotalIncome = total;
      return total;
    } catch (e) {
      print('[PROVIDER ERROR] totalIncome: $e');
      return 0.0;
    }
  }
  
  double get totalExpense {
    if (_cachedTotalExpense != null && !_isLoading) {
      return _cachedTotalExpense!;
    }

    try {
      double total = 0;
      for (var t in _transactions) {
        if (t.type == 'expense') {
          // Convert amount ke display currency jika berbeda
          if (t.transactionCurrency != _displayCurrency) {
            final convertedAmount = convertAmountToDisplayCurrency(t.amount, t.transactionCurrency);
            total += convertedAmount;
          } else {
            total += t.amount;
          }
        }
      }
      _cachedTotalExpense = total;
      return total;
    } catch (e) {
      print('[PROVIDER ERROR] totalExpense: $e');
      return 0.0;
    }
  }
  
  double get balance => totalIncome - totalExpense;
  
  TransactionProvider() {
    print('[PROVIDER] TransactionProvider constructor called');
    _initialize();
  }
  
  Future<void> _initialize() async {
    print('[PROVIDER] Starting initialization...');

    try {
      // Load data dengan delay untuk memastikan database siap
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadDisplayCurrency(); // Load display currency first
      await loadTransactions();
      await loadBudgets();
      // TAMBAHKAN LOAD EXCHANGE RATES
      await _loadExchangeRates();
      print('[PROVIDER] Initialization complete');
    } catch (e) {
      print('[PROVIDER ERROR] _initialize: $e');
      _error = 'Initialization error: $e';
    }
  }
  
  // TAMBAHKAN METHOD UNTUK LOAD DISPLAY CURRENCY
  Future<void> _loadDisplayCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _displayCurrency = prefs.getString('currency') ?? 'IDR';
      print('[PROVIDER] Display currency loaded: $_displayCurrency');
    } catch (e) {
      print('[PROVIDER ERROR] _loadDisplayCurrency: $e');
      _displayCurrency = 'IDR';
    }
  }

  // TAMBAHKAN METHOD UNTUK LOAD EXCHANGE RATES
  Future<void> _loadExchangeRates() async {
    if (_isLoadingRates) return;
    
    _isLoadingRates = true;
    notifyListeners();
    
    try {
      print('[PROVIDER] Loading exchange rates...');
      
      // Coba ambil dari SharedPreferences cache dulu
      final prefs = await SharedPreferences.getInstance();
      final cachedRates = prefs.getString('cached_exchange_rates');
      final cachedTime = prefs.getInt('cached_exchange_time');
      
      if (cachedRates != null && cachedTime != null) {
        final cacheAge = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(cachedTime),
        );
        
        // Jika cache masih valid (1 jam), gunakan cache
        if (cacheAge < const Duration(hours: 1)) {
          _exchangeRates = Map<String, double>.from(json.decode(cachedRates));
          _lastRateUpdate = DateTime.fromMillisecondsSinceEpoch(cachedTime);
          print('[PROVIDER] Using cached exchange rates');
          _isLoadingRates = false;
          notifyListeners();
          return;
        }
      }
      
      // Ambil dari Frankfurter API (GRATIS, NO API KEY!)
      final response = await http.get(
        Uri.parse('https://api.frankfurter.app/latest?from=USD'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _exchangeRates = Map<String, double>.from(data['rates']);
        _lastRateUpdate = DateTime.now();
        
        // Simpan ke cache
        await prefs.setString('cached_exchange_rates', json.encode(_exchangeRates));
        await prefs.setInt('cached_exchange_time', _lastRateUpdate!.millisecondsSinceEpoch);
        
        print('[PROVIDER] Exchange rates loaded successfully');
      } else {
        throw Exception('Failed to load exchange rates: ${response.statusCode}');
      }
    } catch (e) {
      print('[PROVIDER ERROR] _loadExchangeRates: $e');
      
      // Gunakan fallback rates dari constants
      _exchangeRates = AppCurrencies.fallbackRates['USD'] ?? {'IDR': 15523.50};
      _lastRateUpdate = DateTime.now();
    } finally {
      _isLoadingRates = false;
      notifyListeners();
    }
  }
  
  // TAMBAHKAN METHOD UNTUK REFRESH RATES
  Future<void> refreshExchangeRates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_exchange_rates');
    await prefs.remove('cached_exchange_time');
    
    await _loadExchangeRates();
  }
  
  // TAMBAHKAN METHOD UNTUK CONVERT CURRENCY
  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return amount;
    
    try {
      // Jika dari USD ke IDR, gunakan exchange rates yang sudah ada
      if (fromCurrency == 'USD' && toCurrency == 'IDR') {
        return amount * (_exchangeRates['IDR'] ?? 15523.50);
      }
      
      // Untuk konversi lain, hitung langsung dari rates
      if (_exchangeRates.isNotEmpty) {
        // Logika konversi sederhana (untuk demo)
        if (fromCurrency == 'USD') {
          final toRate = _exchangeRates[toCurrency];
          if (toRate != null) return amount * toRate;
        }
        
        // Fallback: gunakan hardcoded rates
        final fallbackRates = AppCurrencies.fallbackRates[fromCurrency];
        if (fallbackRates != null && fallbackRates.containsKey(toCurrency)) {
          return amount * fallbackRates[toCurrency]!;
        }
      }
      
      return amount;
    } catch (e) {
      print('[PROVIDER ERROR] convertCurrency: $e');
      return amount;
    }
  }
  
  // TAMBAHKAN METHOD UNTUK SET DISPLAY CURRENCY
  Future<void> setDisplayCurrency(String currencyCode) async {
    if (currencyCode == _displayCurrency) return;

    print('[PROVIDER] Changing display currency from $_displayCurrency to $currencyCode');

    final oldCurrency = _displayCurrency;
    _displayCurrency = currencyCode;

    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', currencyCode);
      print('[PROVIDER] Display currency saved: $currencyCode');
    } catch (e) {
      print('[PROVIDER ERROR] Failed to save display currency: $e');
    }

    // Convert semua transaksi yang sudah ada ke currency baru
    print('[PROVIDER] Converting ${_transactions.length} transactions to new display currency...');

    for (var i = 0; i < _transactions.length; i++) {
      final transaction = _transactions[i];

      // Jika transaksi dalam currency yang berbeda dari yang baru
      if (transaction.transactionCurrency != currencyCode) {
        final convertedAmount = convertAmountToDisplayCurrency(transaction.amount, transaction.transactionCurrency);

        // Update transaksi dengan amount yang sudah dikonversi
        final updatedTransaction = model.Transaction(
          id: transaction.id,
          title: transaction.title,
          amount: convertedAmount,
          category: transaction.category,
          date: transaction.date,
          type: transaction.type,
          description: transaction.description,
          isFavorite: transaction.isFavorite,
          icon: transaction.icon,
          color: transaction.color,
          originalCurrency: transaction.originalCurrency, // Tetap gunakan original currency
          originalAmount: transaction.originalAmount, // Tetap gunakan original amount
          transactionCurrency: currencyCode, // Update ke currency baru
        );

        _transactions[i] = updatedTransaction;

        // Update di database jika bukan web
        if (!kIsWeb) {
          try {
            await _dbService.updateTransaction(updatedTransaction);
          } catch (e) {
            print('[PROVIDER ERROR] Failed to update transaction ${transaction.id} in database: $e');
          }
        }
      }
    }

    // Backup ke SharedPreferences
    await _saveToSharedPrefs();

    // Reset cache untuk menghitung ulang total dalam currency baru
    _cachedTotalIncome = null;
    _cachedTotalExpense = null;

    notifyListeners();
    print('[PROVIDER] Display currency changed successfully, all transactions converted');
  }
  
  // TAMBAHKAN METHOD UNTUK GET USD TO IDR RATE
  double get usdToIdrRate {
    return _exchangeRates['IDR'] ?? 15523.50;
  }

  // TAMBAHKAN METHOD UNTUK CONVERT AMOUNT TO DISPLAY CURRENCY
  double convertAmountToDisplayCurrency(double amount, String fromCurrency) {
    if (fromCurrency == _displayCurrency) return amount;

    try {
      // Jika exchange rates tersedia, gunakan untuk konversi akurat
      if (_exchangeRates.isNotEmpty) {
        // Konversi melalui USD sebagai base currency
        // Formula: amount_in_fromCurrency * (USD_per_fromCurrency) * (toCurrency_per_USD)

        // Dapatkan rate dari fromCurrency ke USD
        double fromToUsdRate;
        if (fromCurrency == 'USD') {
          fromToUsdRate = 1.0;
        } else {
          fromToUsdRate = _exchangeRates[fromCurrency] ?? _getFallbackRate(fromCurrency, 'USD');
          if (fromToUsdRate == 0) fromToUsdRate = _getFallbackRate(fromCurrency, 'USD');
        }

        // Dapatkan rate dari USD ke display currency
        double usdToDisplayRate;
        if (_displayCurrency == 'USD') {
          usdToDisplayRate = 1.0;
        } else {
          usdToDisplayRate = _exchangeRates[_displayCurrency] ?? _getFallbackRate('USD', _displayCurrency);
          if (usdToDisplayRate == 0) usdToDisplayRate = _getFallbackRate('USD', _displayCurrency);
        }

        // Lakukan konversi
        final usdAmount = amount / fromToUsdRate; // Convert fromCurrency to USD
        final convertedAmount = usdAmount * usdToDisplayRate; // Convert USD to display currency

        print('[PROVIDER] Currency conversion: $amount $fromCurrency → $convertedAmount $_displayCurrency');
        print('  Rate $fromCurrency to USD: $fromToUsdRate');
        print('  Rate USD to $_displayCurrency: $usdToDisplayRate');

        return convertedAmount;
      }

      // Fallback ke hardcoded rates jika API rates tidak tersedia
      return _convertUsingFallbackRates(amount, fromCurrency);

    } catch (e) {
      print('[PROVIDER ERROR] _convertAmountToDisplayCurrency: $e');
      print('  Amount: $amount, From: $fromCurrency, To: $_displayCurrency');
      return amount; // Return as-is jika error
    }
  }

  // Helper method untuk mendapatkan fallback rate
  double _getFallbackRate(String fromCurrency, String toCurrency) {
    final fallbackRates = AppCurrencies.fallbackRates[fromCurrency];
    if (fallbackRates != null && fallbackRates.containsKey(toCurrency)) {
      return fallbackRates[toCurrency]!;
    }

    // Jika tidak ada direct rate, coba inverse dari rates yang ada
    final inverseRates = AppCurrencies.fallbackRates[toCurrency];
    if (inverseRates != null && inverseRates.containsKey(fromCurrency)) {
      return 1.0 / inverseRates[fromCurrency]!;
    }

    // Default fallback rates
    if (fromCurrency == 'IDR' && toCurrency == 'USD') return 0.000064;
    if (fromCurrency == 'USD' && toCurrency == 'IDR') return 15523.50;
    if (fromCurrency == 'EUR' && toCurrency == 'USD') return 1.10;
    if (fromCurrency == 'USD' && toCurrency == 'EUR') return 0.91;
    if (fromCurrency == 'GBP' && toCurrency == 'USD') return 1.28;
    if (fromCurrency == 'USD' && toCurrency == 'GBP') return 0.78;
    if (fromCurrency == 'JPY' && toCurrency == 'USD') return 0.0069;
    if (fromCurrency == 'USD' && toCurrency == 'JPY') return 145.22;

    return 1.0; // Default no conversion
  }

  // Fallback conversion menggunakan hardcoded rates
  double _convertUsingFallbackRates(double amount, String fromCurrency) {
    try {
      // Direct conversion jika tersedia
      final directRates = AppCurrencies.fallbackRates[fromCurrency];
      if (directRates != null && directRates.containsKey(_displayCurrency)) {
        return amount * directRates[_displayCurrency]!;
      }

      // Inverse conversion jika tersedia
      final inverseRates = AppCurrencies.fallbackRates[_displayCurrency];
      if (inverseRates != null && inverseRates.containsKey(fromCurrency)) {
        return amount / inverseRates[fromCurrency]!;
      }

      // Konversi melalui USD sebagai intermediate
      final fromToUsd = _getFallbackRate(fromCurrency, 'USD');
      final usdToDisplay = _getFallbackRate('USD', _displayCurrency);

      if (fromToUsd > 0 && usdToDisplay > 0) {
        final usdAmount = fromCurrency == 'USD' ? amount : amount / fromToUsd;
        final convertedAmount = _displayCurrency == 'USD' ? usdAmount : usdAmount * usdToDisplay;
        return convertedAmount;
      }

      print('[PROVIDER WARNING] No conversion rate found for $fromCurrency to $_displayCurrency, returning original amount');
      return amount;

    } catch (e) {
      print('[PROVIDER ERROR] _convertUsingFallbackRates: $e');
      return amount;
    }
  }

  // TAMBAHKAN METHOD UNTUK GET EXPENSE FOR CATEGORY THIS MONTH
  double getExpenseForCategoryThisMonth(String category) {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    try {
      double total = 0;
      for (var transaction in _transactions) {
        final transactionMonth = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
        if (transaction.type == 'expense' &&
            transaction.category == category &&
            transactionMonth == currentMonth) {
          // Convert amount ke display currency jika berbeda
          if (transaction.transactionCurrency != _displayCurrency) {
            final convertedAmount = convertAmountToDisplayCurrency(transaction.amount, transaction.transactionCurrency);
            total += convertedAmount;
          } else {
            total += transaction.amount;
          }
        }
      }
      return total;
    } catch (e) {
      print('[PROVIDER ERROR] getExpenseForCategoryThisMonth: $e');
      return 0.0;
    }
  }

  // TAMBAHKAN METHOD UNTUK RECALCULATE BUDGETS FOR MONTH
  Future<void> recalculateBudgetsForMonth(int year, int month) async {
    try {
      print('[PROVIDER] Recalculating budgets for $year-$month');

      final targetMonth = '$year-${month.toString().padLeft(2, '0')}';

      // Reset currentAmount untuk semua budget bulan tersebut
      for (var budget in _budgets) {
        if (budget.monthYear == targetMonth) {
          final resetBudget = Budget(
            id: budget.id,
            category: budget.category,
            amountLimit: budget.amountLimit,
            currentAmount: 0.0,
            monthYear: budget.monthYear,
            icon: budget.icon,
            color: budget.color,
          );

          _budgets[_budgets.indexWhere((b) => b.id == budget.id)] = resetBudget;

          if (!kIsWeb) {
            await _dbService.updateBudget(resetBudget);
          }
        }
      }

      // Hitung ulang dari transaksi bulan tersebut
      for (var transaction in _transactions) {
        final transactionMonth = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
        if (transaction.type == 'expense' && transactionMonth == targetMonth) {
          await _updateBudgetOnTransaction(transaction);
        }
      }

      print('[PROVIDER] Budgets recalculated for $year-$month');
      notifyListeners();
    } catch (e) {
      print('[PROVIDER ERROR] recalculateBudgetsForMonth: $e');
    }
  }
  
  Future<void> loadTransactions() async {
    print('[PROVIDER] === LOAD TRANSACTIONS START ===');
    
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      if (kIsWeb) {
        print('[PROVIDER] Platform: Web - Using SharedPreferences');
        _transactions = await _loadFromSharedPrefs();
      } else {
        print('[PROVIDER] Platform: Mobile - Using SQLite');
        _transactions = await _dbService.getTransactions();
        
        // Backup data ke SharedPreferences sebagai fallback
        await _saveToSharedPrefs();
      }
      
      print('[PROVIDER] Loaded ${_transactions.length} transactions');
      
      // Validasi data yang dimuat
      _validateLoadedData();
      
      // Reset cache
      _cachedTotalIncome = null;
      _cachedTotalExpense = null;

      // JANGAN tambah sample data - mulai dengan aplikasi kosong
      // User akan menambah transaksi sendiri
      
      print('[PROVIDER] Statistics after load:');
      print('  - Total transactions: ${_transactions.length}');
      print('  - Total income: $totalIncome');
      print('  - Total expense: $totalExpense');
      print('  - Balance: $balance');
      
    } catch (e) {
      _error = 'Failed to load transactions: $e';
      print('[PROVIDER ERROR] loadTransactions: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Fallback: coba load dari SharedPreferences
      try {
        print('[PROVIDER] Trying SharedPreferences fallback...');
        _transactions = await _loadFromSharedPrefs();
        print('[PROVIDER] Fallback loaded ${_transactions.length} transactions');
      } catch (e2) {
        print('[PROVIDER ERROR] Fallback also failed: $e2');
        _transactions = []; // Reset ke empty array
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      print('[PROVIDER] === LOAD TRANSACTIONS END ===');
    }
  }
  
  void _validateLoadedData() {
    int invalidCount = 0;
    for (var transaction in _transactions) {
      if (transaction.amount.isNaN || transaction.amount <= 0) {
        print('[PROVIDER WARNING] Invalid transaction: ${transaction.title} - amount: ${transaction.amount}');
        invalidCount++;
      }
    }
    
    if (invalidCount > 0) {
      print('[PROVIDER WARNING] Found $invalidCount invalid transactions');
    }
  }
  
  Future<void> _addSampleTransactions() async {
    print('[PROVIDER] Adding sample transactions...');
    
    final sampleTransactions = [
      model.Transaction(
        title: 'Gaji Bulanan',
        amount: 5000000,
        category: 'Gaji',
        date: DateTime.now(),
        type: 'income',
        description: 'Gaji bulan Januari',
        isFavorite: false,
        icon: '💰',
        color: '#10B981',
        transactionCurrency: 'IDR',
      ),
      model.Transaction(
        title: 'Makan Siang',
        amount: 75000,
        category: 'Makanan',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: 'expense',
        description: 'Makan siang di restoran',
        isFavorite: true,
        icon: '🍔',
        color: '#EF4444',
        transactionCurrency: 'IDR',
      ),
      // TAMBAHKAN SAMPLE DENGAN CURRENCY ASING
      model.Transaction(
        title: 'Amazon Purchase',
        amount: 99.99,
        category: 'Belanja',
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: 'expense',
        description: 'Beli buku dari Amazon',
        isFavorite: false,
        icon: '🛒',
        color: '#8B5CF6',
        originalCurrency: 'USD',
        originalAmount: 99.99,
        transactionCurrency: 'USD',
      ),
      model.Transaction(
        title: 'Bonus Project',
        amount: 2000000,
        category: 'Bonus',
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: 'income',
        description: 'Bonus selesai project',
        isFavorite: false,
        icon: '🎁',
        color: '#F59E0B',
        transactionCurrency: 'IDR',
      ),
    ];
    
    // JANGAN convert amount - biarkan dalam currency asli
    // Conversion hanya dilakukan saat display
    // sampleTransactions[2].amount tetap 99.99 USD
    
    for (var transaction in sampleTransactions) {
      try {
        await addTransaction(transaction, skipBackup: true);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('[PROVIDER ERROR] Failed to add sample transaction ${transaction.title}: $e');
      }
    }
    
    // Backup setelah semua sample ditambahkan
    await _saveToSharedPrefs();
    
    print('[PROVIDER] Sample transactions added');
  }
  
  // SharedPreferences untuk web/backup
  Future<List<model.Transaction>> _loadFromSharedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('transactions_backup_v2');
      
      if (json == null || json.isEmpty) {
        print('[PROVIDER] No backup found in SharedPreferences');
        return [];
      }
      
      print('[PROVIDER] Loading from SharedPreferences backup (${json.length} chars)');
      
      final List<dynamic> data = jsonDecode(json);
      final transactions = <model.Transaction>[];
      int errorCount = 0;
      
      for (var item in data) {
        try {
          final transaction = model.Transaction.fromMap(item);
          transactions.add(transaction);
        } catch (e) {
          errorCount++;
          print('[PROVIDER ERROR] Failed to parse transaction from backup: $e');
        }
      }
      
      if (errorCount > 0) {
        print('[PROVIDER WARNING] Failed to parse $errorCount transactions from backup');
      }
      
      print('[PROVIDER] Successfully loaded ${transactions.length} transactions from backup');
      return transactions;
    } catch (e) {
      print('[PROVIDER ERROR] _loadFromSharedPrefs: $e');
      return [];
    }
  }
  
  Future<void> _saveToSharedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_transactions.map((t) => t.toMap()).toList());
      await prefs.setString('transactions_backup_v2', json);
      print('[PROVIDER] Backup saved: ${_transactions.length} transactions');
    } catch (e) {
      print('[PROVIDER ERROR] _saveToSharedPrefs: $e');
    }
  }
  
  // ============ BUDGET AUTO-UPDATE METHODS ============
  
  Future<void> _updateBudgetOnTransaction(model.Transaction transaction) async {
    if (transaction.type != 'expense') return;

    try {
      print('[PROVIDER] Updating budget for expense: ${transaction.category}');

      final currentMonth = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

      // Cari budget untuk kategori dan bulan ini
      final matchingBudgets = _budgets.where((budget) {
        return budget.category == transaction.category &&
               budget.monthYear == currentMonth;
      }).toList();

      if (matchingBudgets.isNotEmpty) {
        for (var budget in matchingBudgets) {
          final oldAmount = budget.currentAmount;
          // Convert transaction amount ke display currency sebelum menambah ke budget
          final convertedTransactionAmount = transaction.transactionCurrency != _displayCurrency
            ? convertAmountToDisplayCurrency(transaction.amount, transaction.transactionCurrency)
            : transaction.amount;
          final newAmount = (oldAmount + convertedTransactionAmount).toDouble();

          print('[PROVIDER] Budget update:');
          print('  Category: ${budget.category}');
          print('  Month: ${budget.monthYear}');
          print('  Old amount: $oldAmount');
          print('  Transaction amount: ${transaction.amount} (${transaction.transactionCurrency})');
          print('  Converted amount: $convertedTransactionAmount (${_displayCurrency})');
          print('  New amount: $newAmount');

          // Update budget
          final updatedBudget = Budget(
            id: budget.id,
            category: budget.category,
            amountLimit: budget.amountLimit,
            currentAmount: newAmount,
            monthYear: budget.monthYear,
            icon: budget.icon,
            color: budget.color,
          );

          // Update di provider
          final index = _budgets.indexWhere((b) => b.id == budget.id);
          if (index != -1) {
            _budgets[index] = updatedBudget;
          }

          // Update di database
          if (!kIsWeb) {
            await _dbService.updateBudget(updatedBudget);
          }

          print('[PROVIDER] ✅ Budget updated successfully');

          // Check jika perlu notifikasi
          _checkBudgetNotification(updatedBudget);
        }

        notifyListeners();
      } else {
        print('[PROVIDER] ⚠️ No budget found for category: ${transaction.category} in month: $currentMonth');
      }
    } catch (e) {
      print('[PROVIDER ERROR] _updateBudgetOnTransaction: $e');
    }
  }
  
  void _checkBudgetNotification(Budget budget) {
    final percentage = budget.percentageUsed;
    
    if (percentage >= 90) {
      print('[PROVIDER] 🔴 BUDGET WARNING: ${budget.category} at ${percentage.toStringAsFixed(1)}%');
    } else if (percentage >= 75) {
      print('[PROVIDER] 🟡 BUDGET ALERT: ${budget.category} at ${percentage.toStringAsFixed(1)}%');
    }
  }
  
  // ============ MAIN TRANSACTION METHODS ============
  
  Future<void> addTransaction(model.Transaction transaction, {bool skipBackup = false}) async {
    print('[PROVIDER] === ADD TRANSACTION START ===');
    
    try {
      print('[PROVIDER] Adding transaction: ${transaction.title}');
      print('[PROVIDER] Amount: ${transaction.amount}');
      print('[PROVIDER] Currency: ${transaction.transactionCurrency}');
      print('[PROVIDER] Type: ${transaction.type}');
      
      // Validasi data
      if (transaction.title.isEmpty) {
        throw Exception('Transaction title cannot be empty');
      }
      
      if (transaction.amount <= 0) {
        throw Exception('Transaction amount must be positive');
      }
      
      // JANGAN convert ke display currency!
      // Transaksi harus disimpan dalam currency aslinya
      // Display conversion dilakukan di UI saat menampilkan
      
      if (kIsWeb) {
        // Web: gunakan SharedPreferences
        final newId = _transactions.isEmpty ? 1 : 
            (_transactions.map((t) => t.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
        transaction.id = newId;
        
        _transactions.insert(0, transaction);
        print('[PROVIDER] Added to memory with ID: $newId');
        
        // UPDATE BUDGET jika transaksi expense
        if (transaction.type == 'expense') {
          await _updateBudgetOnTransaction(transaction);
        }
        
        if (!skipBackup) {
          await _saveToSharedPrefs();
        }
      } else {
        // Mobile: gunakan SQLite
        final insertedId = await _dbService.insertTransaction(transaction);
        
        if (insertedId > 0) {
          transaction.id = insertedId;
          _transactions.insert(0, transaction);
          print('[PROVIDER] Added to SQLite with ID: $insertedId');
          
          // UPDATE BUDGET jika transaksi expense
          if (transaction.type == 'expense') {
            await _updateBudgetOnTransaction(transaction);
          }
          
          // Backup ke SharedPreferences
          if (!skipBackup) {
            await _saveToSharedPrefs();
          }
        } else {
          throw Exception('Failed to insert transaction into database');
        }
      }
      
      // Reset cache
      _cachedTotalIncome = null;
      _cachedTotalExpense = null;
      
      notifyListeners();
      print('[PROVIDER] Transaction added successfully');
      print('[PROVIDER] Total transactions: ${_transactions.length}');
      
    } catch (e) {
      _error = 'Failed to add transaction: $e';
      print('[PROVIDER ERROR] addTransaction: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Fallback strategy untuk mobile
      if (!kIsWeb && !skipBackup) {
        try {
          print('[PROVIDER] Attempting fallback to SharedPreferences...');
          
          final newId = _transactions.isEmpty ? 1 : 
              (_transactions.map((t) => t.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
          transaction.id = newId;
          
          _transactions.insert(0, transaction);
          
          // UPDATE BUDGET jika transaksi expense
          if (transaction.type == 'expense') {
            await _updateBudgetOnTransaction(transaction);
          }
          
          await _saveToSharedPrefs();
          
          _cachedTotalIncome = null;
          _cachedTotalExpense = null;
          
          notifyListeners();
          print('[PROVIDER] Fallback successful');
        } catch (e2) {
          print('[PROVIDER ERROR] Fallback also failed: $e2');
        }
      } else {
        notifyListeners();
      }
    }
    
    print('[PROVIDER] === ADD TRANSACTION END ===');
  }
  
  Future<void> updateTransaction(model.Transaction transaction) async {
    try {
      print('[PROVIDER] Updating transaction ID: ${transaction.id}');
      
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index == -1) {
        throw Exception('Transaction not found in memory');
      }
      
      // Simpan data lama untuk budget adjustment jika perlu
      final oldTransaction = _transactions[index];
      final wasExpense = oldTransaction.type == 'expense';
      final isExpense = transaction.type == 'expense';
      final categoryChanged = oldTransaction.category != transaction.category;
      final amountChanged = oldTransaction.amount != transaction.amount;
      
      _transactions[index] = transaction;
      
      if (kIsWeb) {
        await _saveToSharedPrefs();
      } else {
        await _dbService.updateTransaction(transaction);
        await _saveToSharedPrefs(); // Backup
      }
      
      // Handle budget updates jika ada perubahan yang relevan
      if ((wasExpense || isExpense) && (categoryChanged || amountChanged)) {
        print('[PROVIDER] Transaction update affects budgets, recalculating...');
        await _recalculateAllBudgets();
      }
      
      // Reset cache
      _cachedTotalIncome = null;
      _cachedTotalExpense = null;
      
      notifyListeners();
      print('[PROVIDER] Transaction updated successfully');
    } catch (e) {
      _error = 'Failed to update transaction: $e';
      print('[PROVIDER ERROR] updateTransaction: $e');
      notifyListeners();
    }
  }
  
  Future<void> deleteTransaction(int id) async {
    try {
      print('[PROVIDER] Deleting transaction ID: $id');
      
      // Cari transaksi sebelum dihapus
      final transactionToDelete = _transactions.firstWhere((t) => t.id == id);
      final wasExpense = transactionToDelete.type == 'expense';
      
      // Hapus dari memory
      final initialCount = _transactions.length;
      _transactions.removeWhere((t) => t.id == id);
      final finalCount = _transactions.length;
      
      print('[PROVIDER] Removed ${initialCount - finalCount} transaction(s) from memory');
      
      if (kIsWeb) {
        await _saveToSharedPrefs();
      } else {
        await _dbService.deleteTransaction(id);
        await _saveToSharedPrefs();
      }
      
      // Reset cache
      _cachedTotalIncome = null;
      _cachedTotalExpense = null;
      
      notifyListeners();
      print('[PROVIDER] Transaction deleted successfully');
    } catch (e) {
      _error = 'Failed to delete transaction: $e';
      print('[PROVIDER ERROR] deleteTransaction: $e');
      notifyListeners();
    }
  }
  
  Future<void> toggleFavorite(int id) async {
    try {
      print('[PROVIDER] Toggling favorite for transaction ID: $id');
      
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index == -1) {
        print('[PROVIDER WARNING] Transaction not found for ID: $id');
        return;
      }
      
      final oldStatus = _transactions[index].isFavorite;
      final newStatus = !oldStatus;
      
      _transactions[index].isFavorite = newStatus;
      print('[PROVIDER] Favorite changed: $oldStatus → $newStatus');
      
      if (kIsWeb) {
        await _saveToSharedPrefs();
      } else {
        await _dbService.toggleFavorite(id, newStatus);
        await _saveToSharedPrefs(); // Backup
      }
      
      notifyListeners();
      print('[PROVIDER] Favorite toggled successfully');
    } catch (e) {
      print('[PROVIDER ERROR] toggleFavorite: $e');
    }
  }
  
  void clearError() {
    _error = '';
    notifyListeners();
  }
  
  // ============ BUDGET RECALCULATION METHODS ============
  
  Future<void> _recalculateAllBudgets() async {
    try {
      print('[PROVIDER] Recalculating all budgets from transactions...');
      
      // Reset semua budget currentAmount ke 0
      for (var budget in _budgets) {
        final resetBudget = Budget(
          id: budget.id,
          category: budget.category,
          amountLimit: budget.amountLimit,
          currentAmount: 0.0,
          monthYear: budget.monthYear,
          icon: budget.icon,
          color: budget.color,
        );
        
        _budgets[_budgets.indexWhere((b) => b.id == budget.id)] = resetBudget;
        
        if (!kIsWeb) {
          await _dbService.updateBudget(resetBudget);
        }
      }
      
      // Hitung ulang dari transaksi
      for (var transaction in _transactions) {
        if (transaction.type == 'expense') {
          await _updateBudgetOnTransaction(transaction);
        }
      }
      
      print('[PROVIDER] All budgets recalculated');
      notifyListeners();
    } catch (e) {
      print('[PROVIDER ERROR] _recalculateAllBudgets: $e');
    }
  }
  
  // ============ BUDGET METHODS ============
  
  Future<void> loadBudgets() async {
    try {
      print('[PROVIDER] Loading budgets...');
      
      if (kIsWeb) {
        _budgets = await _loadBudgetsFromSharedPrefs();
        if (_budgets.isEmpty) {
          _budgets = _getDemoBudgets();
          await _saveBudgetsToSharedPrefs();
        }
        print('[PROVIDER] Loaded ${_budgets.length} budgets from SharedPreferences');
      } else {
        _budgets = await _dbService.getBudgets();
        if (_budgets.isEmpty) {
          _budgets = _getDemoBudgets();
          for (var budget in _budgets) {
            await _dbService.insertBudget(budget);
          }
        }
        print('[PROVIDER] Loaded ${_budgets.length} budgets from SQLite');
      }
    } catch (e) {
      _error = 'Failed to load budgets: $e';
      print('[PROVIDER ERROR] loadBudgets: $e');
      _budgets = _getDemoBudgets();
    }
    notifyListeners();
  }

  Future<List<Budget>> _loadBudgetsFromSharedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('budgets');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        return data.map((map) => Budget.fromMap(map)).toList();
      }
    } catch (e) {
      print('[PROVIDER ERROR] _loadBudgetsFromSharedPrefs: $e');
    }
    return [];
  }

  Future<void> _saveBudgetsToSharedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_budgets.map((b) => b.toMap()).toList());
      await prefs.setString('budgets', json);
      print('[PROVIDER] Budgets saved to SharedPreferences: ${_budgets.length} budgets');
    } catch (e) {
      print('[PROVIDER ERROR] _saveBudgetsToSharedPrefs: $e');
    }
  }

  List<Budget> _getDemoBudgets() {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    return [
      Budget(
        id: 1,
        category: 'Makanan',
        amountLimit: 1000000,
        currentAmount: 0.0,
        monthYear: currentMonth,
        icon: '🍔',
        color: '#EF4444',
      ),
      Budget(
        id: 2,
        category: 'Transportasi',
        amountLimit: 500000,
        currentAmount: 0.0,
        monthYear: currentMonth,
        icon: '🚗',
        color: '#3B82F6',
      ),
      Budget(
        id: 3,
        category: 'Belanja',
        amountLimit: 1500000,
        currentAmount: 0.0,
        monthYear: currentMonth,
        icon: '🛒',
        color: '#8B5CF6',
      ),
    ];
  }

  Future<void> addBudget(Budget budget) async {
    try {
      print('[PROVIDER] Adding budget: ${budget.category}');
      
      if (kIsWeb) {
        final newId = _budgets.isEmpty ? 1 :
            (_budgets.map((b) => b.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
        budget.id = newId;

        _budgets.add(budget);
        await _saveBudgetsToSharedPrefs();
        print('[PROVIDER] Budget added to SharedPreferences, ID: $newId');
      } else {
        final insertedId = await _dbService.insertBudget(budget);
        budget.id = insertedId;
        _budgets.add(budget);
        print('[PROVIDER] Budget added to SQLite, ID: $insertedId');
      }
      
      notifyListeners();
      print('[PROVIDER] Budget added successfully');
    } catch (e) {
      _error = 'Failed to add budget: $e';
      print('[PROVIDER ERROR] addBudget: $e');
      notifyListeners();
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      print('[PROVIDER] Updating budget ID: ${budget.id}');
      
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index == -1) {
        throw Exception('Budget not found in memory');
      }
      
      _budgets[index] = budget;
      
      if (kIsWeb) {
        await _saveBudgetsToSharedPrefs();
        print('[PROVIDER] Budget updated in SharedPreferences');
      } else {
        await _dbService.updateBudget(budget);
        print('[PROVIDER] Budget updated in SQLite');
      }
      
      notifyListeners();
      print('[PROVIDER] Budget updated successfully');
    } catch (e) {
      _error = 'Failed to update budget: $e';
      print('[PROVIDER ERROR] updateBudget: $e');
      notifyListeners();
    }
  }

  Future<void> deleteBudget(int id) async {
    try {
      print('[PROVIDER] Deleting budget ID: $id');
      
      _budgets.removeWhere((b) => b.id == id);
      
      if (kIsWeb) {
        await _saveBudgetsToSharedPrefs();
        print('[PROVIDER] Budget deleted from SharedPreferences');
      } else {
        await _dbService.deleteBudget(id);
        print('[PROVIDER] Budget deleted from SQLite');
      }
      
      notifyListeners();
      print('[PROVIDER] Budget deleted successfully');
    } catch (e) {
      _error = 'Failed to delete budget: $e';
      print('[PROVIDER ERROR] deleteBudget: $e');
      notifyListeners();
    }
  }
  
  // ============ UTILITY METHODS ============
  
  Future<void> refreshAll() async {
    print('[PROVIDER] Refreshing all data...');
    await loadTransactions();
    await loadBudgets();
    await _loadExchangeRates(); // TAMBAHKAN REFRESH RATES
    print('[PROVIDER] Refresh complete');
  }
  
  Future<void> resetAllData() async {
    try {
      print('[PROVIDER] 🚨 RESETTING ALL DATA 🚨');
      
      // Clear memory
      _transactions.clear();
      _budgets.clear();
      
      // Clear caches
      _cachedTotalIncome = null;
      _cachedTotalExpense = null;
      _exchangeRates.clear();
      _lastRateUpdate = null;
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('transactions_backup_v2');
      await prefs.remove('budgets');
      await prefs.remove('cached_exchange_rates');
      await prefs.remove('cached_exchange_time');
      
      // Clear SQLite database
      if (!kIsWeb) {
        await _dbService.clearAllData();
      }
      
      notifyListeners();
      print('[PROVIDER] All data cleared from memory and storage');
      
      // Load ulang (akan membuat data sample baru)
      await Future.delayed(const Duration(seconds: 1));
      await refreshAll();
      
    } catch (e) {
      print('[PROVIDER ERROR] resetAllData: $e');
    }
  }
  
  Future<void> forceReload() async {
    print('[PROVIDER] 🚀 Force reloading data...');
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 500));
    await refreshAll();
    
    print('[PROVIDER] Force reload complete');
  }
}