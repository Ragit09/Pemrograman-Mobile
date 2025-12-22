import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import 'add_edit_screen.dart';
import '../utils/constants.dart';

class DetailScreen extends StatefulWidget {
  final Transaction transaction;

  const DetailScreen({super.key, required this.transaction});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Transaction _currentTransaction;

  @override
  void initState() {
    super.initState();
    _currentTransaction = widget.transaction;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Update current transaction from provider if it exists
    final updatedTransaction = provider.transactions.firstWhere(
      (t) => t.id == _currentTransaction.id,
      orElse: () => _currentTransaction,
    );
    _currentTransaction = updatedTransaction;

    final categoryColor = _currentTransaction.categoryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditScreen(transaction: _currentTransaction),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Text(
                      '💰', // Placeholder - akan diganti dengan icon
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _currentTransaction.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: themeProvider.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // TAMBAHKAN INFO CURRENCY DI JUDUL
                  if (_currentTransaction.isForeignCurrency)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_currentTransaction.currencyFlag),
                        const SizedBox(width: 4),
                        Text(
                          _currentTransaction.transactionCurrency,
                          style: TextStyle(
                            fontSize: 14,
                            color: themeProvider.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  Text(
                    _currentTransaction.category,
                    style: TextStyle(
                      fontSize: 16,
                      color: themeProvider.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Details card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Amount - PERBAIKAN: Gunakan display currency
                      _buildAmountDetail(provider, themeProvider),
                      const SizedBox(height: 20),

                      // Type
                      _buildDetailRow(
                        'Tipe',
                        _currentTransaction.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
                        _currentTransaction.type == 'income'
                            ? AppColors.incomeColor
                            : AppColors.expenseColor,
                        _currentTransaction.type == 'income'
                            ? Icons.trending_up
                            : Icons.trending_down,
                      ),
                      const SizedBox(height: 20),

                      // Date
                      _buildDetailRow(
                        'Tanggal',
                        '${_currentTransaction.formattedDate} • ${_currentTransaction.formattedTime}',
                        AppColors.primary,
                        Icons.calendar_today,
                      ),
                      const SizedBox(height: 20),

                      // Favorite status
                      _buildDetailRow(
                        'Status',
                        _currentTransaction.isFavorite ? 'Favorit' : 'Biasa',
                        _currentTransaction.isFavorite ? AppColors.error : Colors.grey,
                        _currentTransaction.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Description
            if (_currentTransaction.description != null &&
                _currentTransaction.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.description,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Deskripsi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: themeProvider.textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentTransaction.description!,
                          style: TextStyle(
                            fontSize: 16,
                            color: themeProvider.secondaryTextColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Currency conversion info (untuk foreign currency)
            if (_currentTransaction.isForeignCurrency)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.currency_exchange,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Info Konversi Mata Uang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: themeProvider.textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Tampilkan informasi konversi
                        Row(
                          children: [
                            Text(
                              'Nilai asli: ',
                              style: TextStyle(
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                            Text(
                              _currentTransaction.formattedAmountWithCurrency,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _currentTransaction.type == 'income'
                                    ? AppColors.incomeColor
                                    : AppColors.expenseColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Dalam ${provider.displayCurrency}: ',
                              style: TextStyle(
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                            Text(
                              provider.formatCurrency(_currentTransaction.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _currentTransaction.type == 'income'
                                    ? AppColors.incomeColor
                                    : AppColors.expenseColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mata uang: ${_currentTransaction.transactionCurrency} ${_currentTransaction.currencyFlag}',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeProvider.secondaryTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Quick actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_currentTransaction.id == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error: ID transaksi tidak valid'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                          );
                          return;
                        }

                        await Provider.of<TransactionProvider>(context, listen: false)
                            .toggleFavorite(_currentTransaction.id!);

                        // Get the updated transaction after toggle
                        final updatedTransaction = Provider.of<TransactionProvider>(context, listen: false)
                            .transactions.firstWhere(
                              (t) => t.id == _currentTransaction.id,
                              orElse: () => _currentTransaction,
                            );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              updatedTransaction.isFavorite
                                  ? 'Ditambahkan ke favorit'
                                  : 'Dihapus dari favorit',
                            ),
                            backgroundColor: updatedTransaction.isFavorite
                                ? AppColors.primary
                                : Colors.grey,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        _currentTransaction.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                      label: Text(
                        _currentTransaction.isFavorite
                            ? 'Hapus Favorit'
                            : 'Tambah Favorit',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentTransaction.isFavorite ? Colors.grey[200] : null,
                        foregroundColor:
                            _currentTransaction.isFavorite ? Colors.grey[800] : null,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddEditScreen(transaction: _currentTransaction),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // PERBAIKAN: Widget baru untuk menampilkan amount dengan currency info
  Widget _buildAmountDetail(TransactionProvider provider, ThemeProvider themeProvider) {
    final amountColor = _currentTransaction.type == 'income'
        ? AppColors.incomeColor
        : AppColors.expenseColor;
    
    // PERBAIKAN: formatCurrency hanya menerima 1 parameter
    final displayedAmount = provider.formatCurrency(_currentTransaction.amount);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.attach_money, color: amountColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jumlah',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Tampilkan dalam display currency
                  Text(
                    displayedAmount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Tampilkan amount asli untuk foreign currency
        if (_currentTransaction.isForeignCurrency)
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_currentTransaction.currencyFlag),
                    const SizedBox(width: 4),
                    Text(
                      'Nilai asli: ${_currentTransaction.formattedAmountWithCurrency}',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Mata uang: ${_currentTransaction.transactionCurrency}',
                  style: TextStyle(
                    fontSize: 10,
                    color: themeProvider.secondaryTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Transaksi'),
          content: Text(
              'Apakah Anda yakin ingin menghapus transaksi "${_currentTransaction.title}"?'),
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
                if (_currentTransaction.id == null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: ID transaksi tidak valid'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                Provider.of<TransactionProvider>(context, listen: false)
                    .deleteTransaction(_currentTransaction.id!);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaksi berhasil dihapus'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                );

                Navigator.pop(context);
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