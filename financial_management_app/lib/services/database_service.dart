import 'dart:math';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import '../models/transaction.dart' as model;
import '../models/budget.dart';
import '../utils/constants.dart';

class DatabaseService {
  static sql.Database? _database;
  static const String _dbName = 'finance_app_v7.db'; // Naikkan versi untuk currency support
  static const int _dbVersion = 7; // Naikkan versi untuk force recreate
  
  static const String tableTransactions = 'transactions';
  static const String tableBudgets = 'budgets';
  static const String tableCategories = 'categories';
  
  Future<sql.Database> get database async {
    if (_database != null && _database!.isOpen) {
      print('[DATABASE] Returning existing database instance');
      return _database!;
    }
    
    print('[DATABASE] Initializing new database instance');
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<sql.Database> _initDatabase() async {
    try {
      final dbPath = await sql.getDatabasesPath();
      final path = join(dbPath, _dbName);
      print('[DATABASE] Database path: $path');
      
      // Cek jika database sudah ada
      final exists = await sql.databaseExists(path);
      print('[DATABASE] Database exists: $exists');
      
      final db = await sql.openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
        onConfigure: (db) async {
          // Enable foreign keys
          await db.execute('PRAGMA foreign_keys = ON');
          print('[DATABASE] Foreign keys enabled');
        },
      );
      
      print('[DATABASE] Database opened successfully');
      
      // Verifikasi semua tabel ada
      await _verifyTables(db);
      
      return db;
    } catch (e) {
      print('[DATABASE ERROR] initDatabase: $e');
      print('[DATABASE ERROR] Stack trace: ${StackTrace.current}');
      
      // Emergency recovery - delete and recreate
      try {
        print('[DATABASE] Attempting emergency recovery...');
        final dbPath = await sql.getDatabasesPath();
        final path = join(dbPath, _dbName);
        
        if (await sql.databaseExists(path)) {
          await sql.deleteDatabase(path);
          print('[DATABASE] Deleted corrupt database');
        }
        
        // Create fresh database
        final db = await sql.openDatabase(
          path,
          version: _dbVersion,
          onCreate: _createDatabase,
        );
        
        print('[DATABASE] Emergency recovery successful');
        return db;
      } catch (e2) {
        print('[DATABASE FATAL ERROR] Recovery failed: $e2');
        rethrow;
      }
    }
  }
  
  Future<void> _upgradeDatabase(sql.Database db, int oldVersion, int newVersion) async {
    print('[DATABASE] Upgrading from v$oldVersion to v$newVersion');
    
    if (oldVersion < 7) {
      print('[DATABASE] Major upgrade required - adding currency support');
      
      // Backup data lama jika perlu
      try {
        final oldTransactions = await db.query(tableTransactions);
        print('[DATABASE] Found ${oldTransactions.length} old transactions to migrate');
        
        // Create temporary table dengan struktur baru
        await db.execute('DROP TABLE IF EXISTS ${tableTransactions}_temp');
        
        await db.execute('''
          CREATE TABLE ${tableTransactions}_temp (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL CHECK(amount >= 0),
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
            description TEXT,
            is_favorite INTEGER DEFAULT 0 CHECK(is_favorite IN (0, 1)),
            icon TEXT,
            color TEXT,
            original_currency TEXT DEFAULT 'IDR',
            original_amount REAL DEFAULT 0,
            transaction_currency TEXT DEFAULT 'IDR',
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        
        // Migrate data
        for (var oldData in oldTransactions) {
          await db.insert('${tableTransactions}_temp', {
            'id': oldData['id'],
            'title': oldData['title'],
            'amount': oldData['amount'],
            'category': oldData['category'],
            'date': oldData['date'],
            'type': oldData['type'],
            'description': oldData['description'],
            'is_favorite': oldData['is_favorite'],
            'icon': oldData['icon'],
            'color': oldData['color'],
            'original_currency': 'IDR', // Set default untuk data lama
            'original_amount': oldData['amount'],
            'transaction_currency': 'IDR', // Set default untuk data lama
            'created_at': oldData['created_at'] ?? DateTime.now().toIso8601String(),
          });
        }
        
        // Drop table lama dan rename temp
        await db.execute('DROP TABLE $tableTransactions');
        await db.execute('ALTER TABLE ${tableTransactions}_temp RENAME TO $tableTransactions');
        
        print('[DATABASE] Successfully migrated transactions to new schema');
      } catch (e) {
        print('[DATABASE ERROR] Migration failed: $e');
        print('[DATABASE] Creating fresh tables...');
        
        // Jika migration gagal, buat tabel baru
        await db.execute('DROP TABLE IF EXISTS $tableTransactions');
        await db.execute('DROP TABLE IF EXISTS $tableBudgets');
        await db.execute('DROP TABLE IF EXISTS $tableCategories');
        
        // Buat ulang semua tabel
        await _createDatabase(db, newVersion);
      }
    } else if (oldVersion < 6) {
      print('[DATABASE] Major upgrade required - recreating tables');
      
      // Drop semua tabel lama
      await db.execute('DROP TABLE IF EXISTS $tableTransactions');
      await db.execute('DROP TABLE IF EXISTS $tableBudgets');
      await db.execute('DROP TABLE IF EXISTS $tableCategories');
      
      // Buat ulang semua tabel
      await _createDatabase(db, newVersion);
    }
  }
  
  Future<void> _verifyTables(sql.Database db) async {
    final tablesToCheck = [tableTransactions, tableBudgets, tableCategories];
    
    for (var table in tablesToCheck) {
      try {
        await db.rawQuery('SELECT 1 FROM $table LIMIT 1');
        print('[DATABASE] Table $table verified');
        
        // Untuk transactions table, cek kolom currency
        if (table == tableTransactions) {
          final columns = await db.rawQuery('PRAGMA table_info($table)');
          final hasCurrencyColumn = columns.any((col) => 
              col['name'] == 'transaction_currency');
          
          if (!hasCurrencyColumn) {
            print('[DATABASE] Transactions table missing currency columns, upgrading...');
            await _upgradeDatabase(db, 6, 7);
          }
        }
      } catch (e) {
        print('[DATABASE] Table $table not found or error: $e');
        print('[DATABASE] Creating table $table...');
        
        // Buat ulang database jika ada tabel yang hilang
        await _createDatabase(db, _dbVersion);
        break;
      }
    }
  }
  
  Future<void> _createDatabase(sql.Database db, int version) async {
    print('[DATABASE] Creating database tables (v$version)...');
    
    // Batch operations untuk performa lebih baik
    await db.transaction((txn) async {
      // Tabel transactions dengan TAMBAHAN field currency
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS $tableTransactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL CHECK(amount >= 0),
          category TEXT NOT NULL,
          date TEXT NOT NULL,
          type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
          description TEXT,
          is_favorite INTEGER DEFAULT 0 CHECK(is_favorite IN (0, 1)),
          icon TEXT,
          color TEXT,
          original_currency TEXT DEFAULT 'IDR',
          original_amount REAL DEFAULT 0,
          transaction_currency TEXT DEFAULT 'IDR',
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Tabel budgets
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS $tableBudgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          amount_limit REAL NOT NULL CHECK(amount_limit >= 0),
          current_amount REAL DEFAULT 0 CHECK(current_amount >= 0),
          month_year TEXT NOT NULL,
          icon TEXT,
          color TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Tabel categories
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS $tableCategories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
          icon TEXT,
          color TEXT,
          is_custom INTEGER DEFAULT 1 CHECK(is_custom IN (0, 1)),
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(name, type)
        )
      ''');
    });
    
    // Insert default categories
    await _insertDefaultCategories(db);
    
    print('[DATABASE] Database tables created successfully');
  }
  
  Future<void> _insertDefaultCategories(sql.Database db) async {
    try {
      // Cek jika sudah ada categories
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableCategories'
      );
      final count = (countResult.first['count'] as int?) ?? 0;
      
      if (count > 0) {
        print('[DATABASE] Categories already exist ($count records), skipping');
        return;
      }
      
      final defaultCategories = [
        // Income categories
        {'name': 'Gaji', 'type': 'income', 'icon': '💰', 'color': '#10B981', 'is_custom': 0},
        {'name': 'Bonus', 'type': 'income', 'icon': '🎁', 'color': '#F59E0B', 'is_custom': 0},
        {'name': 'Investasi', 'type': 'income', 'icon': '📈', 'color': '#6366F1', 'is_custom': 0},
        {'name': 'Hadiah', 'type': 'income', 'icon': '🎁', 'color': '#EC4899', 'is_custom': 0},
        {'name': 'Lainnya', 'type': 'income', 'icon': '📦', 'color': '#6B7280', 'is_custom': 0},
        
        // Expense categories
        {'name': 'Makanan', 'type': 'expense', 'icon': '🍔', 'color': '#EF4444', 'is_custom': 0},
        {'name': 'Transportasi', 'type': 'expense', 'icon': '🚗', 'color': '#3B82F6', 'is_custom': 0},
        {'name': 'Belanja', 'type': 'expense', 'icon': '🛒', 'color': '#8B5CF6', 'is_custom': 0},
        {'name': 'Hiburan', 'type': 'expense', 'icon': '🎬', 'color': '#F59E0B', 'is_custom': 0},
        {'name': 'Kesehatan', 'type': 'expense', 'icon': '⚕️', 'color': '#06B6D4', 'is_custom': 0},
        {'name': 'Pendidikan', 'type': 'expense', 'icon': '📚', 'color': '#8B5CF6', 'is_custom': 0},
        {'name': 'Tagihan', 'type': 'expense', 'icon': '📄', 'color': '#6B7280', 'is_custom': 0},
        {'name': 'Lainnya', 'type': 'expense', 'icon': '📦', 'color': '#9CA3AF', 'is_custom': 0},
      ];
      
      for (var category in defaultCategories) {
        try {
          await db.insert(
            tableCategories,
            category,
            conflictAlgorithm: sql.ConflictAlgorithm.ignore,
          );
        } catch (e) {
          print('[DATABASE] Error inserting category ${category['name']}: $e');
        }
      }
      
      print('[DATABASE] Inserted ${defaultCategories.length} default categories');
    } catch (e) {
      print('[DATABASE ERROR] _insertDefaultCategories: $e');
    }
  }
  
  // ============ TRANSACTION METHODS (UPDATE UNTUK SUPPORT CURRENCY) ============
  
  Future<int> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    
    try {
      print('[DATABASE] Inserting transaction: "${transaction.title}"');
      print('[DATABASE] Currency: ${transaction.transactionCurrency}');
      print('[DATABASE] Original Amount: ${transaction.originalAmount}');
      
      // Siapkan data dengan SEMUA field termasuk yang baru
      final map = {
        'title': transaction.title,
        'amount': transaction.amount,
        'category': transaction.category,
        'date': transaction.date.toIso8601String(),
        'type': transaction.type,
        'description': transaction.description,
        'is_favorite': transaction.isFavorite ? 1 : 0,
        'icon': transaction.icon,
        'color': transaction.color,
        // TAMBAHKAN FIELD BARU
        'original_currency': transaction.originalCurrency,
        'original_amount': transaction.originalAmount,
        'transaction_currency': transaction.transactionCurrency,
      };
      
      // Validasi data
      if (map['title'] == null || (map['title'] as String).isEmpty) {
        throw Exception('Transaction title cannot be empty');
      }
      
      if ((map['amount'] as double) <= 0) {
        throw Exception('Transaction amount must be positive');
      }
      
      // Insert ke database
      final id = await db.insert(
        tableTransactions,
        map,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      
      print('[DATABASE] Transaction inserted with ID: $id');
      
      // Update budget jika transaksi expense
      if (transaction.type == 'expense') {
        await _updateBudgetForTransaction(db, transaction);
      }
      
      return id;
    } catch (e) {
      print('[DATABASE ERROR] insertTransaction: $e');
      print('[DATABASE ERROR] Transaction data: ${transaction.toMap()}');
      rethrow;
    }
  }
  
  Future<void> _updateBudgetForTransaction(sql.Database db, model.Transaction transaction) async {
    try {
      if (transaction.type != 'expense') return;
      
      final monthYear = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      
      print('[DATABASE] Updating budget for transaction: ${transaction.category} - $monthYear');
      
      // Cari budget untuk kategori dan bulan ini
      final budgets = await db.query(
        tableBudgets,
        where: 'category = ? AND month_year = ?',
        whereArgs: [transaction.category, monthYear],
      );
      
      if (budgets.isNotEmpty) {
        for (var budget in budgets) {
          final currentAmount = (budget['current_amount'] as num?)?.toDouble() ?? 0.0;
          final newAmount = currentAmount + transaction.amount;
          
          print('[DATABASE] Budget update:');
          print('  Category: ${transaction.category}');
          print('  Month: $monthYear');
          print('  Current: $currentAmount');
          print('  Added: ${transaction.amount}');
          print('  New total: $newAmount');
          
          await db.update(
            tableBudgets,
            {'current_amount': newAmount},
            where: 'id = ?',
            whereArgs: [budget['id']],
          );
          
          print('[DATABASE] Budget ID ${budget['id']} updated successfully');
        }
      } else {
        print('[DATABASE] No budget found for category: ${transaction.category} in month: $monthYear');
      }
    } catch (e) {
      print('[DATABASE ERROR] _updateBudgetForTransaction: $e');
    }
  }
  
  Future<List<model.Transaction>> getTransactions() async {
    final db = await database;
    
    try {
      print('[DATABASE] Loading all transactions...');
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableTransactions,
        orderBy: 'date DESC, id DESC',
      );
      
      print('[DATABASE] Found ${maps.length} transactions in database');
      
      // Debug: tampilkan beberapa transaksi dengan info currency
      if (maps.isNotEmpty) {
        for (int i = 0; i < min(3, maps.length); i++) {
          final map = maps[i];
          print('[DATABASE SAMPLE] ${i + 1}. ${map['title']} - ${map['amount']} ${map['transaction_currency']} (${map['type']}) - ${map['date']}');
        }
      }
      
      // Parse semua transaksi
      final transactions = <model.Transaction>[];
      int errorCount = 0;
      
      for (var map in maps) {
        try {
          final transaction = model.Transaction.fromMap(map);
          transactions.add(transaction);
        } catch (e) {
          errorCount++;
          print('[DATABASE ERROR] Failed to parse transaction: $e');
          print('[DATABASE ERROR] Problematic data: $map');
        }
      }
      
      if (errorCount > 0) {
        print('[DATABASE WARNING] Failed to parse $errorCount transactions');
      }
      
      print('[DATABASE] Successfully parsed ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      print('[DATABASE ERROR] getTransactions: $e');
      print('[DATABASE ERROR] Stack trace: ${StackTrace.current}');
      return [];
    }
  }
  
  Future<int> updateTransaction(model.Transaction transaction) async {
    final db = await database;
    
    try {
      if (transaction.id == null) {
        throw Exception('Cannot update transaction without ID');
      }
      
      print('[DATABASE] Updating transaction ID ${transaction.id}');
      print('[DATABASE] New currency: ${transaction.transactionCurrency}');
      
      // Get old transaction data for budget adjustment
      final oldTransactionMaps = await db.query(
        tableTransactions,
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      
      // Update data dengan SEMUA field
      final map = {
        'title': transaction.title,
        'amount': transaction.amount,
        'category': transaction.category,
        'date': transaction.date.toIso8601String(),
        'type': transaction.type,
        'description': transaction.description,
        'is_favorite': transaction.isFavorite ? 1 : 0,
        'icon': transaction.icon,
        'color': transaction.color,
        // TAMBAHKAN FIELD BARU
        'original_currency': transaction.originalCurrency,
        'original_amount': transaction.originalAmount,
        'transaction_currency': transaction.transactionCurrency,
      };
      
      final rows = await db.update(
        tableTransactions,
        map,
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      
      print('[DATABASE] Updated $rows row(s)');
      
      // Handle budget updates jika transaction berubah dari/ke expense
      if (oldTransactionMaps.isNotEmpty) {
        final oldTransaction = model.Transaction.fromMap(oldTransactionMaps.first);
        final wasExpense = oldTransaction.type == 'expense';
        final isExpense = transaction.type == 'expense';
        
        if (wasExpense || isExpense) {
          print('[DATABASE] Transaction type change affects budgets, recalculating...');
          await recalculateBudgetsForMonth(transaction.date.year, transaction.date.month);
        }
      }
      
      return rows;
    } catch (e) {
      print('[DATABASE ERROR] updateTransaction: $e');
      rethrow;
    }
  }
  
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    
    try {
      print('[DATABASE] Deleting transaction ID $id');
      
      // Get transaction data sebelum dihapus untuk budget adjustment
      final transactionMaps = await db.query(
        tableTransactions,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      final rows = await db.delete(
        tableTransactions,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('[DATABASE] Deleted $rows row(s)');
      
      // Adjust budget jika transaction yang dihapus adalah expense
      if (transactionMaps.isNotEmpty) {
        final transaction = model.Transaction.fromMap(transactionMaps.first);
        if (transaction.type == 'expense') {
          await _adjustBudgetForDeletedTransaction(db, transaction);
        }
      }
      
      return rows;
    } catch (e) {
      print('[DATABASE ERROR] deleteTransaction: $e');
      rethrow;
    }
  }
  
  Future<void> _adjustBudgetForDeletedTransaction(sql.Database db, model.Transaction transaction) async {
    try {
      if (transaction.type != 'expense') return;
      
      final monthYear = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      
      print('[DATABASE] Adjusting budget for deleted transaction: ${transaction.category}');
      
      // Cari budget untuk kategori dan bulan ini
      final budgets = await db.query(
        tableBudgets,
        where: 'category = ? AND month_year = ?',
        whereArgs: [transaction.category, monthYear],
      );
      
      if (budgets.isNotEmpty) {
        for (var budget in budgets) {
          final currentAmount = (budget['current_amount'] as num?)?.toDouble() ?? 0.0;
          final newAmount = max(0, currentAmount - transaction.amount); // Pastikan tidak negatif
          
          print('[DATABASE] Budget adjustment:');
          print('  Category: ${transaction.category}');
          print('  Current: $currentAmount');
          print('  Subtracted: ${transaction.amount}');
          print('  New total: $newAmount');
          
          await db.update(
            tableBudgets,
            {'current_amount': newAmount},
            where: 'id = ?',
            whereArgs: [budget['id']],
          );
          
          print('[DATABASE] Budget ID ${budget['id']} adjusted successfully');
        }
      }
    } catch (e) {
      print('[DATABASE ERROR] _adjustBudgetForDeletedTransaction: $e');
    }
  }
  
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    
    try {
      print('[DATABASE] Setting favorite for transaction $id to $isFavorite');
      
      await db.update(
        tableTransactions,
        {'is_favorite': isFavorite ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('[DATABASE] Favorite updated');
    } catch (e) {
      print('[DATABASE ERROR] toggleFavorite: $e');
      rethrow;
    }
  }
  
  // ============ BUDGET METHODS ============
  
  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    
    try {
      print('[DATABASE] Inserting budget: "${budget.category}"');
      
      final id = await db.insert(
        tableBudgets,
        budget.toMap(),
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      
      print('[DATABASE] Budget inserted with ID: $id');
      return id;
    } catch (e) {
      print('[DATABASE ERROR] insertBudget: $e');
      rethrow;
    }
  }
  
  Future<List<Budget>> getBudgets() async {
    final db = await database;
    
    try {
      print('[DATABASE] Loading budgets...');
      
      final List<Map<String, dynamic>> maps = await db.query(tableBudgets);
      
      print('[DATABASE] Found ${maps.length} budgets');
      
      return maps.map((map) => Budget.fromMap(map)).toList();
    } catch (e) {
      print('[DATABASE ERROR] getBudgets: $e');
      return [];
    }
  }
  
  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    
    try {
      if (budget.id == null) {
        throw Exception('Cannot update budget without ID');
      }
      
      print('[DATABASE] Updating budget ID ${budget.id}');
      
      final rows = await db.update(
        tableBudgets,
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [budget.id],
      );
      
      print('[DATABASE] Updated $rows row(s)');
      return rows;
    } catch (e) {
      print('[DATABASE ERROR] updateBudget: $e');
      rethrow;
    }
  }
  
  Future<int> deleteBudget(int id) async {
    final db = await database;
    
    try {
      print('[DATABASE] Deleting budget ID $id');
      
      final rows = await db.delete(
        tableBudgets,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('[DATABASE] Deleted $rows row(s)');
      return rows;
    } catch (e) {
      print('[DATABASE ERROR] deleteBudget: $e');
      rethrow;
    }
  }
  
  // ============ BUDGET CALCULATION METHODS ============
  
  Future<void> recalculateBudgetsForMonth(int year, int month) async {
    final db = await database;
    
    try {
      final monthStr = month.toString().padLeft(2, '0');
      final yearStr = year.toString();
      final monthYear = '$yearStr-$monthStr';
      
      print('[DATABASE] Recalculating budgets for $monthYear');
      
      // Reset semua budget untuk bulan ini
      await db.update(
        tableBudgets,
        {'current_amount': 0},
        where: 'month_year = ?',
        whereArgs: [monthYear],
      );
      
      // Ambil semua transaksi expense bulan ini
      final expenseTransactions = await db.rawQuery('''
        SELECT category, SUM(amount) as total 
        FROM $tableTransactions 
        WHERE type = 'expense' 
          AND strftime('%Y', date) = ? 
          AND strftime('%m', date) = ?
        GROUP BY category
      ''', [yearStr, monthStr]);
      
      print('[DATABASE] Found ${expenseTransactions.length} expense categories');
      
      // Update budget untuk setiap kategori
      for (var transaction in expenseTransactions) {
        final category = transaction['category'] as String;
        final total = (transaction['total'] as num?)?.toDouble() ?? 0.0;
        
        print('[DATABASE] Category $category: total expense = $total');
        
        // Update budget untuk kategori ini
        await db.rawUpdate('''
          UPDATE $tableBudgets 
          SET current_amount = ? 
          WHERE category = ? AND month_year = ?
        ''', [total, category, monthYear]);
      }
      
      print('[DATABASE] Budget recalculation complete for $monthYear');
      
    } catch (e) {
      print('[DATABASE ERROR] recalculateBudgetsForMonth: $e');
      rethrow;
    }
  }
  
  Future<Map<String, double>> getExpenseSummaryForMonth(int year, int month) async {
    final db = await database;
    
    try {
      final monthStr = month.toString().padLeft(2, '0');
      final yearStr = year.toString();
      
      print('[DATABASE] Getting expense summary for $year-$month');
      
      // Ambil summary expense per kategori
      final expenseSummary = await db.rawQuery('''
        SELECT category, SUM(amount) as total 
        FROM $tableTransactions 
        WHERE type = 'expense' 
          AND strftime('%Y', date) = ? 
          AND strftime('%m', date) = ?
        GROUP BY category
      ''', [yearStr, monthStr]);
      
      final result = <String, double>{};
      for (var row in expenseSummary) {
        final category = row['category'] as String;
        final total = (row['total'] as num?)?.toDouble() ?? 0.0;
        result[category] = total;
      }
      
      print('[DATABASE] Expense summary: $result');
      return result;
    } catch (e) {
      print('[DATABASE ERROR] getExpenseSummaryForMonth: $e');
      return {};
    }
  }
  
  Future<double> getTotalExpenseForCategoryMonth(String category, int year, int month) async {
    final db = await database;
    
    try {
      final monthStr = month.toString().padLeft(2, '0');
      final yearStr = year.toString();
      
      final result = await db.rawQuery('''
        SELECT SUM(amount) as total 
        FROM $tableTransactions 
        WHERE type = 'expense' 
          AND category = ?
          AND strftime('%Y', date) = ? 
          AND strftime('%m', date) = ?
      ''', [category, yearStr, monthStr]);
      
      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      
      print('[DATABASE] Total expense for $category in $year-$month: $total');
      return total;
    } catch (e) {
      print('[DATABASE ERROR] getTotalExpenseForCategoryMonth: $e');
      return 0.0;
    }
  }
  
  // ============ CATEGORY METHODS ============
  
  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert(
      tableCategories,
      category,
      conflictAlgorithm: sql.ConflictAlgorithm.ignore,
    );
  }
  
  Future<List<Map<String, dynamic>>> getCategories(String type) async {
    final db = await database;
    
    if (type == 'all') {
      return await db.query(tableCategories);
    }
    
    return await db.query(
      tableCategories,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'is_custom ASC, name ASC',
    );
  }
  
  // ============ UTILITY METHODS ============
  
  Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    final db = await database;
    
    try {
      final monthStr = month.toString().padLeft(2, '0');
      final yearStr = year.toString();
      
      // Total income
      final incomeResult = await db.rawQuery('''
        SELECT SUM(amount) as total FROM $tableTransactions 
        WHERE type = 'income' 
        AND strftime('%Y', date) = ? 
        AND strftime('%m', date) = ?
      ''', [yearStr, monthStr]);
      
      // Total expense
      final expenseResult = await db.rawQuery('''
        SELECT SUM(amount) as total FROM $tableTransactions 
        WHERE type = 'expense' 
        AND strftime('%Y', date) = ? 
        AND strftime('%m', date) = ?
      ''', [yearStr, monthStr]);
      
      final totalIncome = (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;
      final totalExpense = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      print('[DATABASE] Monthly summary for $year-$month: income=$totalIncome, expense=$totalExpense');
      
      return {
        'total_income': totalIncome,
        'total_expense': totalExpense,
      };
    } catch (e) {
      print('[DATABASE ERROR] getMonthlySummary: $e');
      return {
        'total_income': 0.0,
        'total_expense': 0.0,
      };
    }
  }
  
  Future<void> checkDatabaseIntegrity() async {
    try {
      final db = await database;
      
      print('[DATABASE INTEGRITY CHECK]');
      print('=' * 40);
      print('Database version: $_dbVersion');
      print('Database name: $_dbName');
      
      // Check semua tabel
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      print('[DATABASE] Tables found:');
      for (var table in tables) {
        final tableName = table['name'] as String;
        print('  - $tableName');
        
        // Get row count
        try {
          final count = await db.rawQuery(
            "SELECT COUNT(*) as count FROM $tableName"
          );
          final rowCount = (count.first['count'] as int?) ?? 0;
          print('    Rows: $rowCount');
          
          // Show sample data untuk transactions
          if (tableName == 'transactions' && rowCount > 0) {
            final sample = await db.rawQuery(
              "SELECT id, title, amount, type, category, date, transaction_currency FROM $tableName ORDER BY id DESC LIMIT 3"
            );
            print('    Sample:');
            for (var row in sample) {
              print('      ${row['id']}: ${row['title']} - ${row['amount']} ${row['transaction_currency']} (${row['type']}) - ${row['category']} - ${row['date']}');
            }
          }
          
          // Show sample data untuk budgets
          if (tableName == 'budgets' && rowCount > 0) {
            final sample = await db.rawQuery(
              "SELECT id, category, amount_limit, current_amount, month_year FROM $tableName ORDER BY id DESC LIMIT 3"
            );
            print('    Sample:');
            for (var row in sample) {
              print('      ${row['id']}: ${row['category']} - Limit: ${row['amount_limit']}, Current: ${row['current_amount']}, Month: ${row['month_year']}');
            }
          }
        } catch (e) {
          print('    Error reading table: $e');
        }
      }
      
      print('=' * 40);
    } catch (e) {
      print('[DATABASE ERROR] checkDatabaseIntegrity: $e');
    }
  }
  
  Future<void> clearAllData() async {
    try {
      final db = await database;
      
      print('[DATABASE] Clearing all data...');
      
      await db.transaction((txn) async {
        await txn.delete(tableTransactions);
        await txn.delete(tableBudgets);
        await txn.delete('categories', where: 'is_custom = 1');
      });
      
      // Reinsert default categories
      await _insertDefaultCategories(db);
      
      print('[DATABASE] All data cleared successfully');
    } catch (e) {
      print('[DATABASE ERROR] clearAllData: $e');
      rethrow;
    }
  }
  
  // TAMBAHKAN METHOD UNTUK MIGRASI DATA LAMA
  Future<void> migrateOldTransactions() async {
    try {
      final db = await database;
      
      print('[DATABASE] Checking for old transactions to migrate...');
      
      // Cek apakah ada transaksi tanpa field currency
      final oldStyleCount = await db.rawQuery('''
        SELECT COUNT(*) as count FROM $tableTransactions 
        WHERE transaction_currency IS NULL OR original_currency IS NULL
      ''');
      
      final count = (oldStyleCount.first['count'] as int?) ?? 0;
      
      if (count > 0) {
        print('[DATABASE] Found $count old-style transactions to migrate');
        
        // Update semua transaksi untuk menambahkan field currency
        await db.rawUpdate('''
          UPDATE $tableTransactions 
          SET transaction_currency = 'IDR', 
              original_currency = 'IDR',
              original_amount = amount
          WHERE transaction_currency IS NULL OR original_currency IS NULL
        ''');
        
        print('[DATABASE] Successfully migrated $count transactions');
      } else {
        print('[DATABASE] No old transactions found to migrate');
      }
    } catch (e) {
      print('[DATABASE ERROR] migrateOldTransactions: $e');
    }
  }
  
  // TAMBAHKAN METHOD UNTUK GET TRANSACTIONS BY CURRENCY
  Future<List<model.Transaction>> getTransactionsByCurrency(String currencyCode) async {
    final db = await database;
    
    try {
      print('[DATABASE] Loading transactions in $currencyCode...');
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableTransactions,
        where: 'transaction_currency = ?',
        whereArgs: [currencyCode],
        orderBy: 'date DESC, id DESC',
      );
      
      print('[DATABASE] Found ${maps.length} transactions in $currencyCode');
      
      return maps.map((map) => model.Transaction.fromMap(map)).toList();
    } catch (e) {
      print('[DATABASE ERROR] getTransactionsByCurrency: $e');
      return [];
    }
  }
  
  // TAMBAHKAN METHOD UNTUK GET CURRENCY STATISTICS
  Future<Map<String, double>> getCurrencyStats() async {
    final db = await database;
    
    try {
      print('[DATABASE] Getting currency statistics...');
      
      final result = await db.rawQuery('''
        SELECT transaction_currency, 
               COUNT(*) as count,
               SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
               SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as total_expense
        FROM $tableTransactions 
        GROUP BY transaction_currency
      ''');
      
      final stats = <String, double>{};
      for (var row in result) {
        final currency = row['transaction_currency'] as String;
        final income = (row['total_income'] as num?)?.toDouble() ?? 0.0;
        final expense = (row['total_expense'] as num?)?.toDouble() ?? 0.0;
        
        stats['${currency}_income'] = income;
        stats['${currency}_expense'] = expense;
        stats['${currency}_balance'] = income - expense;
      }
      
      print('[DATABASE] Currency stats: $stats');
      return stats;
    } catch (e) {
      print('[DATABASE ERROR] getCurrencyStats: $e');
      return {};
    }
  }
  
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      print('[DATABASE] Database closed');
    }
  }
}