import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class Transaction {
  int? id;
  final String title;
  double amount; // Changed to mutable for conversion
  final String category;
  final DateTime date;
  final String type;
  final String? description;
  bool isFavorite;
  final String? icon;
  final String? color;
  
  // TAMBAHKAN FIELD BARU UNTUK MULTI-CURRENCY
  String originalCurrency;
  double originalAmount;
  String transactionCurrency;
  
  Transaction({
    this.id,
    required this.title,
    required double amount,
    required this.category,
    required this.date,
    required this.type,
    this.description,
    this.isFavorite = false,
    this.icon,
    this.color,
    // Parameter baru dengan default values
    this.originalCurrency = 'IDR',
    double? originalAmount,
    String? transactionCurrency,
  }) : 
    amount = amount,
    originalAmount = originalAmount ?? amount,
    transactionCurrency = transactionCurrency ?? originalCurrency;
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
      'is_favorite': isFavorite ? 1 : 0,
      'icon': icon,
      'color': color,
      // TAMBAHKAN FIELD BARU
      'original_currency': originalCurrency,
      'original_amount': originalAmount,
      'transaction_currency': transactionCurrency,
    };
  }
  
  factory Transaction.fromMap(Map<String, dynamic> map) {
    try {
      DateTime parsedDate;
      if (map['date'] is String) {
        parsedDate = DateTime.parse(map['date'] as String);
      } else if (map['date'] is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(map['date'] as int);
      } else {
        parsedDate = DateTime.now();
      }
      
      double parsedAmount;
      if (map['amount'] is int) {
        parsedAmount = (map['amount'] as int).toDouble();
      } else if (map['amount'] is double) {
        parsedAmount = map['amount'] as double;
      } else if (map['amount'] is String) {
        parsedAmount = double.tryParse(map['amount'] as String) ?? 0.0;
      } else {
        parsedAmount = 0.0;
      }
      
      // Parse original amount (field baru)
      double parsedOriginalAmount;
      if (map['original_amount'] != null) {
        if (map['original_amount'] is int) {
          parsedOriginalAmount = (map['original_amount'] as int).toDouble();
        } else if (map['original_amount'] is double) {
          parsedOriginalAmount = map['original_amount'] as double;
        } else {
          parsedOriginalAmount = parsedAmount;
        }
      } else {
        parsedOriginalAmount = parsedAmount;
      }
      
      // Parse original currency (field baru)
      String parsedOriginalCurrency = map['original_currency']?.toString() ?? 'IDR';
      String parsedTransactionCurrency = map['transaction_currency']?.toString() ?? parsedOriginalCurrency;
      
      bool parsedIsFavorite;
      if (map['is_favorite'] == 1 || map['is_favorite'] == true) {
        parsedIsFavorite = true;
      } else {
        parsedIsFavorite = false;
      }
      
      return Transaction(
        id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
        title: map['title']?.toString().trim() ?? 'Unknown Transaction',
        amount: parsedAmount,
        category: map['category']?.toString().trim() ?? 'Other',
        date: parsedDate,
        type: (map['type']?.toString().toLowerCase() == 'income') ? 'income' : 'expense',
        description: map['description']?.toString().trim(),
        isFavorite: parsedIsFavorite,
        icon: map['icon']?.toString(),
        color: map['color']?.toString(),
        // Field baru
        originalCurrency: parsedOriginalCurrency,
        originalAmount: parsedOriginalAmount,
        transactionCurrency: parsedTransactionCurrency,
      );
    } catch (e) {
      print('[TRANSACTION MODEL ERROR] Failed to parse: $e');
      
      return Transaction(
        id: 0,
        title: 'Error Transaction',
        amount: 0.0,
        category: 'Error',
        date: DateTime.now(),
        type: 'expense',
        description: 'Error parsing transaction data',
        isFavorite: false,
        icon: '⚠️',
        color: '#FF0000',
        originalCurrency: 'IDR',
        originalAmount: 0.0,
        transactionCurrency: 'IDR',
      );
    }
  }
  
  // TAMBAHKAN METHOD BARU UNTUK CURRENCY
  String get formattedAmountWithCurrency {
    try {
      final symbol = AppCurrencies.currencySymbols[transactionCurrency] ?? transactionCurrency;
      // JANGAN round - tampilkan nilai asli tanpa pembulatan
      final formatter = NumberFormat.currency(
        symbol: symbol,
        decimalDigits: transactionCurrency == 'IDR' ? 0 : 2,
      );

      return formatter.format(originalAmount);
    } catch (e) {
      return 'Rp 0';
    }
  }
  
  String get currencyFlag {
    return AppCurrencies.currencyFlags[transactionCurrency] ?? '🏳️';
  }
  
  bool get isForeignCurrency {
    return transactionCurrency != 'IDR';
  }
  
  // Method lama tetap ada
  String get formattedDate {
    try {
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }
  
  String get formattedTime {
    try {
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return 'Invalid Time';
    }
  }
  
  String get formattedAmount {
    try {
      final formatter = NumberFormat.currency(
        symbol: AppStrings.currencySymbol,
        decimalDigits: 0,
      );
      return formatter.format(amount);
    } catch (e) {
      return '${AppStrings.currencySymbol} 0';
    }
  }
  
  Color get categoryColor {
    if (color != null && color!.isNotEmpty) {
      try {
        String colorString = color!;
        if (colorString.startsWith('#')) {
          colorString = colorString.replaceFirst('#', '');
          if (colorString.length == 6) {
            colorString = 'FF$colorString';
          }
          if (colorString.length == 8) {
            return Color(int.parse(colorString, radix: 16));
          }
        }
      } catch (e) {
        print('[TRANSACTION MODEL] Error parsing color $color: $e');
      }
    }
    
    return type == 'income' ? AppColors.incomeColor : AppColors.expenseColor;
  }
  
  String get categoryIcon {
    if (icon != null && icon!.isNotEmpty) {
      return icon!;
    }
    
    switch (category.toLowerCase()) {
      case 'gaji': return '💰';
      case 'bonus': return '🎁';
      case 'investasi': return '📈';
      case 'makanan': return '🍔';
      case 'transportasi': return '🚗';
      case 'belanja': return '🛒';
      case 'hiburan': return '🎬';
      case 'kesehatan': return '⚕️';
      case 'pendidikan': return '📚';
      case 'hadiah': return '🎁';
      case 'tagihan': return '📄';
      case 'lainnya': return '📦';
      default: return type == 'income' ? '📈' : '📉';
    }
  }
  
  void printDebugInfo() {
    print('[TRANSACTION DEBUG]');
    print('  ID: $id');
    print('  Title: $title');
    print('  Amount: $amount');
    print('  Original Amount: $originalAmount');
    print('  Currency: $transactionCurrency');
    print('  Original Currency: $originalCurrency');
    print('  Category: $category');
    print('  Date: $date');
    print('  Type: $type');
    print('  Description: $description');
    print('  IsFavorite: $isFavorite');
  }
}