import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/section_header.dart';
import '../widgets/pattern_timeline.dart';

class PatternsScreen extends StatelessWidget {
  const PatternsScreen({super.key});

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
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;

    final patterns = appState.patternInsights;
    final rhythm = appState.hourlyRhythm;
    final triggers = appState.triggerBreakdown;
    final strategyRankings = appState.strategyRankings;
    final totalLogs = appState.smokingLogs.length + appState.cravingLogs.length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patterns',
                style: AppTypography.titleLarge.copyWith(
                  color: textPrim,
                  fontWeight: FontWeight.w600,
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your behavioral smoking model inferred from real logs.',
                style: TextStyle(fontSize: 13, color: textMut),
              ),
              const SizedBox(height: 20),

              // 1. Your Smoking Rhythm
              SectionHeader(
                title: 'Your Smoking Rhythm',
                subtitle: '24-hour distribution of cigarettes',
              ),
              PatternTimeline(rhythmMap: rhythm),
              const SizedBox(height: 24),

              // 2. High-Risk Times
              SectionHeader(
                title: 'High-Risk Times',
                subtitle: 'Windows with repeated urge clustering',
              ),
              _buildHighRiskCard(appState, cardBg, border, textPrim, textSec, textMut, accent),
              const SizedBox(height: 24),

              // 3. Common Triggers
              SectionHeader(
                title: 'Common Triggers',
                subtitle: 'Environmental & emotional associations',
              ),
              _buildTriggersCard(triggers, cardBg, border, textPrim, textSec, textMut, accent),
              const SizedBox(height: 24),

              // 4. What Helps You (Strategy Library)
              SectionHeader(
                title: 'What Helps You',
                subtitle: 'Delay & intervention effectiveness from your history',
              ),
              _buildWhatWorksCard(strategyRankings, cardBg, border, textPrim, textSec, textMut, accent),
              const SizedBox(height: 24),

              // 5. Emerging Patterns / Insufficient Data State
              SectionHeader(
                title: 'Emerging Patterns',
                subtitle: 'Evolving behavioral habits',
              ),
              if (patterns.isNotEmpty) ...[
                ...patterns.map((p) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.category.toUpperCase(),
                          style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrim),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.message,
                          style: TextStyle(fontSize: 13, color: textSec, height: 1.4),
                        ),
                        if (p.actionableAdvice != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            p.actionableAdvice!,
                            style: TextStyle(fontSize: 12, color: accent, height: 1.35),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border, width: 1.0),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.insights_outlined, size: 28, color: accent),
                      const SizedBox(height: 10),
                      Text(
                        "We're still learning your pattern.",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrim),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total logged events: $totalLogs / 4 needed for initial behavioral cluster detection. As you log honestly, precise correlations will emerge here.',
                        style: TextStyle(fontSize: 12, color: textMut, height: 1.45),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighRiskCard(
    AppState appState,
    Color cardBg,
    Color border,
    Color textPrim,
    Color textSec,
    Color textMut,
    Color accent,
  ) {
    final smoking = appState.smokingLogs;
    if (smoking.length < 3) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Text(
          "We're still learning your pattern. High-risk time windows will be identified as you log throughout your day.",
          style: TextStyle(fontSize: 12, color: textMut, height: 1.4),
        ),
      );
    }

    final topHour = appState.hourlyRhythm.entries.reduce((a, b) => a.value > b.value ? a : b);
    final periodStart = '${topHour.key % 12 == 0 ? 12 : topHour.key % 12}:00 ${topHour.key >= 12 ? 'PM' : 'AM'}';
    final endHour = (topHour.key + 2) % 24;
    final periodEnd = '${endHour % 12 == 0 ? 12 : endHour % 12}:00 ${endHour >= 12 ? 'PM' : 'AM'}';

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
                '$periodStart – $periodEnd',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrim),
              ),
              Text(
                'Highest density',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.amber),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${topHour.value} cigarettes logged in this time band today. Planning a 5-minute break with water or walking 15 minutes before this window reduces automatic reach.',
            style: TextStyle(fontSize: 12, color: textSec, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggersCard(
    Map<String, int> triggers,
    Color cardBg,
    Color border,
    Color textPrim,
    Color textSec,
    Color textMut,
    Color accent,
  ) {
    if (triggers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Text(
          "We're still learning your pattern. When logging a cigarette, select the prompt (Stress, Coffee, Meal) to map your triggers.",
          style: TextStyle(fontSize: 12, color: textMut, height: 1.4),
        ),
      );
    }

    final sortedEntries = triggers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = triggers.values.fold<int>(0, (a, b) => a + b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Column(
        children: sortedEntries.take(4).map((entry) {
          final pct = total > 0 ? (entry.value / total) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrim)),
                    Text('${(pct * 100).round()}% (${entry.value})', style: TextStyle(fontSize: 12, color: textMut)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: border,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWhatWorksCard(
    List<dynamic> strategyRankings,
    Color cardBg,
    Color border,
    Color textPrim,
    Color textSec,
    Color textMut,
    Color accent,
  ) {
    if (strategyRankings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Text(
          "We're still learning your pattern. As you try conscious delay, breathing, or water during cravings, Clarity will measure which strategy gives you the highest success rate.",
          style: TextStyle(fontSize: 12, color: textMut, height: 1.4),
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
        children: strategyRankings.map((s) {
          final pct = ((s.successRate as double) * 100).round();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.strategyName as String,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrim),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.successfulDelays} of ${s.totalAttempts} cravings delayed/overcome',
                        style: TextStyle(fontSize: 11, color: textMut),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$pct%',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: accent),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
