import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CravingIntensitySelector extends StatelessWidget {
  final int intensity;
  final ValueChanged<int> onChanged;

  const CravingIntensitySelector({
    super.key,
    required this.intensity,
    required this.onChanged,
  });

  String _getIntensityLabel(int value) {
    if (value <= 3) return 'Mild';
    if (value <= 6) return 'Moderate';
    if (value <= 8) return 'Strong';
    return 'Severe';
  }

  Color _getIntensityColor(int value) {
    if (value <= 3) return AppColors.sagePrimary;
    if (value <= 6) return AppColors.amber;
    return AppColors.rose;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final currentColor = _getIntensityColor(intensity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CRAVING INTENSITY',
              style: AppTypography.labelUppercase.copyWith(
                color: textMut,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$intensity/10 (${_getIntensityLabel(intensity)})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: currentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: currentColor,
            thumbColor: currentColor,
            overlayColor: currentColor.withValues(alpha: 0.15),
            trackHeight: 4,
          ),
          child: Slider(
            value: intensity.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (val) => onChanged(val.round()),
          ),
        ),
      ],
    );
  }
}
