import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Note {
  String id;
  String title;
  String description;
  String category;
  DateTime createdDate;
  DateTime? updatedDate;

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdDate,
    this.updatedDate,
  });

  IconData get categoryIcon {
    switch (category) {
      case 'Kuliah':
        return Icons.school;
      case 'Organisasi':
        return Icons.groups;
      case 'Pribadi':
        return Icons.person;
      case 'Lain-lain':
        return Icons.category;
      default:
        return Icons.note;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'Kuliah':
        return const Color(0xFF4CAF50);
      case 'Organisasi':
        return const Color(0xFF2196F3);
      case 'Pribadi':
        return const Color(0xFFFF9800);
      case 'Lain-lain':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy • HH:mm').format(createdDate);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate?.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Lain-lain',
      createdDate: DateTime.parse(map['createdDate'] ?? DateTime.now().toIso8601String()),
      updatedDate: map['updatedDate'] != null ? DateTime.parse(map['updatedDate']) : null,
    );
  }
}