import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Minimal geometric symbol representing Clarity:
/// An interrupted habit loop opening smoothly into clear, unbounded space,
/// symbolizing conscious control, transformation, and freedom from automatic cravings.
class ClarityLogoMark extends StatelessWidget {
  final double size;
  final Color? color;
  final bool isDark;

  const ClarityLogoMark({
    super.key,
    this.size = 48,
    this.color,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ClarityLogoPainter(
          primaryColor: color ?? (isDark ? AppColors.sageLight : AppColors.sagePrimary),
          secondaryColor: isDark ? AppColors.sagePrimary : AppColors.sageDark,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _ClarityLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _ClarityLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Primary Outer Broken Loop: An arc breaking open at top-right (from 75 deg to 360 deg)
    // Symbolizing the conscious interruption of an automatic circular loop
    final loopPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    // Arc from 75 degrees around to 345 degrees (leaving a clean 90-degree opening at the top-right)
    const startAngle = 0.55; // ~31 degrees
    const sweepAngle = 2 * math.pi - 1.25; // Opens at top-right
    final loopRect = Rect.fromCircle(center: center, radius: radius * 0.78);
    canvas.drawArc(loopRect, startAngle, sweepAngle, false, loopPaint);

    // 2. Ascending Clarity Pathway: A calm diagonal vector leading out through the opening into clear space
    final pathPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final p1 = Offset(center.dx - radius * 0.28, center.dy + radius * 0.28);
    final p2 = Offset(center.dx + radius * 0.52, center.dy - radius * 0.52);
    canvas.drawLine(p1, p2, pathPaint);

    // 3. Center Mindful Focus Anchor: A small luminous pebble at the center
    final corePaint = Paint()
      ..color = isDark ? const Color(0xFFD8F3DC) : AppColors.sageDark
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.16, corePaint);
  }

  @override
  bool shouldRepaint(covariant _ClarityLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}

/// Full Clarity Brand Header (Mark + Wordmark + Tagline)
class ClarityBrandHeader extends StatelessWidget {
  final double markSize;
  final bool showTagline;

  const ClarityBrandHeader({
    super.key,
    this.markSize = 40,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClarityLogoMark(size: markSize, isDark: isDark),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CLARITY',
              style: TextStyle(
                fontSize: markSize * 0.48,
                fontWeight: FontWeight.w700,
                letterSpacing: 3.5,
                color: textPrim,
              ),
            ),
            if (showTagline) ...[
              const SizedBox(height: 2),
              Text(
                'Understand · Control · Change',
                style: TextStyle(
                  fontSize: markSize * 0.22,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  color: textMut,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
