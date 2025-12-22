import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';
import '../utils/constants.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'all'; // all, income, expense, favorite
  String _searchQuery = '';
  final Map<int, bool> _localFavoriteStatus = {};

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter and search bar
          _buildFilterBar(themeProvider, transactionProvider),
          
          // Transactions list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await transactionProvider.refreshAll();
              },
              child: _buildTransactionsList(themeProvider, transactionProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeProvider themeProvider, TransactionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: themeProvider.cardColor,
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari transaksi...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: themeProvider.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all', themeProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Pemasukan', 'income', themeProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Pengeluaran', 'expense', themeProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Favorit', 'favorite', themeProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeProvider themeProvider) {
    final isSelected = _selectedFilter == value;
    
    Color getChipColor() {
      switch (value) {
        case 'income':
          return AppColors.incomeColor;
        case 'expense':
          return AppColors.expenseColor;
        case 'favorite':
          return AppColors.error;
        default:
          return AppColors.primary;
      }
    }
    
    final chipColor = getChipColor();
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: themeProvider.backgroundColor,
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : themeProvider.textColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? chipColor : Colors.grey[300]!,
          width: isSelected ? 1.5 : 1,
        ),
      ),
    );
  }

  Widget _buildTransactionsList(ThemeProvider themeProvider, TransactionProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Get filtered transactions based on selected filter
    List<Transaction> filteredTransactions = _getFilteredTransactions(provider.transactions);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredTransactions = filteredTransactions
          .where((t) => 
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }
    
    if (filteredTransactions.isEmpty) {
      return _buildEmptyState(themeProvider, provider);
    }

    // Group transactions by date
    final Map<String, List<Transaction>> groupedTransactions = {};
    
    for (var transaction in filteredTransactions) {
      final dateKey = transaction.formattedDate;
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    final dateKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending (newest first)

    return ListView.builder(
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final date = dateKeys[index];
        final transactions = groupedTransactions[date]!;
        
        // Sort transactions by time (newest first)
        transactions.sort((a, b) => b.date.compareTo(a.date));
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.secondaryTextColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            // Transactions for this date
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, idx) {
                return _buildTransactionItem(transactions[idx], themeProvider, provider);
              },
            ),
          ],
        );
      },
    );
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> allTransactions) {
    switch (_selectedFilter) {
      case 'income':
        return allTransactions.where((t) => t.type == 'income').toList();
      case 'expense':
        return allTransactions.where((t) => t.type == 'expense').toList();
      case 'favorite':
        return allTransactions.where((t) => t.isFavorite).toList();
      case 'all':
      default:
        return allTransactions;
    }
  }

  Widget _buildTransactionItem(Transaction transaction, ThemeProvider themeProvider, TransactionProvider transactionProvider) {
    final amountColor = transaction.type == 'income' 
        ? AppColors.incomeColor 
        : AppColors.expenseColor;
    
    final iconColor = transaction.type == 'income' 
        ? AppColors.incomeColor 
        : AppColors.expenseColor;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(transaction: transaction),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon with colored background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  transaction.type == 'income' 
                      ? Icons.trending_up 
                      : Icons.trending_down,
                  color: iconColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      transaction.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Category and type
                    Row(
                      children: [
                        Text(
                          transaction.category,
                          style: TextStyle(
                            fontSize: 14,
                            color: themeProvider.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: transaction.type == 'income'
                                ? AppColors.incomeColor.withOpacity(0.1)
                                : AppColors.expenseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            transaction.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
                            style: TextStyle(
                              fontSize: 10,
                              color: transaction.type == 'income'
                                  ? AppColors.incomeColor
                                  : AppColors.expenseColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Time
                    Text(
                      transaction.formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount and actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Amount in display currency
                  Text(
                    transactionProvider.formatCurrency(transaction.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Favorite button
                      IconButton(
                        icon: Icon(
                          transaction.isFavorite 
                              ? Icons.favorite 
                              : Icons.favorite_border,
                          size: 20,
                          color: transaction.isFavorite 
                              ? AppColors.error 
                              : themeProvider.secondaryTextColor,
                        ),
                        onPressed: () {
                          Provider.of<TransactionProvider>(context, listen: false)
                              .toggleFavorite(transaction.id!);
                        },
                      ),
                      
                      // More options button
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: themeProvider.secondaryTextColor,
                        ),
                        onPressed: () => _showActionMenu(transaction),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider, TransactionProvider provider) {
    String emptyMessage = '';
    String emptySubtitle = '';
    IconData emptyIcon = Icons.receipt_long_outlined;
    
    switch (_selectedFilter) {
      case 'income':
        emptyMessage = 'Belum ada transaksi pemasukan';
        emptySubtitle = 'Tambahkan transaksi pemasukan baru';
        emptyIcon = Icons.trending_up_outlined;
        break;
      case 'expense':
        emptyMessage = 'Belum ada transaksi pengeluaran';
        emptySubtitle = 'Tambahkan transaksi pengeluaran baru';
        emptyIcon = Icons.trending_down_outlined;
        break;
      case 'favorite':
        emptyMessage = 'Belum ada transaksi favorit';
        emptySubtitle = 'Tandai transaksi sebagai favorit untuk melihatnya di sini';
        emptyIcon = Icons.favorite_border;
        break;
      default:
        emptyMessage = 'Tidak ada transaksi';
        emptySubtitle = 'Tambahkan transaksi baru untuk memulai';
        emptyIcon = Icons.receipt_long_outlined;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 80,
              color: themeProvider.secondaryTextColor.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: TextStyle(
                color: themeProvider.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Show different buttons based on filter
            if (_selectedFilter != 'favorite')
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedFilter == 'income' 
                      ? AppColors.incomeColor 
                      : _selectedFilter == 'expense'
                          ? AppColors.expenseColor
                          : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  _selectedFilter == 'income' 
                      ? 'Tambah Pemasukan' 
                      : _selectedFilter == 'expense'
                          ? 'Tambah Pengeluaran'
                          : 'Tambah Transaksi',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            
            // Show go to all transactions button if filtered
            if (_selectedFilter != 'all')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedFilter = 'all';
                      _searchQuery = '';
                    });
                  },
                  child: Text(
                    'Lihat Semua Transaksi',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showActionMenu(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const Divider(height: 1),
              
              // Edit option
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Edit Transaksi'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditScreen(transaction: transaction),
                    ),
                  );
                },
              ),
              
              // Favorite option
              ListTile(
                leading: Icon(
                  (_localFavoriteStatus[transaction.id] ?? transaction.isFavorite) ? Icons.favorite_border : Icons.favorite,
                  color: AppColors.error,
                ),
                title: Text(
                  (_localFavoriteStatus[transaction.id] ?? transaction.isFavorite)
                      ? 'Hapus dari Favorit'
                      : 'Tambah ke Favorit',
                ),
                onTap: () {
                  setState(() {
                    _localFavoriteStatus[transaction.id!] = !(_localFavoriteStatus[transaction.id] ?? transaction.isFavorite);
                  });
                  Navigator.pop(context);
                  Provider.of<TransactionProvider>(context, listen: false)
                      .toggleFavorite(transaction.id!);
                },
              ),
              
              // View details option
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.primary),
                title: const Text('Lihat Detail'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(transaction: transaction),
                    ),
                  );
                },
              ),
              
              // Delete option
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Hapus Transaksi'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(transaction);
                },
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Transaksi'),
          content: Text(
            'Apakah Anda yakin ingin menghapus transaksi "${transaction.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Provider.of<TransactionProvider>(context, listen: false)
                    .deleteTransaction(transaction.id!);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Transaksi berhasil dihapus'),
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