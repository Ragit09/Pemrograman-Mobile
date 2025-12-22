import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/shared_prefs_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SharedPrefsService _prefsService = SharedPrefsService();
  String _userName = 'User';
  String _selectedCurrency = 'IDR';
  bool _budgetAlerts = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final name = await _prefsService.getUserName();
    final currency = await _prefsService.getCurrency();
    final alerts = await _prefsService.getBudgetAlert();
    
    setState(() {
      _userName = name;
      _selectedCurrency = currency;
      _budgetAlerts = alerts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            _buildProfileSection(themeProvider),
            const SizedBox(height: 32),
            
            // Preferences section
            _buildSectionTitle('Preferensi'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Theme mode
                  SwitchListTile(
                    title: const Text('Mode Gelap'),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16),
                  
                  // Budget alerts
                  SwitchListTile(
                    title: const Text('Notifikasi Budget'),
                    subtitle: const Text('Peringatan saat budget hampir habis'),
                    value: _budgetAlerts,
                    onChanged: (value) async {
                      setState(() => _budgetAlerts = value);
                      await _prefsService.setBudgetAlert(value);
                    },
                  ),
                  const Divider(height: 1, indent: 16),

                  // Currency selection
                  ListTile(
                    leading: const Icon(Icons.currency_exchange, color: AppColors.primary),
                    title: const Text('Mata Uang'),
                    subtitle: Text('Mata uang display: $_selectedCurrency'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showCurrencyDialog,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Exchange Rate Info Section - TAMBAHKAN DI SINI
            _buildSectionTitle('Informasi Kurs'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Simple Exchange rate info
                    _buildSimpleExchangeRateInfo(transactionProvider, themeProvider),
                    const SizedBox(height: 12),
                    
                    // Refresh button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: transactionProvider.isLoadingRates
                            ? null
                            : () => transactionProvider.refreshExchangeRates(),
                        icon: transactionProvider.isLoadingRates
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: themeProvider.isDarkMode ? Colors.white : AppColors.primary,
                                ),
                              )
                            : Icon(
                                Icons.refresh,
                                color: themeProvider.isDarkMode ? Colors.white70 : AppColors.primary,
                              ),
                        label: Text(
                          transactionProvider.isLoadingRates 
                              ? 'Memperbarui...' 
                              : 'Perbarui Kurs',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white70 : AppColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Data management section
            _buildSectionTitle('Manajemen Data'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Export data
                  ListTile(
                    leading: const Icon(Icons.backup, color: AppColors.primary),
                    title: const Text('Ekspor Data'),
                    subtitle: const Text('Simpan data ke file'),
                    onTap: _exportData,
                    trailing: _isExporting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: themeProvider.isDarkMode ? Colors.white70 : AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.chevron_right),
                  ),
                  const Divider(height: 1, indent: 16),
                  
                  // Clear data
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Hapus Semua Data'),
                    subtitle: const Text('Reset aplikasi ke keadaan awal'),
                    onTap: _showClearDataDialog,
                    trailing: const Icon(Icons.chevron_right),
                    textColor: Colors.red,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // App info
            Center(
              child: Column(
                children: [
                  Text(
                    'Financial Management App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2024 - UAS Pemrograman Mobile',
                    style: TextStyle(
                      color: themeProvider.secondaryTextColor,
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

  Widget _buildProfileSection(ThemeProvider themeProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pengguna FinFlow',
                    style: TextStyle(
                      color: themeProvider.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                color: themeProvider.isDarkMode ? Colors.white70 : AppColors.primary,
              ),
              onPressed: () => _showEditNameDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: themeProvider.textColor,
        ),
      ),
    );
  }

  // TAMBAHKAN METHOD UNTUK SIMPLE EXCHANGE RATE INFO
  Widget _buildSimpleExchangeRateInfo(TransactionProvider provider, ThemeProvider themeProvider) {
    if (provider.exchangeRates.isEmpty || provider.isLoadingRates) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info,
              color: themeProvider.isDarkMode ? Colors.blue[300] : Colors.blue,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Sedang memuat kurs...',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }
    
    final usdRate = provider.usdToIdrRate;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode 
            ? Colors.blue[900]!.withOpacity(0.3)
            : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.isDarkMode 
              ? Colors.blue[700]!.withOpacity(0.5)
              : Colors.blue[100]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🇺🇸',
                style: TextStyle(
                  fontSize: themeProvider.isDarkMode ? 22 : 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Kurs USD ke IDR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Exchange Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '1 USD = ',
                style: TextStyle(
                  fontSize: themeProvider.isDarkMode ? 16 : 17,
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
              Text(
                provider.formatCurrency(usdRate, 'IDR'),
                style: TextStyle(
                  fontSize: themeProvider.isDarkMode ? 20 : 22,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.green[300] : Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Last Update
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Update: ${provider.formattedLastRateUpdate}',
                style: TextStyle(
                  fontSize: 12,
                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final nameController = TextEditingController(text: _userName);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Nama'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Masukkan nama Anda',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  await _prefsService.setUserName(newName);
                  setState(() => _userName = newName);
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      await Future.delayed(const Duration(seconds: 2)); // Simulate export
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil diekspor'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Semua Data'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus semua data transaksi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearAllData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllData() async {
    try {
      final dbService = DatabaseService();
      final db = await dbService.database;

      // Clear data tanpa memanggil private method
      await db.delete('transactions');
      await db.delete('budgets');

      // Refresh provider
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.loadTransactions();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua data berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Mata Uang'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: AppCurrencies.supportedCurrencies.map((currency) {
                  return ListTile(
                    leading: Text(
                      AppCurrencies.currencyFlags[currency] ?? '🏳️',
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(currency),
                    subtitle: Text(AppCurrencies.currencySymbols[currency] ?? currency),
                    trailing: _selectedCurrency == currency
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      await _changeCurrency(currency);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeCurrency(String newCurrency) async {
    if (newCurrency == _selectedCurrency) return;

    try {
      // Update shared preferences
      await _prefsService.setCurrency(newCurrency);

      // Update transaction provider
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.setDisplayCurrency(newCurrency);

      setState(() {
        _selectedCurrency = newCurrency;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mata uang berhasil diubah ke $newCurrency'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah mata uang: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}