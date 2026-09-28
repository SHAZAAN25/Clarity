import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/strategy_mode.dart';
import '../services/target_engine.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Step 0: Identity & Welcome (Optional name)
  final TextEditingController _nameController = TextEditingController();

  // Step 1: Smoking Baseline & Economics (REQUIRED)
  int _cpd = 10;
  int _yearsSmoked = 5;
  int _firstCigMinutes = 30;
  final int _intervalMinutes = 60;
  int _packSize = 20;
  double _packPriceInr = 200.0; // ₹200 standard pack price

  // Step 2: Routines (REQUIRED: at least one)
  final Set<String> _selectedRoutines = {};
  final List<String> _routineOptions = [
    'Morning coffee',
    'After meals',
    'Work breaks',
    'Commute / Driving',
    'Evening relaxation',
    'Socializing with friends',
    'Before sleeping',
    'After stressful moments',
  ];

  // Step 3: Triggers (REQUIRED: at least one)
  final Set<String> _selectedTriggers = {};
  final List<String> _triggerOptions = [
    'Stress & Anxiety',
    'Work pressure',
    'Boredom',
    'Coffee / Tea',
    'Alcohol',
    'Social smoking cues',
    'Loneliness',
    'Habitual downtime',
  ];
  final TextEditingController _customTriggerController = TextEditingController();

  // Step 4: Primary Goal & Strategy Mode (REQUIRED: at least one goal)
  final Set<String> _selectedGoals = {'Reduce consumption progressively'};
  final List<String> _goalOptions = [
    'Reduce consumption progressively',
    'Regain control over impulses',
    'Save money',
    'Improve lung and cardiovascular health',
    'Quit completely on a specific date',
    'Stop smoking right now',
  ];
  StrategyMode _selectedStrategy = StrategyMode.reduce;
  DateTime? _targetQuitDate;

  // Step 5: Motivation & Personalized Review (Optional motivation)
  final TextEditingController _motivationController = TextEditingController();

  String? _stepError;

  @override
  void dispose() {
    _nameController.dispose();
    _customTriggerController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  bool _validateStep(int step) {
    setState(() => _stepError = null);
    switch (step) {
      case 0:
        return true; // Name is optional
      case 1:
        if (_cpd <= 0) {
          setState(() => _stepError = 'Please specify your typical cigarettes per day.');
          return false;
        }
        if (_yearsSmoked <= 0) {
          setState(() => _stepError = 'Please specify how many years you have smoked.');
          return false;
        }
        if (_packSize <= 0) {
          setState(() => _stepError = 'Cigarettes per pack must be greater than zero.');
          return false;
        }
        if (_packPriceInr <= 0) {
          setState(() => _stepError = 'Pack price in ₹ INR must be greater than zero.');
          return false;
        }
        return true;
      case 2:
        if (_selectedRoutines.isEmpty) {
          setState(() => _stepError = 'Please select at least one routine when you typically smoke.');
          return false;
        }
        return true;
      case 3:
        final hasTriggers =
            _selectedTriggers.isNotEmpty || _customTriggerController.text.trim().isNotEmpty;
        if (!hasTriggers) {
          setState(() => _stepError = 'Please select at least one primary smoking trigger.');
          return false;
        }
        return true;
      case 4:
        if (_selectedGoals.isEmpty) {
          setState(() => _stepError = 'Please select at least one primary goal.');
          return false;
        }
        if (_selectedStrategy == StrategyMode.quitByDate && _targetQuitDate == null) {
          setState(() => _stepError = 'Please choose your target quit date.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
          _stepError = null;
        });
      } else {
        _finishOnboarding();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _stepError = null;
      });
    }
  }

  void _finishOnboarding() async {
    // Validate all required steps before completion
    for (int s = 1; s <= 4; s++) {
      if (!_validateStep(s)) {
        setState(() => _currentStep = s);
        return;
      }
    }

    final appState = Provider.of<AppState>(context, listen: false);

    final triggersList = List<String>.from(_selectedTriggers);
    if (_customTriggerController.text.trim().isNotEmpty) {
      triggersList.add(_customTriggerController.text.trim());
    }

    await appState.completeOnboarding(
      name: _nameController.text.trim(),
      baselineCpd: _cpd,
      yearsSmoked: _yearsSmoked,
      ageStarted: 18,
      firstCigAfterWakingMins: _firstCigMinutes,
      typicalIntervalMins: _intervalMinutes,
      packSize: _packSize,
      packPriceInr: _packPriceInr,
      routines: _selectedRoutines.toList(),
      triggers: triggersList,
      goals: _selectedGoals.toList(),
      motivation: _motivationController.text.trim(),
      strategyMode: _selectedStrategy,
      targetQuitDate: _targetQuitDate,
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const ClarityAppShell(),
          transitionsBuilder: (context, anim, secAnim, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;
    final border = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Step Indicator (Step X of 6)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textPrim, size: 20),
                      onPressed: _previousStep,
                    )
                  else
                    const SizedBox(width: 44),
                  Column(
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(_totalSteps, (idx) {
                          final isCurrent = idx == _currentStep;
                          final isCompleted = idx < _currentStep;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isCurrent ? 20 : 6,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? accent
                                  : (isCompleted
                                      ? accent.withValues(alpha: 0.5)
                                      : border),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            if (_stepError != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _stepError!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _buildCurrentStepContent(isDark, textPrim, textSec, textMut, accent, border, cardBg),
              ),
            ),

            // Bottom Navigation Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: PrimaryButton(
                label: _currentStep == _totalSteps - 1 ? 'BEGIN MY JOURNEY' : 'CONTINUE',
                onPressed: _nextStep,
                height: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(
    bool isDark,
    Color textPrim,
    Color textSec,
    Color textMut,
    Color accent,
    Color border,
    Color cardBg,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildStep0Identity(textPrim, textSec, textMut, cardBg, border);
      case 1:
        return _buildStep1Baseline(isDark, textPrim, textSec, textMut, accent, border, cardBg);
      case 2:
        return _buildStep2Routines(textPrim, textSec, textMut, accent, border, cardBg);
      case 3:
        return _buildStep3Triggers(textPrim, textSec, textMut, accent, border, cardBg);
      case 4:
        return _buildStep4Goals(isDark, textPrim, textSec, textMut, accent, border, cardBg);
      case 5:
        return _buildStep5Review(isDark, textPrim, textSec, textMut, accent, border, cardBg);
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Identity
  Widget _buildStep0Identity(Color textPrim, Color textSec, Color textMut, Color cardBg, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to Clarity.',
          style: AppTypography.titleLarge.copyWith(color: textPrim, fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'A quiet, private behavioral companion. To build your personal model, we will ask a few essential questions about how you actually smoke.',
          style: AppTypography.bodySmall.copyWith(color: textSec, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 28),
        Text('WHAT SHOULD WE CALL YOU? (OPTIONAL)', style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: TextStyle(color: textPrim, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Your name or nickname',
            hintStyle: TextStyle(color: textMut),
            filled: true,
            fillColor: cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
          ),
        ),
      ],
    );
  }

  // Step 1: Baseline & Economics (MANDATORY)
  Widget _buildStep1Baseline(bool isDark, Color textPrim, Color textSec, Color textMut, Color accent, Color border, Color cardBg) {
    final costPerCig = _packPriceInr / (_packSize > 0 ? _packSize : 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Smoking Baseline',
          style: AppTypography.titleLarge.copyWith(color: textPrim, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Clarity uses this to establish your initial ceiling and money calculations. Be completely honest—there is zero judgment.',
          style: AppTypography.bodySmall.copyWith(color: textSec, fontSize: 13, height: 1.45),
        ),
        const SizedBox(height: 24),

        // Cigarettes / Day counter
        _buildCounterRow(
          label: 'TYPICAL CIGARETTES PER DAY',
          value: _cpd,
          unit: 'cigs',
          min: 1,
          max: 60,
          onChanged: (val) => setState(() => _cpd = val),
          textPrim: textPrim,
          textMut: textMut,
          accent: accent,
          cardBg: cardBg,
          border: border,
        ),
        const SizedBox(height: 18),

        // Years smoked
        _buildCounterRow(
          label: 'YEARS SMOKING',
          value: _yearsSmoked,
          unit: 'years',
          min: 1,
          max: 50,
          onChanged: (val) => setState(() => _yearsSmoked = val),
          textPrim: textPrim,
          textMut: textMut,
          accent: accent,
          cardBg: cardBg,
          border: border,
        ),
        const SizedBox(height: 18),

        // First cigarette timing
        _buildCounterRow(
          label: 'FIRST CIGARETTE AFTER WAKING',
          value: _firstCigMinutes,
          unit: 'mins',
          min: 5,
          max: 180,
          step: 5,
          onChanged: (val) => setState(() => _firstCigMinutes = val),
          textPrim: textPrim,
          textMut: textMut,
          accent: accent,
          cardBg: cardBg,
          border: border,
        ),
        const SizedBox(height: 18),

        // Pack Price (INR ₹ strictly)
        _buildCounterRow(
          label: 'PRICE PER PACK (₹ INR)',
          value: _packPriceInr.toInt(),
          unit: '₹',
          min: 50,
          max: 1000,
          step: 10,
          onChanged: (val) => setState(() => _packPriceInr = val.toDouble()),
          textPrim: textPrim,
          textMut: textMut,
          accent: accent,
          cardBg: cardBg,
          border: border,
        ),
        const SizedBox(height: 18),

        // Pack Size
        _buildCounterRow(
          label: 'CIGARETTES PER PACK',
          value: _packSize,
          unit: 'cigs',
          min: 10,
          max: 30,
          step: 10,
          onChanged: (val) => setState(() => _packSize = val),
          textPrim: textPrim,
          textMut: textMut,
          accent: accent,
          cardBg: cardBg,
          border: border,
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cost per cigarette:', style: TextStyle(color: textSec, fontSize: 13)),
              Text('₹${costPerCig.toStringAsFixed(2)}', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  // Step 2: Routines (MANDATORY: >= 1)
  Widget _buildStep2Routines(Color textPrim, Color textSec, Color textMut, Color accent, Color border, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Smoking Routines',
          style: AppTypography.titleLarge.copyWith(color: textPrim, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Select at least one routine when smoking feels automatic. This helps Clarity predict craving windows.',
          style: AppTypography.bodySmall.copyWith(color: textSec, fontSize: 13, height: 1.45),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _routineOptions.map((r) {
            final isSel = _selectedRoutines.contains(r);
            return FilterChip(
              label: Text(r),
              selected: isSel,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedRoutines.add(r);
                  } else {
                    _selectedRoutines.remove(r);
                  }
                });
              },
              backgroundColor: cardBg,
              selectedColor: accent.withValues(alpha: 0.2),
              side: BorderSide(color: isSel ? accent : border),
              labelStyle: TextStyle(
                color: isSel ? accent : textPrim,
                fontSize: 13,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Step 3: Triggers (MANDATORY: >= 1)
  Widget _buildStep3Triggers(Color textPrim, Color textSec, Color textMut, Color accent, Color border, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Triggers',
          style: AppTypography.titleLarge.copyWith(color: textPrim, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'What feelings or situations trigger the urge to smoke? Select all that apply.',
          style: AppTypography.bodySmall.copyWith(color: textSec, fontSize: 13, height: 1.45),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _triggerOptions.map((t) {
            final isSel = _selectedTriggers.contains(t);
            return FilterChip(
              label: Text(t),
              selected: isSel,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedTriggers.add(t);
                  } else {
                    _selectedTriggers.remove(t);
                  }
                });
              },
              backgroundColor: cardBg,
              selectedColor: accent.withValues(alpha: 0.2),
              side: BorderSide(color: isSel ? accent : border),
              labelStyle: TextStyle(
                color: isSel ? accent : textPrim,
                fontSize: 13,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('CUSTOM TRIGGER (OPTIONAL)', style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10)),
        const SizedBox(height: 8),
        TextField(
          controller: _customTriggerController,
          style: TextStyle(color: textPrim, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Add another trigger (e.g. Traffic)',
            hintStyle: TextStyle(color: textMut),
            filled: true,
            fillColor: cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
          ),
        ),
      ],
    );
  }

  // Step 4: Goals & Strategy Mode (MANDATORY: >= 1)
  Widget _buildStep4Goals(bool isDark, Color textPrim, Color textSec, Color textMut, Color accent, Color border, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Goals & Strategy',
          style: AppTypography.titleLarge.copyWith(color: textPrim, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Select your primary aspirations and how you want Clarity to pace your journey.',
          style: AppTypography.bodySmall.copyWith(color: textSec, fontSize: 13, height: 1.45),
        ),
        const SizedBox(height: 18),
        Text('PRIMARY GOALS', style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10)),
        const SizedBox(height: 8),
        ..._goalOptions.map((g) {
          final isSel = _selectedGoals.contains(g);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSel ? accent.withValues(alpha: 0.08) : cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSel ? accent : border),
            ),
            child: CheckboxListTile(
              title: Text(g, style: TextStyle(color: textPrim, fontSize: 13, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400)),
              value: isSel,
              activeColor: accent,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedGoals.add(g);
                  } else {
                    _selectedGoals.remove(g);
                  }
                });
              },
            ),
          );
        }),
        const SizedBox(height: 18),
        Text('STRATEGY MODE', style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StrategyMode.reduce,
            StrategyMode.quitByDate,
            StrategyMode.quitNow,
          ].map((mode) {
            final isSel = _selectedStrategy == mode;
            return ChoiceChip(
              label: Text(mode.label),
              selected: isSel,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedStrategy = mode);
                }
              },
              backgroundColor: cardBg,
              selectedColor: accent.withValues(alpha: 0.25),
              side: BorderSide(color: isSel ? accent : border),
              labelStyle: TextStyle(
                color: isSel ? accent : textPrim,
                fontSize: 12,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
        if (_selectedStrategy == StrategyMode.quitByDate) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Quit Date:', style: TextStyle(color: textSec, fontSize: 13)),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now().add(const Duration(days: 7)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _targetQuitDate = picked);
                  }
                },
                child: Text(
                  _targetQuitDate != null
                      ? DateFormat('dd MMM yyyy').format(_targetQuitDate!)
                      : 'Select target date',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Step 5: Motivation & Review
  Widget _buildStep5Review(bool isDark, Color textPrim, Color textSec, Color textMut, Color accent, Color border, Color cardBg) {
    // initialTarget = ceil(effectiveBaseline * 0.90)
    final initialTarget = _selectedStrategy == StrategyMode.quitNow
        ? 0
        : TargetEngine.calculateInitialReductionTarget(_cpd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personalized Setup',
          style: AppTypography.titleLarge.copyWith(color: textPrim, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Here is your deterministic starting baseline. Clarity will track, understand, and coach you quietly.',
          style: AppTypography.bodySmall.copyWith(color: textSec, fontSize: 13, height: 1.45),
        ),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Baseline CPD:', style: TextStyle(color: textSec, fontSize: 13)),
                  Text('$_cpd cigarettes', style: TextStyle(color: textPrim, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Initial Daily Ceiling:', style: TextStyle(color: textSec, fontSize: 13)),
                  Text('$initialTarget cigarettes/day', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Strategy Mode:', style: TextStyle(color: textSec, fontSize: 13)),
                  Text(_selectedStrategy.label, style: TextStyle(color: textPrim, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pack Price (INR):', style: TextStyle(color: textSec, fontSize: 13)),
                  Text('₹${_packPriceInr.toInt()}', style: TextStyle(color: textPrim, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text('YOUR WHY / MOTIVATION (OPTIONAL)', style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10)),
        const SizedBox(height: 8),
        TextField(
          controller: _motivationController,
          maxLines: 3,
          style: TextStyle(color: textPrim, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'e.g. I want to feel physically energized for my kids and regain control over automatic urges.',
            hintStyle: TextStyle(color: textMut, fontSize: 13),
            filled: true,
            fillColor: cardBg,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int value,
    required String unit,
    required int min,
    required int max,
    int step = 1,
    required ValueChanged<int> onChanged,
    required Color textPrim,
    required Color textMut,
    required Color accent,
    required Color cardBg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 9.5)),
                const SizedBox(height: 4),
                Text('$value $unit', style: TextStyle(color: textPrim, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 24),
                color: textMut,
                onPressed: value > min ? () => onChanged(value - step) : null,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 24),
                color: accent,
                onPressed: value < max ? () => onChanged(value + step) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
