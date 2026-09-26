import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class DayProgressData {
  final String dayLabel;
  final int count;
  final bool isToday;

  const DayProgressData({
    required this.dayLabel,
    required this.count,
    this.isToday = false,
  });
}

class ProgressChart extends StatelessWidget {
  final List<DayProgressData> days;
  final int target;
  final double height;

  const ProgressChart({
    super.key,
    required this.days,
    required this.target,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final elevatedBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;

    final maxVal = max(target + 3, days.fold<int>(0, (prev, d) => max(prev, d.count)));
    final safeMax = max(1, maxVal);

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) {
                final heightFraction = (day.count / safeMax).clamp(0.06, 1.0);
                final isExceeded = day.count > target;
                final barColor = day.isToday
                    ? (isExceeded ? AppColors.rose : accent)
                    : (isExceeded
                        ? AppColors.rose.withValues(alpha: 0.5)
                        : (day.count == 0 ? elevatedBg : textMut.withValues(alpha: 0.35)));

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (day.count > 0)
                          Text(
                            '${day.count}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
                              color: day.isToday ? (isExceeded ? AppColors.rose : accent) : textSec,
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                        const SizedBox(height: 4),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: heightFraction,
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 24),
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day.dayLabel,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w400,
                            color: day.isToday ? accent : textMut,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target: $target/day',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textMut,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Within target',
                    style: TextStyle(fontSize: 11, color: textMut),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
