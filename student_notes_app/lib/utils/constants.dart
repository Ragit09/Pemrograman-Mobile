import 'package:flutter/material.dart';

class AppConstants {
  // Daftar kategori
  static const List<String> categories = [
    'Kuliah',
    'Organisasi',
    'Pribadi',
    'Lain-lain'
  ];

  // Ikon untuk setiap kategori
  static Map<String, IconData> get categoryIcons {
    return {
      'Kuliah': Icons.school,
      'Organisasi': Icons.groups,
      'Pribadi': Icons.person,
      'Lain-lain': Icons.category,
    };
  }

  // Warna untuk setiap kategori
  static Map<String, Color> get categoryColors {
    return {
      'Kuliah': Colors.blue,
      'Organisasi': Colors.green,
      'Pribadi': Colors.orange,
      'Lain-lain': Colors.purple,
    };
  }

  // Warna untuk dark mode
  static Map<String, Color> get categoryColorsDark {
    return {
      'Kuliah': Colors.blueAccent,
      'Organisasi': Colors.greenAccent,
      'Pribadi': Colors.orangeAccent,
      'Lain-lain': Colors.purpleAccent,
    };
  }

  // Format tanggal
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Format tanggal dengan waktu
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}