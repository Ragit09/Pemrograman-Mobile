import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../models/budget.dart';
import '../utils/constants.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late DateTime _selectedMonth;
  bool _isRecalculating = false;
  bool _isSyncing = false;
  
  final List<Map<String, dynamic>> _defaultCategories = [
    {'name': 'Makanan', 'icon': '🍔', 'color': '#EF4444'},
    {'name': 'Transportasi', 'icon': '🚗', 'color': '#3B82F6'},
    {'name': 'Belanja', 'icon': '🛒', 'color': '#8B5CF6'},
    {'name': 'Hiburan', 'icon': '🎬', 'color': '#EC4899'},
    {'name': 'Kesehatan', 'icon': '🏥', 'color': '#06B6D4'},
    {'name': 'Pendidikan', 'icon': '📚', 'color': '#8B5CF6'},
    {'name': 'Tagihan', 'icon': '📄', 'color': '#6B7280'},
    {'name': 'Lainnya', 'icon': '📦', 'color': '#9CA3AF'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    // Recalculate budgets saat pertama kali load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculateBudgets();
    });
  }

  Future<void> _recalculateBudgets() async {
    if (_isRecalculating) return;
    
    setState(() => _isRecalculating = true);
    
    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      
      print('[BUDGET SCREEN] Recalculating budgets for ${_selectedMonth.year}-${_selectedMonth.month}');
      
      await provider.recalculateBudgetsForMonth(
        _selectedMonth.year, 
        _selectedMonth.month
      );
      
      // Tampilkan feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Budget berhasil dihitung ulang'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      print('[BUDGET SCREEN ERROR] _recalculateBudgets: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghitung ulang: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isRecalculating = false);
    }
  }

  Future<void> _syncBudgetWithTransactions(Budget budget) async {
    if (_isSyncing) return;
    
    setState(() => _isSyncing = true);
    
    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      
      print('[BUDGET SCREEN] Syncing budget: ${budget.category}');
      
      // Hitung real expense dari transaksi
      final realExpense = provider.getExpenseForCategoryThisMonth(budget.category);
      
      print('[BUDGET SCREEN] Real expense for ${budget.category}: $realExpense');
      print('[BUDGET SCREEN] Current budget amount: ${budget.currentAmount}');
      
      // Update budget dengan real expense
      final updatedBudget = Budget(
        id: budget.id,
        category: budget.category,
        amountLimit: budget.amountLimit,
        currentAmount: realExpense,
        monthYear: budget.monthYear,
        icon: budget.icon,
        color: budget.color,
      );
      
      await provider.updateBudget(updatedBudget);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Budget ${budget.category} berhasil disinkronisasi'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      print('[BUDGET SCREEN ERROR] _syncBudgetWithTransactions: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal sinkronisasi: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // TOMBOL RECALCULATE ALL
          IconButton(
            icon: _isRecalculating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, 
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRecalculating ? null : _recalculateBudgets,
            tooltip: 'Hitung ulang semua budget',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudgetDialog(context, transactionProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector dengan statistik
          _buildMonthSelector(themeProvider, transactionProvider),
          
          // Budgets list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await transactionProvider.loadBudgets();
                await _recalculateBudgets();
              },
              child: _buildBudgetsList(themeProvider, transactionProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(ThemeProvider themeProvider, TransactionProvider provider) {
    final monthKey = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
    
    // Hitung total expense bulan ini
    final monthExpenses = provider.transactions
        .where((t) {
          final tMonth = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
          return t.type == 'expense' && tMonth == monthKey;
        })
        .fold(0.0, (sum, item) => sum + item.amount);
    
    // Hitung total budget limit bulan ini
    final totalBudgetLimit = provider.budgets
        .where((b) => b.monthYear == monthKey)
        .fold(0.0, (sum, item) => sum + item.amountLimit);
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: themeProvider.cardColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: themeProvider.textColor),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                  });
                  _recalculateBudgets();
                },
              ),
              Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Statistik pengeluaran vs budget
                  Column(
                    children: [
                      Text(
                        'Pengeluaran: Rp ${NumberFormat('#,###').format(monthExpenses)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                      Text(
                        'Total Budget: Rp ${NumberFormat('#,###').format(totalBudgetLimit)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                      if (totalBudgetLimit > 0)
                        Text(
                          'Sisa Alokasi: Rp ${NumberFormat('#,###').format(max(0, totalBudgetLimit - monthExpenses))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: (totalBudgetLimit - monthExpenses) >= 0 
                                ? AppColors.success 
                                : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: themeProvider.textColor),
                onPressed: () {
                  final now = DateTime.now();
                  if (_selectedMonth.month < now.month || _selectedMonth.year < now.year) {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                    });
                    _recalculateBudgets();
                  }
                },
              ),
            ],
          ),
          // Progress bar total
          if (totalBudgetLimit > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: min(1.0, monthExpenses / totalBudgetLimit),
                    backgroundColor: themeProvider.backgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      monthExpenses / totalBudgetLimit >= 0.9 
                          ? AppColors.error 
                          : monthExpenses / totalBudgetLimit >= 0.75
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${((monthExpenses / totalBudgetLimit) * 100).toStringAsFixed(1)}% dari total budget terpakai',
                    style: TextStyle(
                      fontSize: 10,
                      color: themeProvider.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetsList(ThemeProvider themeProvider, TransactionProvider provider) {
    final monthKey = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
    final currentBudgets = provider.budgets
        .where((budget) => budget.monthYear == monthKey)
        .toList();

    if (_isRecalculating && currentBudgets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menghitung ulang budget...'),
          ],
        ),
      );
    }

    if (currentBudgets.isEmpty) {
      return _buildEmptyState(themeProvider);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentBudgets.length,
      itemBuilder: (context, index) {
        final budget = currentBudgets[index];
        return _buildBudgetCard(budget, themeProvider, provider);
      },
    );
  }

  Widget _buildBudgetCard(Budget budget, ThemeProvider themeProvider, TransactionProvider transactionProvider) {
    final color = Color(int.parse(budget.color?.replaceFirst('#', '0xFF') ?? '0xFF6366F1'));
    final progress = budget.percentageUsed / 100;
    
    // Hitung real expense dari transaksi
    final realExpense = transactionProvider.getExpenseForCategoryThisMonth(budget.category);
    
    final difference = (budget.currentAmount - realExpense).abs();
    final hasDiscrepancy = difference > 100; // Jika selisih > Rp 100
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan icon dan category
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    budget.icon ?? '📊',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.textColor,
                        ),
                      ),
                      Text(
                        budget.monthName,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                      // Tampilkan real expense vs budget
                      if (hasDiscrepancy)
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              size: 12,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Data transaksi: Rp ${NumberFormat('#,###').format(realExpense)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.more_vert),
                  onPressed: _isSyncing ? null : () => _showBudgetMenu(budget, transactionProvider),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress bar dan info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Digunakan: ${budget.formattedCurrent}',
                          style: TextStyle(
                            fontSize: 14,
                            color: themeProvider.secondaryTextColor,
                          ),
                        ),
                        if (hasDiscrepancy)
                          Text(
                            'Klik sync untuk update',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Limit: ${budget.formattedLimit}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.textColor,
                          ),
                        ),
                        Text(
                          'Sisa: ${budget.formattedRemaining}',
                          style: TextStyle(
                            fontSize: 12,
                            color: budget.remainingAmount >= 0 
                                ? AppColors.success 
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                Stack(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        budget.statusColor,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                    // Progress text overlay
                    if (progress > 0.15)
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Text(
                          '${budget.percentageUsed.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: progress > 0.5 ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Info tambahan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Persentase
                    Text(
                      '${budget.percentageUsed.toStringAsFixed(1)}% terpakai',
                      style: TextStyle(
                        fontSize: 12,
                        color: budget.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Tombol sync jika ada discrepancy
                    if (hasDiscrepancy)
                      TextButton(
                        onPressed: () => _syncBudgetWithTransactions(budget),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sync',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            // Warning message jika budget hampir habis
            if (budget.percentageUsed >= 75)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: budget.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: budget.statusColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      budget.percentageUsed >= 90 ? Icons.warning : Icons.info,
                      color: budget.statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.percentageUsed >= 90 
                                ? 'Budget hampir habis!' 
                                : 'Perhatian!',
                            style: TextStyle(
                              color: budget.statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Budget ${budget.category} sudah terpakai ${budget.percentageUsed.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: budget.statusColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: themeProvider.secondaryTextColor.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada budget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan budget untuk kategori pengeluaran',
              style: TextStyle(
                color: themeProvider.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showAddBudgetDialog(context, Provider.of<TransactionProvider>(context, listen: false)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tambah Budget Pertama'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, TransactionProvider provider) {
    String selectedCategory = _defaultCategories.first['name'];
    final amountController = TextEditingController();
    final monthController = TextEditingController(
      text: DateFormat('yyyy-MM').format(_selectedMonth),
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Budget'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Month input
                    TextFormField(
                      controller: monthController,
                      decoration: InputDecoration(
                        labelText: 'Bulan (YYYY-MM)',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Provider.of<ThemeProvider>(context).cardColor,
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedMonth,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          monthController.text = DateFormat('yyyy-MM').format(picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Category selector
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Provider.of<ThemeProvider>(context).cardColor,
                      ),
                      items: _defaultCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['name'],
                          child: Row(
                            children: [
                              Text(category['icon']),
                              const SizedBox(width: 8),
                              Text(category['name']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedCategory = value);
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Amount input
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Limit Budget',
                        prefixText: '${AppStrings.currencySymbol} ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Provider.of<ThemeProvider>(context).cardColor,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan jumlah budget';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Masukkan jumlah yang valid';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    if (amount != null && amount > 0) {
                      final selectedCat = _defaultCategories
                          .firstWhere((cat) => cat['name'] == selectedCategory);
                      
                      final budget = Budget(
                        category: selectedCategory,
                        amountLimit: amount,
                        monthYear: monthController.text,
                        icon: selectedCat['icon'],
                        color: selectedCat['color'],
                      );
                      
                      provider.addBudget(budget);
                      
                      // Recalculate budgets setelah menambah budget baru
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _recalculateBudgets();
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Budget berhasil ditambahkan'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                      
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBudgetMenu(Budget budget, TransactionProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Edit Budget'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditBudgetDialog(budget, provider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync, color: AppColors.primary),
                title: const Text('Sync dengan Transaksi'),
                onTap: () {
                  Navigator.pop(context);
                  _syncBudgetWithTransactions(budget);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Hapus Budget'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteBudgetDialog(budget, provider);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showEditBudgetDialog(Budget budget, TransactionProvider provider) {
    final amountController = TextEditingController(text: budget.amountLimit.toString());
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Budget'),
          content: TextFormField(
            controller: amountController,
            decoration: InputDecoration(
              labelText: 'Limit Budget',
              prefixText: '${AppStrings.currencySymbol} ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Provider.of<ThemeProvider>(context).cardColor,
            ),
            keyboardType: TextInputType.number,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  final updatedBudget = Budget(
                    id: budget.id,
                    category: budget.category,
                    amountLimit: amount,
                    currentAmount: budget.currentAmount,
                    monthYear: budget.monthYear,
                    icon: budget.icon,
                    color: budget.color,
                  );
                  
                  provider.updateBudget(updatedBudget);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Budget berhasil diperbarui'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteBudgetDialog(Budget budget, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Budget'),
          content: Text('Apakah Anda yakin ingin menghapus budget "${budget.category}"?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                provider.deleteBudget(budget.id!);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Budget berhasil dihapus'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}