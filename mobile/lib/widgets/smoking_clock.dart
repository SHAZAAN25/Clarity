import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/smoking_log.dart';
import '../models/craving_log.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TimelineEvent {
  final DateTime timestamp;
  final String title;
  final String type; // 'smoke', 'craving', 'delay'
  final String? subtitle;
  final IconData icon;
  final Color color;

  const TimelineEvent({
    required this.timestamp,
    required this.title,
    required this.type,
    this.subtitle,
    required this.icon,
    required this.color,
  });
}

class SmokingClock extends StatelessWidget {
  final List<SmokingLog> smokingLogs;
  final List<CravingLog> cravingLogs;

  const SmokingClock({
    super.key,
    required this.smokingLogs,
    required this.cravingLogs,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;

    // Filter events for today only
    final now = DateTime.now();
    final events = <TimelineEvent>[];

    for (final s in smokingLogs) {
      if (s.timestamp.year == now.year &&
          s.timestamp.month == now.month &&
          s.timestamp.day == now.day) {
        events.add(
          TimelineEvent(
            timestamp: s.timestamp,
            title: 'Cigarette',
            type: 'smoke',
            subtitle: s.trigger != null ? 'Trigger: ${s.trigger}' : null,
            icon: Icons.smoking_rooms_outlined,
            color: isDark ? const Color(0xFFE2847A) : const Color(0xFFDC2626),
          ),
        );
      }
    }

    for (final c in cravingLogs) {
      if (c.timestamp.year == now.year &&
          c.timestamp.month == now.month &&
          c.timestamp.day == now.day) {
        if (c.delayedMinutesCompleted > 0) {
          events.add(
            TimelineEvent(
              timestamp: c.timestamp.add(Duration(minutes: c.delayedMinutesCompleted)),
              title: 'Delayed (${c.delayedMinutesCompleted}m)',
              type: 'delay',
              subtitle: 'Overcame craving: ${c.trigger}',
              icon: Icons.check_circle_outline,
              color: accent,
            ),
          );
        } else {
          events.add(
            TimelineEvent(
              timestamp: c.timestamp,
              title: 'Craving (${c.intensity}/10)',
              type: 'craving',
              subtitle: 'Trigger: ${c.trigger}',
              icon: Icons.hourglass_top_outlined,
              color: AppColors.amber,
            ),
          );
        }
      }
    }

    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Column(
          children: [
            Icon(Icons.access_time, size: 28, color: textMut),
            const SizedBox(height: 8),
            Text(
              'No logs yet today',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrim),
            ),
            const SizedBox(height: 4),
            Text(
              'Your chronological rhythm of cigarettes, cravings, and delays will appear here.',
              style: TextStyle(fontSize: 12, color: textMut, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODAY’S RHYTHM TIMELINE',
                style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10),
              ),
              Text(
                '${events.length} events',
                style: TextStyle(fontSize: 11, color: textMut),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...events.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final timeStr = DateFormat('h:mm a').format(e.timestamp);
            final isLast = idx == events.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time
                  SizedBox(
                    width: 62,
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textMut,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  // Timeline dot & connector line
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: e.color,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrim,
                            ),
                          ),
                          if (e.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              e.subtitle!,
                              style: TextStyle(fontSize: 11, color: textSec),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
