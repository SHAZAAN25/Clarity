import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class GoalCard extends StatelessWidget {
  final int smoked;
  final int target;
  final int avoided;
  final VoidCallback? onLogCigarette;
  final VoidCallback? onCraving;

  const GoalCard({
    super.key,
    required this.smoked,
    required this.target,
    required this.avoided,
    this.onLogCigarette,
    this.onCraving,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final elevatedBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;

    final isExceeded = smoked > target;
    final diff = (target - smoked).abs();
    final statusText = isExceeded
        ? '$diff above target'
        : (smoked == target ? 'At target' : '$diff below target');

    final progressRatio = target > 0 ? (smoked / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExceeded ? AppColors.rose.withValues(alpha: 0.5) : borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODAY',
                style: AppTypography.labelUppercase.copyWith(
                  color: textMut,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isExceeded
                      ? AppColors.rose.withValues(alpha: 0.12)
                      : (isDark ? AppColors.sageSubtle : const Color(0xFFECFDF5)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isExceeded ? AppColors.rose : accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$smoked',
                style: AppTypography.displayLarge.copyWith(
                  color: isExceeded ? AppColors.rose : textPrim,
                  fontSize: 52,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'cigarettes',
                style: AppTypography.titleMedium.copyWith(
                  color: textSec,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Target $target · $statusText',
            style: AppTypography.bodySmall.copyWith(
              color: textMut,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          // Clean progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: progressRatio,
                backgroundColor: elevatedBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExceeded ? AppColors.rose : (isDark ? AppColors.sagePrimary : AppColors.sageDark),
                ),
              ),
            ),
          ),
          if (avoided > 0) ...[
            const SizedBox(height: 12),
            Text(
              'You have avoided $avoided ${avoided == 1 ? 'cigarette' : 'cigarettes'} today.',
              style: TextStyle(
                fontSize: 13,
                color: accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
