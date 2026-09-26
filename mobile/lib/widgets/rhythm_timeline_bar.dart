import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class RhythmTimelineBar extends StatelessWidget {
  final Map<int, int> rhythmMap; // Hour -> Count
  final VoidCallback? onTap;

  const RhythmTimelineBar({
    super.key,
    required this.rhythmMap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hours = [8, 10, 12, 14, 16, 18, 20, 22];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TODAY\'S SMOKING RHYTHM',
                  style: AppTypography.labelUppercase.copyWith(fontSize: 10),
                ),
                Text(
                  'Tap for details',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.sageLight),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: hours.map((hour) {
                final count = rhythmMap[hour] ?? 0;
                final label = hour == 12
                    ? '12P'
                    : hour > 12
                        ? '${hour - 12}P'
                        : '${hour}A';

                return Column(
                  children: [
                    Container(
                      height: 48,
                      width: 28,
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(count.clamp(0, 3), (index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 3),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.rose,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: count > 0 ? AppColors.textPrimary : AppColors.textMuted,
                        fontWeight: count > 0 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
