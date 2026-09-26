import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/pattern_timeline.dart';
import '../widgets/progress_chart.dart';
import '../widgets/insight_card.dart';
import '../widgets/section_header.dart';
import 'craving_intervention_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final elevatedBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;

    final rhythm = appState.hourlyRhythm;
    final triggers = appState.triggerBreakdown;
    final totalTriggers = triggers.values.fold<int>(0, (a, b) => a + b);

    // Calculate this week average and baseline
    final baseline = appState.profile.cigarettesPerDay;
    final target = appState.todayTargetCount;
    final weekAvg = appState.weeklyAverageCpd;
    final patterns = appState.patternInsights;

    // 7-day progress data
    final now = DateTime.now();
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekProgress = List.generate(7, (index) {
      final d = now.subtract(Duration(days: 6 - index));
      final isToday = index == 6;
      final count = isToday
          ? appState.todaySmokedCount
          : appState.smokingLogs.where((l) {
              return l.timestamp.year == d.year &&
                  l.timestamp.month == d.month &&
                  l.timestamp.day == d.day;
            }).length;
      return DayProgressData(
        dayLabel: daysOfWeek[d.weekday - 1],
        count: count,
        isToday: isToday,
      );
    });

    final hasLogs = appState.smokingLogs.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title
              Text(
                'Your progress',
                style: AppTypography.titleLarge.copyWith(
                  color: textPrim,
                  fontWeight: FontWeight.w600,
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),

              // This Week Metric Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                          'THIS WEEK',
                          style: AppTypography.labelUppercase.copyWith(
                            color: textMut,
                            fontSize: 10,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          baseline > 0 ? 'Baseline: $baseline/day' : 'Baseline: —',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMut,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          weekAvg != null ? weekAvg.toStringAsFixed(1) : '—',
                          style: AppTypography.displayLarge.copyWith(
                            color: textPrim,
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '/ day',
                          style: TextStyle(fontSize: 16, color: textSec),
                        ),
                      ],
                    ),
                    if (weekAvg == null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Keep logging to reveal your weekly average.',
                        style: TextStyle(fontSize: 12, color: textMut),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Weekly Chart
                    ProgressChart(
                      days: weekProgress,
                      target: target,
                      height: 130,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Behavioral Insights / Patterns (Real Observed Data Only)
              SectionHeader(title: 'Observed Patterns'),
              if (patterns.isNotEmpty) ...[
                ...patterns.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InsightCard(
                        category: p.category.toUpperCase(),
                        headline: p.title,
                        explanation: '${p.message} ${p.actionableAdvice ?? ''}',
                        actionLabel: 'Delay craving',
                        onAction: () => CravingInterventionScreen.open(context),
                      ),
                    )),
              ] else ...[
                Container(
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
                        children: [
                          Icon(Icons.query_stats_outlined, size: 18, color: accent),
                          const SizedBox(width: 8),
                          Text(
                            "We're still learning your pattern",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrim,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'As you log cigarettes and delay sessions over the coming days, Clarity will uncover your high-risk triggers, peak hours, and delay resilience.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSec,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Smoking Rhythm (24-hour distribution from real logs)
              SectionHeader(
                title: 'Smoking Rhythm',
                subtitle: '24-hour cigarette distribution',
              ),
              if (hasLogs) ...[
                PatternTimeline(
                  rhythmMap: rhythm,
                  peakWindow: appState.patternInsights.isNotEmpty
                      ? appState.patternInsights.first.title
                      : 'Observed timeline',
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    'No cigarettes logged yet today. Rhythm timeline will plot your hourly distribution.',
                    style: TextStyle(fontSize: 13, color: textMut),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Your Triggers
              SectionHeader(title: 'Your triggers'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.0),
                ),
                child: totalTriggers == 0
                    ? Text(
                        'Trigger breakdown will appear as you log cigarettes.',
                        style: TextStyle(fontSize: 13, color: textMut),
                      )
                    : Column(
                        children: triggers.entries.take(5).map((entry) {
                          final pct = totalTriggers > 0
                              ? ((entry.value / totalTriggers) * 100).round()
                              : 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: textPrim,
                                      ),
                                    ),
                                    Text(
                                      '$pct%',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textSec,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: SizedBox(
                                    height: 4,
                                    child: LinearProgressIndicator(
                                      value: pct / 100.0,
                                      backgroundColor: elevatedBg,
                                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
