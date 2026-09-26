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
    final strokeW = size.width * 0.11;

    // 1. Lower-Left Arc: The habit loop gently releasing (curving from bottom up to middle-left)
    final arcPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final arcPath = Path();
    arcPath.addArc(
      Rect.fromLTWH(strokeW, strokeW, size.width - 2 * strokeW, size.height - 2 * strokeW),
      math.pi * 0.45, // starts at bottom
      math.pi * 0.95, // sweeps smoothly around to mid-left
    );
    canvas.drawPath(arcPath, arcPaint);

    // 2. Upper-Right Ascending Curve: Transformation & mindful clarity releasing into open space
    final releasePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final releasePath = Path();
    // Smooth bezier curve separating upward and outward
    releasePath.moveTo(size.width * 0.45, size.height * 0.52);
    releasePath.cubicTo(
      size.width * 0.52, size.height * 0.35,
      size.width * 0.65, size.height * 0.20,
      size.width * 0.88, size.height * 0.16,
    );
    canvas.drawPath(releasePath, releasePaint);

    // 3. Subtle harmonic accent dot at the point of release (spacious clarity)
    final dotPaint = Paint()
      ..color = secondaryColor.withValues(alpha: isDark ? 0.9 : 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.28), strokeW * 0.5, dotPaint);
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
