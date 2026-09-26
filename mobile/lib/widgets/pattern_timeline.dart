import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PatternTimeline extends StatelessWidget {
  final Map<int, int> rhythmMap; // Hour (0-23) -> Count
  final String? peakWindow;
  final VoidCallback? onTap;

  const PatternTimeline({
    super.key,
    required this.rhythmMap,
    this.peakWindow = '7:30 PM – 10:00 PM',
    this.onTap,
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

    // Timeline milestone hours as specified in Section 22:
    // 07:00, 09:00, 11:00, 13:00, 15:00, 17:00, 19:00, 21:00, 23:00
    final hours = [7, 9, 11, 13, 15, 17, 19, 21, 23];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SMOKING RHYTHM',
                    style: AppTypography.labelUppercase.copyWith(
                      color: textMut,
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (peakWindow != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Peak: $peakWindow',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Timeline bar
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: hours.map((hour) {
                  final count = (rhythmMap[hour] ?? 0) + (rhythmMap[hour + 1] ?? 0);
                  final isEveningPeak = hour >= 19 && hour <= 22;
                  final label = '${hour.toString().padLeft(2, '0')}:00';

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Cigarette subtle markers
                        Container(
                          height: 52,
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: count == 0
                                ? [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: elevatedBg,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ]
                                : List.generate(count.clamp(1, 4), (index) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 3),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isEveningPeak ? AppColors.amber : textSec,
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: count > 0 ? FontWeight.w600 : FontWeight.w400,
                            color: count > 0 ? textPrim : textMut,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Cigarettes logged throughout the 24-hour cycle. Notice density patterns to anticipate conscious delays.',
                style: AppTypography.bodySmall.copyWith(
                  color: textMut,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
