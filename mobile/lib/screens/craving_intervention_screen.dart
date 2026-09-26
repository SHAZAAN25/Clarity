import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/trigger_chip.dart';
import '../services/smart_delay_engine.dart';

enum CravingStep {
  intensity,
  trigger,
  intervention,
  outcome,
  summary,
}

class CravingInterventionScreen extends StatefulWidget {
  const CravingInterventionScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CravingInterventionScreen()),
    );
  }

  @override
  State<CravingInterventionScreen> createState() => _CravingInterventionScreenState();
}

class _CravingInterventionScreenState extends State<CravingInterventionScreen>
    with SingleTickerProviderStateMixin {
  CravingStep _step = CravingStep.intensity;

  // Step 1: Craving Intensity (1-10)
  int _intensity = 6;

  // Step 2: Trigger
  String _selectedTrigger = 'Stress';
  final List<String> _triggers = [
    'Stress',
    'Boredom',
    'Habit',
    'Social',
    'Food',
    'Tea/coffee',
    'Alcohol',
    'Work',
    'Other',
  ];

  // Step 3: Personalized Intervention
  late int _delayMinutes;
  late int _remainingSeconds;
  Timer? _timer;
  String _selectedInterventionType = 'delay'; // 'delay', 'breathing', 'water', 'walk', 'coach'

  late AnimationController _breathingController;

  // Step 4: Outcome
  String _outcome = 'craving_passed';

  @override
  void initState() {
    super.initState();
    _delayMinutes = 7;
    _remainingSeconds = _delayMinutes * 60;

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  void _startTimer() {
    final appState = Provider.of<AppState>(context, listen: false);
    _delayMinutes = SmartDelayEngine.calculateOptimalDelay(
      cravingHistory: appState.cravingLogs,
      smokingHistory: appState.smokingLogs,
      cravingIntensity: _intensity,
      trigger: _selectedTrigger,
      baselineIntervalMinutes: appState.profile.typicalIntervalMinutes,
    );
    _remainingSeconds = _delayMinutes * 60;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        setState(() {
          _step = CravingStep.outcome;
        });
      }
    });
  }

  void _endTimerEarly() {
    _timer?.cancel();
    setState(() {
      _step = CravingStep.outcome;
    });
  }

  void _submitOutcome(String outcomeKey) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final elapsedMinutes = ((_delayMinutes * 60 - _remainingSeconds) / 60).round();

    setState(() {
      _outcome = outcomeKey;
      _step = CravingStep.summary;
    });

    await appState.logCraving(
      trigger: _selectedTrigger,
      intensity: _intensity,
      microAction: _selectedInterventionType == 'breathing'
          ? '4-7-8 Breathing'
          : (_selectedInterventionType == 'water'
              ? 'Cold Water'
              : (_selectedInterventionType == 'walk' ? 'Short Walk' : 'Conscious Delay')),
      delayedMinutesCompleted: elapsedMinutes,
      outcome: outcomeKey,
    );
  }

  String _formatTimer(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: textMut, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'CRAVING CONTROL',
                    style: AppTypography.labelUppercase.copyWith(
                      color: textMut,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Content in a scroll view to guarantee ZERO OVERFLOW
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: _buildCurrentStep(textPrim, textSec, textMut, cardBg, border, accent, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(
    Color textPrim,
    Color textSec,
    Color textMut,
    Color cardBg,
    Color border,
    Color accent,
    bool isDark,
  ) {
    switch (_step) {
      case CravingStep.intensity:
        return _buildIntensityStep(textPrim, textSec, textMut, accent, border);
      case CravingStep.trigger:
        return _buildTriggerStep(textPrim, textSec, textMut, border);
      case CravingStep.intervention:
        return _buildInterventionStep(textPrim, textSec, textMut, cardBg, border, accent, isDark);
      case CravingStep.outcome:
        return _buildOutcomeStep(textPrim, textSec, textMut, border);
      case CravingStep.summary:
        return _buildSummaryStep(textPrim, textSec, textMut, cardBg, border, accent);
    }
  }

  // Step 1: Intensity
  Widget _buildIntensityStep(
    Color textPrim,
    Color textSec,
    Color textMut,
    Color accent,
    Color border,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'STEP 1 OF 3 · URGE STRENGTH',
          style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10),
        ),
        const SizedBox(height: 8),
        Text(
          'How strong is the craving right now?',
          style: AppTypography.titleLarge.copyWith(
            color: textPrim,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rating your urge separates the automated impulse from conscious observation.',
          style: TextStyle(fontSize: 14, color: textSec, height: 1.4),
        ),
        const SizedBox(height: 48),

        Center(
          child: Column(
            children: [
              Text(
                '$_intensity',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  color: textPrim,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _intensity <= 3
                    ? 'Mild · Background thought'
                    : (_intensity <= 7 ? 'Moderate · Noticeable physical pull' : 'Intense · Acute urge peak'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _intensity > 7 ? AppColors.amber : accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        Slider(
          value: _intensity.toDouble(),
          min: 1.0,
          max: 10.0,
          divisions: 9,
          activeColor: _intensity > 7 ? AppColors.amber : accent,
          onChanged: (val) => setState(() => _intensity = val.round()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 (Mild)', style: TextStyle(fontSize: 11, color: textMut)),
              Text('5', style: TextStyle(fontSize: 11, color: textMut)),
              Text('10 (Peak)', style: TextStyle(fontSize: 11, color: textMut)),
            ],
          ),
        ),
        const SizedBox(height: 48),

        PrimaryButton(
          label: 'Next',
          onPressed: () => setState(() => _step = CravingStep.trigger),
          height: 50,
        ),
      ],
    );
  }

  // Step 2: Trigger
  Widget _buildTriggerStep(Color textPrim, Color textSec, Color textMut, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'STEP 2 OF 3 · HABIT CUE',
          style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10),
        ),
        const SizedBox(height: 8),
        Text(
          'What triggered this craving?',
          style: AppTypography.titleLarge.copyWith(
            color: textPrim,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Identifying the trigger allows Clarity to recommend what worked best historically.',
          style: TextStyle(fontSize: 14, color: textSec, height: 1.4),
        ),
        const SizedBox(height: 28),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _triggers.map((t) {
            final isSelected = _selectedTrigger == t;
            return TriggerChip(
              label: t,
              isSelected: isSelected,
              onSelected: (_) => setState(() => _selectedTrigger = t),
            );
          }).toList(),
        ),
        const SizedBox(height: 48),

        PrimaryButton(
          label: 'Begin Intervention',
          onPressed: () {
            _startTimer();
            setState(() => _step = CravingStep.intervention);
          },
          height: 50,
        ),
      ],
    );
  }

  // Step 3: Personalized Intervention (Adaptive Delay, Breathing, Cold Water, Walk)
  Widget _buildInterventionStep(
    Color textPrim,
    Color textSec,
    Color textMut,
    Color cardBg,
    Color border,
    Color accent,
    bool isDark,
  ) {
    final rationale = SmartDelayEngine.getDelayRationale(
      minutes: _delayMinutes,
      cravingIntensity: _intensity,
      trigger: _selectedTrigger,
    );

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          "You don't have to decide right now.",
          style: AppTypography.titleLarge.copyWith(
            color: textPrim,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Craving curves crest and decline within minutes.',
          style: TextStyle(fontSize: 13, color: textSec),
        ),
        const SizedBox(height: 24),

        // Timer
        Text(
          _formatTimer(_remainingSeconds),
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.w300,
            color: textPrim,
            letterSpacing: -1.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rationale,
          style: TextStyle(fontSize: 12, color: textMut, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Intervention Switcher Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInterventionPill('delay', 'Delay', Icons.timer_outlined, accent, border, textPrim),
            const SizedBox(width: 8),
            _buildInterventionPill('breathing', 'Breathe', Icons.air, accent, border, textPrim),
            const SizedBox(width: 8),
            _buildInterventionPill('water', 'Water', Icons.water_drop_outlined, accent, border, textPrim),
            const SizedBox(width: 8),
            _buildInterventionPill('walk', 'Walk', Icons.directions_walk, accent, border, textPrim),
          ],
        ),
        const SizedBox(height: 20),

        // Active Intervention Micro-Guide Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.0),
          ),
          child: _buildInterventionCardContent(textPrim, textSec, textMut, accent, isDark),
        ),
        const SizedBox(height: 28),

        // Actions: Pause / End early
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'End delay early',
                onPressed: _endTimerEarly,
                height: 46,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Craving passed',
                backgroundColor: accent,
                textColor: Colors.black,
                onPressed: () => _submitOutcome('craving_passed'),
                height: 46,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInterventionPill(
    String type,
    String label,
    IconData icon,
    Color accent,
    Color border,
    Color textPrim,
  ) {
    final isSelected = _selectedInterventionType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedInterventionType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? accent : border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? accent : textPrim),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? accent : textPrim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterventionCardContent(
    Color textPrim,
    Color textSec,
    Color textMut,
    Color accent,
    bool isDark,
  ) {
    if (_selectedInterventionType == 'breathing') {
      return Column(
        children: [
          Text(
            '4-7-8 Breathing Guide',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrim),
          ),
          const SizedBox(height: 6),
          Text(
            'Inhale quietly for 4s, hold gently for 7s, release slowly through mouth for 8s.',
            style: TextStyle(fontSize: 12, color: textSec, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.15).animate(
              CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.2),
                border: Border.all(color: accent, width: 2),
              ),
              child: Center(
                child: Icon(Icons.air, color: accent, size: 24),
              ),
            ),
          ),
        ],
      );
    } else if (_selectedInterventionType == 'water') {
      return Column(
        children: [
          Text(
            'Drink a Glass of Cold Water',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrim),
          ),
          const SizedBox(height: 6),
          Text(
            'The cold temperature stimulates your vagus nerve and shifts sensory focus in the mouth and throat away from cigarette heat.',
            style: TextStyle(fontSize: 12, color: textSec, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (_selectedInterventionType == 'walk') {
      return Column(
        children: [
          Text(
            'Change Your Immediate Setting',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrim),
          ),
          const SizedBox(height: 6),
          Text(
            'Step away from your desk, chair, or the current room for 2 minutes. Physical motion interrupts automated behavioral loops.',
            style: TextStyle(fontSize: 12, color: textSec, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'Notice Where the Urge Sits',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrim),
        ),
        const SizedBox(height: 6),
        Text(
          'Notice your hands, chest, and breathing. The craving is just a physical sensation passing through—you are in control.',
          style: TextStyle(fontSize: 12, color: textSec, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Step 4: Outcome (Section 17: "What happened?")
  Widget _buildOutcomeStep(Color textPrim, Color textSec, Color textMut, Color border) {
    final outcomes = [
      {'key': 'craving_passed', 'label': 'Craving passed completely'},
      {'key': 'delayed_then_smoked', 'label': 'I delayed and smoked later'},
      {'key': 'smoked', 'label': 'I smoked during the delay'},
      {'key': 'still_craving', 'label': 'I still want to smoke'},
      {'key': 'other_strategy', 'label': 'I used another strategy'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'CRAVING OUTCOME',
          style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10),
        ),
        const SizedBox(height: 8),
        Text(
          'What happened?',
          style: AppTypography.titleLarge.copyWith(
            color: textPrim,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'No judgment. Recording the actual outcome helps Clarity discover which interventions work best for you.',
          style: TextStyle(fontSize: 13, color: textSec, height: 1.4),
        ),
        const SizedBox(height: 24),

        ...outcomes.map((o) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(color: border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () => _submitOutcome(o['key']!),
              child: Text(
                o['label']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textPrim,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Step 5: Summary
  Widget _buildSummaryStep(
    Color textPrim,
    Color textSec,
    Color textMut,
    Color cardBg,
    Color border,
    Color accent,
  ) {
    final isSuccess = _outcome == 'craving_passed' || _outcome == 'delayed_then_smoked';

    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isSuccess ? accent : AppColors.amber).withValues(alpha: 0.15),
          ),
          child: Icon(
            isSuccess ? Icons.check : Icons.lightbulb_outline,
            size: 32,
            color: isSuccess ? accent : AppColors.amber,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isSuccess ? 'Urge Handled with Control' : 'Behavioral Data Recorded',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textPrim,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          isSuccess
            ? 'You paused and met this craving consciously. Each conscious delay rewires your brain away from automatic lighting.'
            : 'Understanding what leads to smoking is the first step toward lasting control. Tomorrow is another opportunity to delay.',
          style: TextStyle(fontSize: 14, color: textSec, height: 1.45),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        PrimaryButton(
          label: 'Return to Home',
          onPressed: () => Navigator.of(context).pop(),
          height: 48,
        ),
      ],
    );
  }
}
