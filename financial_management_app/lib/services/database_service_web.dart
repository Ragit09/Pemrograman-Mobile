import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import '../models/transaction.dart' as model;
import '../models/budget.dart';
import '../utils/constants.dart';

class DatabaseService {
  static sql.Database? _database;
  static const String _dbName = 'finance_app.db';
  static const int _dbVersion = 2; // Naikkan versi untuk force recreate jika perlu
  
  static const String tableTransactions = 'transactions';
  static const String tableBudgets = 'budgets';
  static const String tableCategories = 'categories';
  
  Future<sql.Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<sql.Database> _initDatabase() async {
    try {
      final dbPath = await sql.getDatabasesPath();
      final path = join(dbPath, _dbName);

      // Buka database dengan error handling
      final db = await sql.openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createDatabase,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );

      // Verifikasi tabel ada
      await _verifyTables(db);
      
      return db;
    } catch (e) {
      print('❌ Error initializing database: $e');
      
      // Coba recover dengan menghapus dan membuat ulang
      try {
        final dbPath = await sql.getDatabasesPath();
        final path = join(dbPath, _dbName);
        
        // Hapus database yang corrupt
        try {
          await sql.deleteDatabase(path);
          print('🗑️ Deleted corrupt database');
        } catch (e) {
          print('⚠️ Could not delete database: $e');
        }
        
        // Buat database baru
        final db = await sql.openDatabase(
          path,
          version: _dbVersion,
          onCreate: _createDatabase,
        );
        
        print('✅ Database recreated successfully');
        return db;
      } catch (e2) {
        print('❌ Failed to recreate database: $e2');
        rethrow;
      }
    }
  }
  
  Future<void> _verifyTables(sql.Database db) async {
    try {
      // Cek tabel transactions
      await db.rawQuery("SELECT 1 FROM $tableTransactions LIMIT 1");
      
      // Cek tabel budgets
      await db.rawQuery("SELECT 1 FROM $tableBudgets LIMIT 1");
      
      // Cek tabel categories
      await db.rawQuery("SELECT 1 FROM $tableCategories LIMIT 1");
      
      print('✅ All tables verified');
    } catch (e) {
      print('⚠️ Tables not found or error: $e');
      print('🔄 Creating missing tables...');
      await _createDatabase(db, _dbVersion);
    }
  }
  
  Future<void> _createDatabase(sql.Database db, int version) async {
    // Tabel transactions - PASTIKAN struktur sama dengan model
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        is_favorite INTEGER DEFAULT 0,
        icon TEXT,
        color TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Tabel budgets
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableBudgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount_limit REAL NOT NULL,
        current_amount REAL DEFAULT 0,
        month_year TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Tabel categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableCategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        is_custom INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Insert default categories hanya jika tabel kosong
    await _insertDefaultCategories(db);
    
    print('✅ Database tables created successfully');
  }
  
  Future<void> _insertDefaultCategories(sql.Database db) async {
    // Cek apakah sudah ada data
    final count = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableCategories WHERE is_custom = 0'
    );
    final existingCount = count.first['count'] as int? ?? 0;
    
    if (existingCount > 0) {
      print('ℹ️ Default categories already exist');
      return;
    }
    
    final defaultCategories = [
      // Income categories
      {'name': 'Gaji', 'type': 'income', 'icon': '💰', 'color': '#10B981', 'is_custom': 0},
      {'name': 'Bonus', 'type': 'income', 'icon': '🎁', 'color': '#F59E0B', 'is_custom': 0},
      {'name': 'Investasi', 'type': 'income', 'icon': '📈', 'color': '#6366F1', 'is_custom': 0},
      {'name': 'Lainnya', 'type': 'income', 'icon': '📦', 'color': '#6B7280', 'is_custom': 0},
      
      // Expense categories
      {'name': 'Makanan', 'type': 'expense', 'icon': '🍔', 'color': '#EF4444', 'is_custom': 0},
      {'name': 'Transportasi', 'type': 'expense', 'icon': '🚗', 'color': '#3B82F6', 'is_custom': 0},
      {'name': 'Belanja', 'type': 'expense', 'icon': '🛒', 'color': '#8B5CF6', 'is_custom': 0},
      {'name': 'Hiburan', 'type': 'expense', 'icon': '🎬', 'color': '#EC4899', 'is_custom': 0},
      {'name': 'Kesehatan', 'type': 'expense', 'icon': '⚕️', 'color': '#06B6D4', 'is_custom': 0},
      {'name': 'Pendidikan', 'type': 'expense', 'icon': '📚', 'color': '#8B5CF6', 'is_custom': 0},
      {'name': 'Lainnya', 'type': 'expense', 'icon': '📦', 'color': '#9CA3AF', 'is_custom': 0},
    ];
    
    for (var category in defaultCategories) {
      try {
        await db.insert(tableCategories, category);
      } catch (e) {
        print('⚠️ Error inserting category ${category['name']}: $e');
      }
    }
    
    print('✅ Default categories inserted');
  }
  
  // CRUD untuk Transactions - PASTIKAN METHODS INI ADA
  Future<int> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    try {
      final result = await db.insert(tableTransactions, transaction.toMap());
      print('✅ Transaction inserted with id: $result');
      return result;
    } catch (e) {
      print('❌ Error inserting transaction: $e');
      print('📋 Transaction data: ${transaction.toMap()}');
      rethrow;
    }
  }
  
  Future<List<model.Transaction>> getTransactions() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableTransactions,
        orderBy: 'date DESC',
      );
      print('📊 Loaded ${maps.length} transactions from database');
      
      // Debug: print semua transaksi
      for (var map in maps) {
        print('  - ${map['id']}: ${map['title']} - ${map['amount']}');
      }
      
      return maps.map((map) => model.Transaction.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error loading transactions: $e');
      return [];
    }
  }
  
  Future<List<model.Transaction>> getFavoriteTransactions() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableTransactions,
        where: 'is_favorite = ?',
        whereArgs: [1],
        orderBy: 'date DESC',
      );
      return maps.map((map) => model.Transaction.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error loading favorite transactions: $e');
      return [];
    }
  }
  
  Future<int> updateTransaction(model.Transaction transaction) async {
    final db = await database;
    try {
      final result = await db.update(
        tableTransactions,
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      print('✅ Transaction ${transaction.id} updated: $result row(s) affected');
      return result;
    } catch (e) {
      print('❌ Error updating transaction: $e');
      rethrow;
    }
  }
  
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    try {
      final result = await db.delete(
        tableTransactions,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Transaction $id deleted: $result row(s) affected');
      return result;
    } catch (e) {
      print('❌ Error deleting transaction: $e');
      rethrow;
    }
  }
  
  // CRUD untuk Budgets
  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    try {
      final result = await db.insert(tableBudgets, budget.toMap());
      print('✅ Budget inserted with id: $result');
      return result;
    } catch (e) {
      print('❌ Error inserting budget: $e');
      rethrow;
    }
  }
  
  Future<List<Budget>> getBudgets() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(tableBudgets);
      print('📊 Loaded ${maps.length} budgets from database');
      return maps.map((map) => Budget.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error loading budgets: $e');
      return [];
    }
  }
  
  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    try {
      final result = await db.update(
        tableBudgets,
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [budget.id],
      );
      print('✅ Budget ${budget.id} updated: $result row(s) affected');
      return result;
    } catch (e) {
      print('❌ Error updating budget: $e');
      rethrow;
    }
  }
  
  Future<int> deleteBudget(int id) async {
    final db = await database;
    try {
      final result = await db.delete(
        tableBudgets,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Budget $id deleted: $result row(s) affected');
      return result;
    } catch (e) {
      print('❌ Error deleting budget: $e');
      rethrow;
    }
  }
  
  // CRUD untuk Categories
  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert(tableCategories, category);
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
  
  // Data offline - Get summary statistics
  Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    final db = await database;
    
    try {
      // Total income
      final incomeResult = await db.rawQuery('''
        SELECT SUM(amount) as total FROM $tableTransactions 
        WHERE type = 'income' 
        AND strftime('%Y', date) = ? 
        AND strftime('%m', date) = ?
      ''', [year.toString(), month.toString().padLeft(2, '0')]);
      
      // Total expense
      final expenseResult = await db.rawQuery('''
        SELECT SUM(amount) as total FROM $tableTransactions 
        WHERE type = 'expense' 
        AND strftime('%Y', date) = ? 
        AND strftime('%m', date) = ?
      ''', [year.toString(), month.toString().padLeft(2, '0')]);
      
      return {
        'total_income': incomeResult.first['total'] ?? 0.0,
        'total_expense': expenseResult.first['total'] ?? 0.0,
      };
    } catch (e) {
      print('❌ Error getting monthly summary: $e');
      return {
        'total_income': 0.0,
        'total_expense': 0.0,
      };
    }
  }
  
  // Method untuk debugging database
  Future<void> debugDatabase() async {
    try {
      final db = await database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      print('🔍 DATABASE DEBUG INFO');
      print('=====================');
      for (var table in tables) {
        final tableName = table['name'] as String;
        print('\n📋 Table: $tableName');
        
        try {
          final count = await db.rawQuery(
            "SELECT COUNT(*) as count FROM $tableName"
          );
          print('   Rows: ${count.first['count']}');
          
          if (tableName == 'transactions') {
            final sample = await db.rawQuery(
              "SELECT id, title, amount, type, date FROM $tableName ORDER BY date DESC LIMIT 3"
            );
            if (sample.isNotEmpty) {
              print('   Sample data:');
              for (var row in sample) {
                print('     - ${row['id']}: ${row['title']} (${row['type']}) - ${row['amount']} on ${row['date']}');
              }
            }
          }
        } catch (e) {
          print('   Error reading table: $e');
        }
      }
      print('=====================');
    } catch (e) {
      print('❌ Error debugging database: $e');
    }
  }
  
  // Close database
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      print('🔒 Database closed');
    }
  }
}