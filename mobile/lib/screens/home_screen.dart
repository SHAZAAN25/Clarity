import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/strategy_mode.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/goal_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/section_header.dart';
import '../widgets/smoking_clock.dart';
import 'quick_log_bottom_sheet.dart';
import 'craving_intervention_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToPatterns;
  final VoidCallback onNavigateToCoach;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToSettings;

  const HomeScreen({
    super.key,
    required this.onNavigateToPatterns,
    required this.onNavigateToCoach,
    required this.onNavigateToProfile,
    required this.onNavigateToSettings,
  });

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    String prefix;
    if (hour < 12) {
      prefix = 'Good morning';
    } else if (hour < 17) {
      prefix = 'Good afternoon';
    } else {
      prefix = 'Good evening';
    }

    if (name.isNotEmpty) {
      return '$prefix, $name';
    }
    return prefix;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final smoked = appState.todaySmokedCount;
    final target = appState.todayTargetCount;
    final avoided = appState.cigarettesAvoidedToday;
    final status = appState.todayStatus;
    final steadyStreak = appState.steadyStreak;

    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final money = appState.moneyStats;
    final patterns = appState.patternInsights;

    final isAboveTarget = status == DailyTargetStatus.aboveTarget || status == DailyTargetStatus.smoked;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header with Greeting, Steady Status, Profile and Settings buttons (Section 36 & 42)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(appState.profile.name),
                          style: AppTypography.titleLarge.copyWith(
                            color: textPrim,
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: AppTypography.bodySmall.copyWith(
                            color: textMut,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Steady badge (Section 33: Functional metric, not decorative)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isAboveTarget
                              ? (isDark ? const Color(0xFF332015) : const Color(0xFFFEF3C7))
                              : (isDark ? AppColors.sageSubtle : const Color(0xFFECFDF5)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAboveTarget
                                ? (isDark ? const Color(0xFFB45309).withValues(alpha: 0.4) : const Color(0xFFFDE68A))
                                : (isDark ? AppColors.sageLight.withValues(alpha: 0.3) : const Color(0xFFA7F3D0)),
                          ),
                        ),
                        child: Text(
                          isAboveTarget
                              ? 'Above Target'
                              : 'Steady · ${steadyStreak}d',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isAboveTarget ? const Color(0xFFD97706) : accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Profile Button (Section 42: Separate from Settings)
                      IconButton(
                        tooltip: 'Profile',
                        icon: Icon(Icons.person_outline, size: 22, color: textSec),
                        onPressed: onNavigateToProfile,
                      ),
                      // Settings Button
                      IconButton(
                        tooltip: 'Settings',
                        icon: Icon(Icons.settings_outlined, size: 20, color: textMut),
                        onPressed: onNavigateToSettings,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Main Hero Goal Card (Where am I today?)
              GoalCard(
                smoked: smoked,
                target: target,
                avoided: avoided,
              ),
              const SizedBox(height: 14),

              // 3. Key Metrics Row (Interval, Longest gap, INR Money retained)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT GAP',
                            style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 9),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.currentSmokingInterval,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LONGEST GAP',
                            style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 9),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.longestSmokeFreeGapToday,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RETAINED',
                            style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 9),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            money.formatInr(money.retainedToday),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4. Primary Actions (Quick log & Delay craving)
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'I SMOKED',
                      icon: Icons.add,
                      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      textColor: textPrim,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        QuickLogBottomSheet.show(context);
                      },
                      height: 50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: "I'M CRAVING",
                      icon: Icons.hourglass_top_outlined,
                      backgroundColor: AppColors.sagePrimary,
                      textColor: Colors.black,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        CravingInterventionScreen.open(context);
                      },
                      height: 50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // 5. Smoking Clock (Chronological rhythm of today)
              SectionHeader(
                title: 'Smoking Clock',
                subtitle: 'Today’s rhythm of cigarettes, cravings & delays',
              ),
              SmokingClock(
                smokingLogs: appState.smokingLogs,
                cravingLogs: appState.cravingLogs,
              ),
              const SizedBox(height: 26),

              // 6. Current Behavioral Insight (Real Observed Data Only)
              SectionHeader(
                title: 'Behavioral Insights',
                actionLabel: 'All patterns',
                onAction: onNavigateToPatterns,
              ),
              if (patterns.isNotEmpty) ...[
                InsightCard(
                  category: patterns.first.category.toUpperCase(),
                  headline: patterns.first.title,
                  explanation: '${patterns.first.message} ${patterns.first.actionableAdvice ?? ''}',
                  actionLabel: 'Discuss with Coach',
                  onAction: onNavigateToCoach,
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.query_stats_outlined, size: 18, color: accent),
                          const SizedBox(width: 8),
                          Text(
                            'Learning Your Pattern',
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
                        "We're still learning your pattern. As you log cigarettes and cravings over the next few days, Clarity will identify your high-risk times, primary triggers, and successful strategies.",
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
              const SizedBox(height: 26),

              // 7. Active Behavioral Experiment Card
              if (appState.experiments.isNotEmpty) ...[
                SectionHeader(
                  title: 'Active Experiment',
                  subtitle: 'Small behavioral adjustment',
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
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
                          Expanded(
                            child: Text(
                              appState.experiments.first.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrim,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Day ${appState.experiments.first.currentDay} of ${appState.experiments.first.durationDays}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        appState.experiments.first.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSec,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 8. Day Completion Tracking (Section 25: Explicit Day Completion)
              SectionHeader(
                title: 'Day Tracking Status',
                subtitle: 'Confirm completeness for target cycle evaluation',
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: appState.isTodayClosed
                        ? accent.withValues(alpha: 0.4)
                        : borderColor,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          appState.isTodayClosed
                              ? Icons.check_circle_outline
                              : Icons.schedule_outlined,
                          size: 20,
                          color: appState.isTodayClosed ? accent : textSec,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            appState.isTodayClosed
                                ? "Today's Tracking Completed"
                                : "Finish Today's Tracking",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrim,
                            ),
                          ),
                        ),
                        if (appState.isTodayClosed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'COMPLETE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appState.isTodayClosed
                          ? "You have marked today's logs as complete. This verified day counts toward your 7-day target evaluation cycle."
                          : "Done smoking for the day? Confirming completion marks this as a valid observation day for your adaptive target engine.",
                      style: TextStyle(
                        fontSize: 13,
                        color: textSec,
                        height: 1.45,
                      ),
                    ),
                    if (!appState.isTodayClosed) ...[
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: "I'm done logging for today",
                        backgroundColor: accent,
                        textColor: Colors.black,
                        height: 44,
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await appState.finishTodayTracking();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Today's tracking marked complete!"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
