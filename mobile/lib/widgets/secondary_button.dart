import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = Colors.transparent,
    this.borderColor = AppColors.cardBorder,
    this.textColor = AppColors.textPrimary,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedBorder = borderColor == AppColors.cardBorder
        ? (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder)
        : borderColor;
    final resolvedText = textColor == AppColors.textPrimary
        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
        : textColor;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: resolvedText,
          side: BorderSide(color: resolvedBorder, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: resolvedText),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: resolvedText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

