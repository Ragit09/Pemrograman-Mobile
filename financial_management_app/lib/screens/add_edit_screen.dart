import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart' as model;
import '../utils/constants.dart';

class AddEditScreen extends StatefulWidget {
  final model.Transaction? transaction;

  const AddEditScreen({super.key, this.transaction});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'expense';
  String _selectedCategory = 'Makanan';
  DateTime _selectedDate = DateTime.now();
  bool _isFavorite = false;
  
  // TAMBAHKAN CURRENCY SELECTION
  String _selectedCurrency = 'IDR';
  
  final List<Map<String, dynamic>> _incomeCategories = [
    {'name': 'Gaji', 'icon': Icons.attach_money},
    {'name': 'Bonus', 'icon': Icons.card_giftcard},
    {'name': 'Investasi', 'icon': Icons.trending_up},
    {'name': 'Hadiah', 'icon': Icons.card_giftcard},
    {'name': 'Freelance', 'icon': Icons.work},
    {'name': 'Bisnis', 'icon': Icons.business},
    {'name': 'Penjualan', 'icon': Icons.sell},
    {'name': 'Dividen', 'icon': Icons.account_balance_wallet},
    {'name': 'Tabungan', 'icon': Icons.savings},
    {'name': 'Komisi', 'icon': Icons.percent},
    {'name': 'Sewa', 'icon': Icons.home},
    {'name': 'Pinjaman', 'icon': Icons.account_balance},
    {'name': 'Asuransi', 'icon': Icons.security},
    {'name': 'Hibah', 'icon': Icons.volunteer_activism},
    {'name': 'Lainnya', 'icon': Icons.more_horiz},
  ];
  
  final List<Map<String, dynamic>> _expenseCategories = [
    {'name': 'Makanan', 'icon': Icons.restaurant},
    {'name': 'Transportasi', 'icon': Icons.directions_car},
    {'name': 'Belanja', 'icon': Icons.shopping_cart},
    {'name': 'Hiburan', 'icon': Icons.movie},
    {'name': 'Kesehatan', 'icon': Icons.medical_services},
    {'name': 'Pendidikan', 'icon': Icons.school},
    {'name': 'Tagihan', 'icon': Icons.receipt},
    {'name': 'Komunikasi', 'icon': Icons.phone},
    {'name': 'Listrik', 'icon': Icons.electrical_services},
    {'name': 'Air', 'icon': Icons.water_drop},
    {'name': 'Internet', 'icon': Icons.wifi},
    {'name': 'Bensin', 'icon': Icons.local_gas_station},
    {'name': 'Pakaian', 'icon': Icons.checkroom},
    {'name': 'Kosmetik', 'icon': Icons.face},
    {'name': 'Lainnya', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _titleController.text = t.title;
      _amountController.text = t.originalAmount.toString();
      _descriptionController.text = t.description ?? '';
      _selectedType = t.type;
      _selectedCategory = t.category;
      _selectedDate = t.date;
      _isFavorite = t.isFavorite;
      _selectedCurrency = t.transactionCurrency;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentCategories => 
      _selectedType == 'income' ? _incomeCategories : _expenseCategories;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null ? 'Tambah Transaksi' : 'Edit Transaksi',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type selector
              _buildTypeSelector(themeProvider),
              const SizedBox(height: 24),
              
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Transaksi',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul transaksi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Amount field dengan currency selector - DIUBAH
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Jumlah',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah tidak boleh kosong';
                        }

                        final cleanValue = value.replaceAll('.', '').replaceAll(',', '.');
                        final amount = double.tryParse(cleanValue);

                        if (amount == null || amount <= 0) {
                          return 'Masukkan jumlah yang valid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // TAMBAHKAN CURRENCY SELECTOR
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Mata Uang',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: AppCurrencies.supportedCurrencies.map((currency) {
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Row(
                            children: [
                              Text(AppCurrencies.currencyFlags[currency] ?? '🏳️'),
                              const SizedBox(width: 4),
                              Text(currency),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCurrency = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              // TAMBAHKAN CONVERSION PREVIEW
              if (_selectedCurrency != 'IDR' && _amountController.text.isNotEmpty)
                FutureBuilder<double>(
                  future: transactionProvider.convertCurrency(
                    amount: double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
                    fromCurrency: _selectedCurrency,
                    toCurrency: 'IDR',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data! > 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.info, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '≈ ${transactionProvider.formatCurrency(snapshot.data!, 'IDR')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              
              const SizedBox(height: 16),
              
              // Category selector
              _buildCategorySelector(),
              const SizedBox(height: 16),
              
              // Date picker
              _buildDatePicker(themeProvider),
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Favorite toggle
              SwitchListTile(
                title: const Text('Tandai sebagai Favorit'),
                subtitle: const Text('Transaksi favorit akan ditandai dengan hati'),
                value: _isFavorite,
                onChanged: (value) => setState(() => _isFavorite = value),
                activeColor: AppColors.primary,
              ),
              
              const SizedBox(height: 32),
              
              // Save button
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.transaction == null ? 'Simpan Transaksi' : 'Update Transaksi',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              
              // TAMBAHKAN CURRENCY INFO
              if (_selectedCurrency != 'IDR')
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    '💡 Transaksi akan disimpan dalam ${AppCurrencies.currencyFlags[_selectedCurrency]} $_selectedCurrency dan dikonversi ke IDR',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Expense Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'expense';
                  _selectedCategory = _expenseCategories.first['name']!;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'expense'
                      ? AppColors.expenseColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedType == 'expense'
                        ? AppColors.expenseColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pengeluaran',
                      style: TextStyle(
                        color: _selectedType == 'expense'
                            ? AppColors.expenseColor
                            : themeProvider.secondaryTextColor,
                        fontWeight: _selectedType == 'expense'
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Income Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'income';
                  _selectedCategory = _incomeCategories.first['name']!;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'income'
                      ? AppColors.incomeColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedType == 'income'
                        ? AppColors.incomeColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pemasukan',
                      style: TextStyle(
                        color: _selectedType == 'income'
                            ? AppColors.incomeColor
                            : themeProvider.secondaryTextColor,
                        fontWeight: _selectedType == 'income'
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentCategories.map((category) {
            final isSelected = _selectedCategory == category['name'];
            final icon = category['icon'] as IconData;
            
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                  Text(category['name']!),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category['name']!);
                }
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker(ThemeProvider themeProvider) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.textColor,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveTransaction() {
    print('[ADD/EDIT SCREEN] Save button pressed');
    
    if (_formKey.currentState!.validate()) {
      print('[ADD/EDIT SCREEN] Form validation PASSED');
      
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      // Clean and parse amount
      final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '.');
      final originalAmount = double.tryParse(amountText);
      
      if (originalAmount == null || originalAmount <= 0) {
        print('[ADD/EDIT SCREEN] Invalid amount: ${_amountController.text}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Masukkan jumlah yang valid'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      print('[ADD/EDIT SCREEN] Creating transaction object...');
      print('  Title: ${_titleController.text}');
      print('  Original Amount: $originalAmount');
      print('  Currency: $_selectedCurrency');
      print('  Category: $_selectedCategory');
      print('  Type: $_selectedType');
      
      // Buat transaction object
      final transaction = model.Transaction(
        id: widget.transaction?.id,
        title: _titleController.text.trim(),
        amount: originalAmount, // Akan di-convert di provider
        category: _selectedCategory,
        date: _selectedDate,
        type: _selectedType,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        isFavorite: _isFavorite,
        // TAMBAHKAN CURRENCY FIELDS
        originalCurrency: _selectedCurrency,
        originalAmount: originalAmount,
        transactionCurrency: _selectedCurrency,
      );
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(widget.transaction == null 
                  ? 'Menyimpan transaksi...' 
                  : 'Memperbarui transaksi...'),
            ],
          ),
        ),
      );
      
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          if (widget.transaction == null) {
            print('[ADD/EDIT SCREEN] Calling addTransaction...');
            transactionProvider.addTransaction(transaction);
          } else {
            print('[ADD/EDIT SCREEN] Calling updateTransaction...');
            transactionProvider.updateTransaction(transaction);
          }
          
          // Close loading dialog
          Navigator.pop(context);
          
          // Close screen
          Navigator.pop(context);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.transaction == null 
                    ? '✅ Transaksi berhasil ditambahkan!' 
                    : '✅ Transaksi berhasil diperbarui!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          print('[ADD/EDIT SCREEN] Transaction saved successfully');
          
        } catch (e) {
          // Close loading dialog
          Navigator.pop(context);
          
          print('[ADD/EDIT SCREEN ERROR] Failed to save: $e');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ Gagal menyimpan transaksi: ${e.toString()}',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
      
    } else {
      print('[ADD/EDIT SCREEN] Form validation FAILED');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Harap isi semua field dengan benar'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}