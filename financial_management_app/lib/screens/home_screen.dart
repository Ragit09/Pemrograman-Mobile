import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart' as model;
import '../utils/constants.dart';
import 'add_edit_screen.dart';
import 'transactions_screen.dart';
import 'budgets_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const BudgetsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refresh button saja (hapus currency selector)
          IconButton(
            icon: transactionProvider.isLoadingRates
                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Icon(AppIcons.refresh, color: Colors.white),
            onPressed: transactionProvider.isLoadingRates
                ? null
                : () => transactionProvider.refreshExchangeRates(),
            tooltip: 'Refresh exchange rates',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Balance Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Saldo Bulan Ini',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4), // Dikurangi dari 8 ke 4
                    Text(
                      transactionProvider.formatCurrency(transactionProvider.balance),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode 
                            ? Colors.white 
                            : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 20), // Tambah spacing sebelum pemasukan/pengeluaran
                    
                    // Pemasukan dan Pengeluaran
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniCard(
                          'Pemasukan',
                          transactionProvider.totalIncome,
                          AppColors.incomeColor,
                          themeProvider,
                          transactionProvider,
                        ),
                        _buildMiniCard(
                          'Pengeluaran',
                          transactionProvider.totalExpense,
                          AppColors.expenseColor,
                          themeProvider,
                          transactionProvider,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Quick Actions
            Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add,
                    label: 'Tambah Transaksi',
                    color: AppColors.primary,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.list,
                    label: 'Lihat Semua',
                    color: AppColors.secondary,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Recent Transactions
            Text(
              'Transaksi Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 12),
            
            if (transactionProvider.transactions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
              )
            else
              ...transactionProvider.transactions.take(3).map((transaction) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transaction.type == 'income'
                          ? AppColors.incomeColor.withOpacity(0.2)
                          : AppColors.expenseColor.withOpacity(0.2),
                      child: Icon(
                        transaction.type == 'income'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: transaction.type == 'income'
                            ? AppColors.incomeColor
                            : AppColors.expenseColor,
                      ),
                    ),
                    title: Text(
                      transaction.title,
                      style: TextStyle(
                        color: themeProvider.textColor,
                      ),
                    ),
                    subtitle: Text(
                      '${transaction.category} • ${DateFormat('dd/MM/yyyy').format(transaction.date)}',
                      style: TextStyle(
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          transactionProvider.formatCurrency(transaction.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: transaction.type == 'income'
                                ? AppColors.incomeColor
                                : AppColors.expenseColor,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(transaction.title),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jumlah: ${transactionProvider.formatCurrency(transaction.amount)}'),
                              Text('Kategori: ${transaction.category}'),
                              Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
                              Text('Tipe: ${transaction.type == 'income' ? 'Pemasukan' : 'Pengeluaran'}'),
                              Text('Favorite: ${transaction.isFavorite ? 'Ya' : 'Tidak'}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  // Update mini card dengan spacing yang lebih rapat
  Widget _buildMiniCard(String title, double amount, Color color, 
      ThemeProvider themeProvider, TransactionProvider currencyProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: themeProvider.secondaryTextColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2), // Dikurangi dari 4 ke 2
        Text(
          currencyProvider.formatCurrency(amount),
          style: TextStyle(
            color: color, 
            fontSize: 18, 
            fontWeight: FontWeight.w600
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}