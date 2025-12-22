import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;
  final bool useDarkColors;
  
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 24.0,
    this.useDarkColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorMap = useDarkColors || isDark 
        ? AppConstants.categoryColorsDark 
        : AppConstants.categoryColors;
    
    return Icon(
      AppConstants.categoryIcons[category] ?? Icons.category,
      color: colorMap[category] ?? Colors.grey,
      size: size,
    );
  }
}