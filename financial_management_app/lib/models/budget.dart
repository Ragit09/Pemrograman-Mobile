import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class Budget {
  int? id;
  final String category;
  final double amountLimit;
  double currentAmount;
  final String monthYear; // Format: 'YYYY-MM'
  final String? icon;
  final String? color;
  
  Budget({
    this.id,
    required this.category,
    required this.amountLimit,
    this.currentAmount = 0.0,
    required this.monthYear,
    this.icon,
    this.color,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount_limit': amountLimit,
      'current_amount': currentAmount,
      'month_year': monthYear,
      'icon': icon,
      'color': color,
    };
  }
  
  factory Budget.fromMap(Map<String, dynamic> map) {
    try {
      return Budget(
        id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
        category: map['category']?.toString() ?? 'Unknown',
        amountLimit: (map['amount_limit'] is num) 
            ? (map['amount_limit'] as num).toDouble() 
            : double.tryParse(map['amount_limit']?.toString() ?? '0') ?? 0.0,
        currentAmount: (map['current_amount'] is num) 
            ? (map['current_amount'] as num).toDouble() 
            : double.tryParse(map['current_amount']?.toString() ?? '0') ?? 0.0,
        monthYear: map['month_year']?.toString() ?? '2024-01',
        icon: map['icon']?.toString(),
        color: map['color']?.toString(),
      );
    } catch (e) {
      print('[BUDGET MODEL ERROR] Failed to parse budget: $e');
      print('[BUDGET MODEL ERROR] Raw data: $map');
      
      return Budget(
        id: 0,
        category: 'Error',
        amountLimit: 0.0,
        currentAmount: 0.0,
        monthYear: '2024-01',
        icon: '⚠️',
        color: '#FF0000',
      );
    }
  }
  
  double get remainingAmount => amountLimit - currentAmount;
  double get percentageUsed => amountLimit > 0 ? (currentAmount / amountLimit) * 100 : 0;
  
  String get formattedLimit {
    try {
      final formatter = NumberFormat.currency(
        symbol: AppStrings.currencySymbol,
        decimalDigits: 0,
      );
      return formatter.format(amountLimit);
    } catch (e) {
      print('[BUDGET MODEL] Error formatting limit: $e');
      return '${AppStrings.currencySymbol} 0';
    }
  }
  
  String get formattedCurrent {
    try {
      final formatter = NumberFormat.currency(
        symbol: AppStrings.currencySymbol,
        decimalDigits: 0,
      );
      return formatter.format(currentAmount);
    } catch (e) {
      print('[BUDGET MODEL] Error formatting current: $e');
      return '${AppStrings.currencySymbol} 0';
    }
  }
  
  String get formattedRemaining {
    try {
      final formatter = NumberFormat.currency(
        symbol: AppStrings.currencySymbol,
        decimalDigits: 0,
      );
      return formatter.format(remainingAmount);
    } catch (e) {
      print('[BUDGET MODEL] Error formatting remaining: $e');
      return '${AppStrings.currencySymbol} 0';
    }
  }
  
  Color get statusColor {
    if (percentageUsed >= 90) return AppColors.error;
    if (percentageUsed >= 75) return AppColors.warning;
    return AppColors.success;
  }
  
  String get monthName {
    try {
      final parts = monthYear.split('-');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year != null && month != null && month >= 1 && month <= 12) {
          return DateFormat('MMMM yyyy').format(DateTime(year, month));
        }
      }
      return monthYear;
    } catch (e) {
      print('[BUDGET MODEL] Error parsing month name: $e');
      return monthYear;
    }
  }
}