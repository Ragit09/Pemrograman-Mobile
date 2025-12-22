abstract class DatabaseService {
  // Transactions
  Future<List<Map<String, dynamic>>> getTransactions();
  Future<int> insertTransaction(Map<String, dynamic> transaction);
  Future<int> updateTransaction(Map<String, dynamic> transaction);
  Future<int> deleteTransaction(int id);
  
  // Budgets
  Future<List<Map<String, dynamic>>> getBudgets();
  Future<int> insertBudget(Map<String, dynamic> budget);
  
  // Categories
  Future<List<Map<String, dynamic>>> getCategories(String type);
  
  // Statistics
  Future<Map<String, dynamic>> getMonthlySummary(int year, int month);
}