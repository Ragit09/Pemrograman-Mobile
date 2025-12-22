import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF10B981);
  static const Color accent = Color(0xFFF59E0B);
  static const Color background = Color(0xFFF9FAFB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color incomeColor = Color(0xFF10B981);
  static const Color expenseColor = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  
  static const Color darkBackground = Color(0xFF1F2937);
  static const Color darkCard = Color(0xFF374151);
  static const Color darkText = Color(0xFFF9FAFB);
}

class AppStrings {
  static const String appName = 'FinFlow';
  static const String currencySymbol = 'Rp';
}

// TAMBAHKAN CLASS BARU UNTUK CURRENCY
class AppCurrencies {
  static const List<String> supportedCurrencies = [
    'IDR', 'USD', 'EUR', 'GBP', 'JPY', 
    'SGD', 'MYR', 'AUD', 'CNY', 'CAD'
  ];
  
  static Map<String, String> get currencyFlags {
    return {
      'IDR': '🇮🇩',
      'USD': '🇺🇸',
      'EUR': '🇪🇺',
      'GBP': '🇬🇧',
      'JPY': '🇯🇵',
      'SGD': '🇸🇬',
      'MYR': '🇲🇾',
      'AUD': '🇦🇺',
      'CNY': '🇨🇳',
      'CAD': '🇨🇦',
    };
  }
  
  static Map<String, String> get currencySymbols {
    return {
      'IDR': 'Rp',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'SGD': 'S\$',
      'MYR': 'RM',
      'AUD': 'A\$',
      'CNY': '¥',
      'CAD': 'C\$',
    };
  }
  
  // Hardcoded fallback rates (update periodically)
  static Map<String, Map<String, double>> get fallbackRates {
    return {
      'USD': {
        'IDR': 15523.50,
        'EUR': 0.91,
        'GBP': 0.78,
        'JPY': 145.22,
        'SGD': 1.33,
        'MYR': 4.68,
        'AUD': 1.49,
        'CNY': 7.18,
      },
      'IDR': {
        'USD': 0.000064,
        'EUR': 0.000059,
        'GBP': 0.000050,
        'JPY': 0.0094,
        'SGD': 0.000086,
        'MYR': 0.00030,
      },
      'EUR': {
        'IDR': 16950.00,
        'USD': 1.10,
        'GBP': 0.86,
        'JPY': 159.50,
      },
    };
  }
}

class AppIcons {
  static const IconData home = Icons.home;
  static const IconData transactions = Icons.list_alt;
  static const IconData stats = Icons.bar_chart;
  static const IconData budget = Icons.account_balance_wallet;
  static const IconData settings = Icons.settings;
  static const IconData add = Icons.add;
  static const IconData income = Icons.trending_up;
  static const IconData expense = Icons.trending_down;
  static const IconData food = Icons.restaurant;
  static const IconData transport = Icons.directions_car;
  static const IconData shopping = Icons.shopping_cart;
  static const IconData entertainment = Icons.movie;
  static const IconData salary = Icons.attach_money;
  static const IconData investment = Icons.show_chart;
  static const IconData health = Icons.medical_services;
  static const IconData education = Icons.school;
  static const IconData other = Icons.category;
  static const IconData receipt = Icons.receipt;
  static const IconData favorite = Icons.favorite;
  static const IconData calendar = Icons.calendar_today;
  static const IconData description = Icons.description;
  static const IconData check = Icons.check_circle;
  static const IconData warning = Icons.warning;
  static const IconData error = Icons.error;
  static const IconData money = Icons.attach_money;
  static const IconData gift = Icons.card_giftcard;
  static const IconData chart = Icons.trending_up;
  // TAMBAHKAN ICON CURRENCY
  static const IconData currency = Icons.currency_exchange;
  static const IconData refresh = Icons.refresh;
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkCard,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      filled: true,
      fillColor: AppColors.darkCard,
      hintStyle: TextStyle(color: Colors.grey[400]),
      labelStyle: TextStyle(color: Colors.grey[300]),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}