import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AIMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isEmergency;

  const AIMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final userBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final userText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final coachBg = isEmergency
        ? (isDark ? AppColors.rose.withValues(alpha: 0.15) : AppColors.roseSubtle)
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final coachBorder = isEmergency
        ? AppColors.rose
        : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);
    final coachText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isUser ? 'You' : 'Companion',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textMut,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  color: textMut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? userBg : coachBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUser ? userBorder : coachBorder,
                width: 1.0,
              ),
            ),
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: isUser ? userText : coachText,
                height: 1.45,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
