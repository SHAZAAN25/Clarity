import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/section_header.dart';

class HealthLibraryScreen extends StatelessWidget {
  const HealthLibraryScreen({super.key});

  void _openArticleDetail(BuildContext context, Map<String, String> article) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                article['category']!.toUpperCase(),
                style: AppTypography.labelUppercase.copyWith(
                  color: textMut,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                article['title']!,
                style: AppTypography.titleLarge.copyWith(
                  color: textPrim,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Source: ${article['source']}',
                    style: TextStyle(fontSize: 12, color: textMut),
                  ),
                  const SizedBox(width: 8),
                  Text('·', style: TextStyle(color: textMut)),
                  const SizedBox(width: 8),
                  Text(
                    'Updated: ${article['updated']}',
                    style: TextStyle(fontSize: 12, color: textMut),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                article['content']!,
                style: AppTypography.bodyMedium.copyWith(
                  color: textSec,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

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

    final hours = appState.hoursSinceLastSmoke;
    final moneySaved = appState.totalMoneySaved;
    final milestones = appState.healthMilestones;

    final articles = [
      {
        'category': 'Neurobiology',
        'title': 'The 10-Minute Craving Curve',
        'summary':
            'Nicotine craving intensity peaks within 3 to 5 minutes, then steadily declines as acetylcholine receptors reset.',
        'content':
            'When you experience a sudden urge to smoke, your autonomic nervous system is responding to a learned associative cue. Cravings do not build indefinitely—they follow a bell curve, peaking sharply between 3 and 5 minutes before the prefrontal cortex regains inhibitory control. By postponing action by just 10 minutes, you allow physiological arousal to dissipate naturally.',
        'source': 'World Health Organization',
        'updated': '2026',
      },
      {
        'category': 'Cardiovascular',
        'title': 'Carbon Monoxide Clearance in 8 Hours',
        'summary':
            'Within eight hours without smoke, blood carbon monoxide levels drop by half, restoring cellular oxygen transport.',
        'content':
            'Inhaled tobacco smoke binds hemoglobin with 200 times the affinity of oxygen, reducing total oxygen delivery to muscle and brain tissues. Within eight hours of your last cigarette, carbon monoxide levels halve, and arterial oxygen saturation begins climbing back to baseline non-smoking levels.',
        'source': 'American Heart Association',
        'updated': '2026',
      },
      {
        'category': 'Behavioral Science',
        'title': 'Habit Loops vs. Physical Addiction',
        'summary':
            'Over 70% of smoking episodes are automated responses to context rather than acute chemical withdrawal.',
        'content':
            'Habits consist of a cue, a routine, and a reward. Often the cigarette is simply a marker for taking a break, pausing after a meal, or signaling the end of a work sprint. Disentangling the craving from the routine allows you to retain the restorative break without the smoke.',
        'source': 'National Institute on Drug Abuse',
        'updated': '2025',
      },
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learn',
                style: AppTypography.titleLarge.copyWith(
                  color: textPrim,
                  fontWeight: FontWeight.w600,
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),

              // Recovery Interval Card
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
                    Text(
                      'SMOKE-FREE INTERVAL',
                      style: AppTypography.labelUppercase.copyWith(
                        color: textMut,
                        fontSize: 10,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          appState.smokingLogs.isEmpty
                              ? '—'
                              : (hours < 1.0 ? '${(hours * 60).round()}' : hours.toStringAsFixed(1)),
                          style: AppTypography.displayLarge.copyWith(
                            color: textPrim,
                            fontSize: 44,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          appState.smokingLogs.isEmpty
                              ? 'no logs recorded'
                              : (hours < 1.0 ? 'minutes' : 'hours'),
                          style: TextStyle(fontSize: 16, color: textSec),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONEY SAVED',
                              style: AppTypography.labelUppercase.copyWith(
                                color: textMut,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${moneySaved.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEXT RECOVERY STAGE',
                              style: AppTypography.labelUppercase.copyWith(
                                color: textMut,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hours < 8 ? '8 Hours' : (hours < 24 ? '24 Hours' : (hours < 48 ? '48 Hours' : '72 Hours')),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrim,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Recovery Timeline Milestones
              SectionHeader(
                title: 'Physiological Milestones',
                subtitle: 'Evidence-based recovery timeline (WHO / CDC / AHA)',
              ),
              ...milestones.map((m) {
                final isReached = m.isUnlocked;
                final progress = m.progress.clamp(0.0, 1.0);

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isReached ? accent.withValues(alpha: 0.35) : border,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            m.timeframe,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isReached ? accent : textSec,
                            ),
                          ),
                          Text(
                            isReached ? 'Achieved' : '${(progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isReached ? accent : textMut,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrim,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: textSec,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          height: 3,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: elevatedBg,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isReached ? accent : textMut,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Editorial Health Content (Section 28)
              SectionHeader(
                title: 'Articles & Evidence',
                subtitle: 'Peer-reviewed behavioral research',
              ),
              ...articles.map((art) {
                return GestureDetector(
                  onTap: () => _openArticleDetail(context, art),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          art['category']!.toUpperCase(),
                          style: AppTypography.labelUppercase.copyWith(
                            color: textMut,
                            fontSize: 10,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          art['title']!,
                          style: AppTypography.titleSmall.copyWith(
                            color: textPrim,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          art['summary']!,
                          style: AppTypography.bodySmall.copyWith(
                            color: textSec,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Source: ${art['source']}',
                              style: TextStyle(fontSize: 11, color: textMut),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Text(
                                  'Read',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 12, color: accent),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
