import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TriggerChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;

  const TriggerChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedBg = isDark
        ? AppColors.sagePrimary.withValues(alpha: 0.15)
        : AppColors.sageSubtle;
    final selectedBorder = isDark ? AppColors.sagePrimary : AppColors.sageDark;
    final selectedText = isDark ? AppColors.sageLight : AppColors.sageDark;

    final unselectedBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final unselectedBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final unselectedText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected != null ? () => onSelected!(!isSelected) : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? selectedBorder : unselectedBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? selectedText : unselectedText,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedText : unselectedText,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
