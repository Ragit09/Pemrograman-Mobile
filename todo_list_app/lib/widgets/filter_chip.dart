import 'package:flutter/material.dart';

enum TodoFilter { all, completed, pending }

class FilterChipWidget extends StatelessWidget {
  final TodoFilter currentFilter;
  final ValueChanged<TodoFilter> onFilterChanged;

  const FilterChipWidget({
    Key? key,
    required this.currentFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFilterChip(
            label: 'Semua',
            isSelected: currentFilter == TodoFilter.all,
            onSelected: () => onFilterChanged(TodoFilter.all),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Selesai',
            isSelected: currentFilter == TodoFilter.completed,
            onSelected: () => onFilterChanged(TodoFilter.completed),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Belum Selesai',
            isSelected: currentFilter == TodoFilter.pending,
            onSelected: () => onFilterChanged(TodoFilter.pending),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          onSelected();
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[200],
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}