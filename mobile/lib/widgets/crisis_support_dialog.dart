import 'package:flutter/material.dart';
import '../services/crisis_service.dart';
import '../theme/app_colors.dart';

class CrisisSupportDialog extends StatelessWidget {
  final CrisisDetectionResult crisisResult;

  const CrisisSupportDialog({super.key, required this.crisisResult});

  static Future<void> show(BuildContext context, CrisisDetectionResult result) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CrisisSupportDialog(crisisResult: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      title: Row(
        children: [
          const Icon(Icons.emergency_outlined, color: Color(0xFFEF4444), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              crisisResult.isMedicalEmergency
                  ? 'Medical Safety Notice'
                  : 'Crisis Support & Safety',
              style: TextStyle(
                color: textPrim,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              crisisResult.safetyMessage,
              style: TextStyle(
                color: textSec,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Immediate 24/7 Helplines & Resources:',
              style: TextStyle(
                color: textPrim,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...crisisResult.resources.map((res) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            res.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrim,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            res.contact,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      res.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSec,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Clarity is a smoking behavior coach and is not a medical professional, clinical hospital, or crisis center.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: textSec.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'I Understand',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.sagePrimary,
            ),
          ),
        ),
      ],
    );
  }
}
