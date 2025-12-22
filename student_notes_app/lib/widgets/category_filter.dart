import 'package:flutter/material.dart';
import '../utils/constants.dart';
import './category_icon.dart';

class CategoryFilter extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;
  
  const CategoryFilter({
    super.key,
    this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          hint: Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filter Kategori',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Row(
                children: [
                  const Icon(Icons.all_inclusive, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Semua Kategori',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            ...AppConstants.categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Row(
                  children: [
                    CategoryIcon(category: category, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}