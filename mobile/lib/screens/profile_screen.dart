import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/strategy_mode.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _baselineCpdController;
  late TextEditingController _targetCpdController;
  late TextEditingController _yearsSmokedController;
  late TextEditingController _firstCigTimeController;
  late TextEditingController _intervalController;
  late TextEditingController _packPriceController;
  late TextEditingController _packSizeController;
  late TextEditingController _motivationController;

  late StrategyMode _strategyMode;
  DateTime? _targetQuitDate;
  late Set<String> _routines;
  late Set<String> _triggers;
  late Set<String> _goals;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AppState>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile.name);
    _baselineCpdController = TextEditingController(text: '${profile.cigarettesPerDay}');
    _targetCpdController = TextEditingController(text: '${profile.targetCigarettesPerDay}');
    _yearsSmokedController = TextEditingController(text: '${profile.smokingDuration}');
    _firstCigTimeController = TextEditingController(text: '${profile.firstCigaretteTime}');
    _intervalController = TextEditingController(text: '${profile.averageInterval}');
    _packPriceController = TextEditingController(text: '${profile.packPrice.toInt()}');
    _packSizeController = TextEditingController(text: '${profile.cigarettesPerPack}');
    _motivationController = TextEditingController(text: profile.motivation);

    _strategyMode = profile.strategyMode;
    _targetQuitDate = profile.targetQuitDate;
    _routines = Set<String>.from(profile.routines);
    _triggers = Set<String>.from(profile.triggers);
    _goals = Set<String>.from(profile.goals);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baselineCpdController.dispose();
    _targetCpdController.dispose();
    _yearsSmokedController.dispose();
    _firstCigTimeController.dispose();
    _intervalController.dispose();
    _packPriceController.dispose();
    _packSizeController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final baseline = int.tryParse(_baselineCpdController.text.trim()) ?? appState.profile.cigarettesPerDay;
    final target = int.tryParse(_targetCpdController.text.trim()) ?? appState.profile.targetCigarettesPerDay;
    final years = int.tryParse(_yearsSmokedController.text.trim()) ?? appState.profile.smokingDuration;
    final firstTime = int.tryParse(_firstCigTimeController.text.trim()) ?? appState.profile.firstCigaretteTime;
    final interval = int.tryParse(_intervalController.text.trim()) ?? appState.profile.averageInterval;
    final price = double.tryParse(_packPriceController.text.trim()) ?? appState.profile.packPrice;
    final packSize = int.tryParse(_packSizeController.text.trim()) ?? appState.profile.cigarettesPerPack;

    await appState.updateProfile(
      name: _nameController.text.trim(),
      cigarettesPerDay: baseline,
      smokingDuration: years,
      firstCigaretteTime: firstTime,
      averageInterval: interval,
      packPrice: price,
      cigarettesPerPack: packSize,
      routines: _routines.toList(),
      triggers: _triggers.toList(),
      goals: _goals.toList(),
      motivation: _motivationController.text.trim(),
      targetCpd: target,
      targetQuitDate: _targetQuitDate,
      strategyMode: _strategyMode,
    );

    setState(() => _isEditing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: AppColors.sagePrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    bool isNumeric = true,
    String? suffix,
  }) {
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final bg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final border = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: _isEditing,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            style: TextStyle(color: textPrim, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: _isEditing ? bg : Colors.transparent,
              suffixText: suffix,
              suffixStyle: TextStyle(color: textMut, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: border),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.sagePrimary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final profile = appState.profile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;

    final costPerCig = profile.costPerCigarette;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Personal Profile',
          style: TextStyle(
            color: textPrim,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'App Settings',
            icon: Icon(Icons.settings_outlined, color: textSec, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined, color: accent, size: 20),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Identity Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name.isNotEmpty ? profile.name : 'Smoking Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textPrim,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Active Strategy: ${profile.strategyMode.label}',
                            style: TextStyle(
                              fontSize: 12,
                              color: accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Steady · ${profile.steadyStreak}d',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 2. Personal Info & Baseline
              SectionHeader(title: 'Smoking Baseline'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    _buildField(
                      label: 'NAME',
                      controller: _nameController,
                      isDark: isDark,
                      isNumeric: false,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'CIGARETTES / DAY (BASELINE)',
                            controller: _baselineCpdController,
                            isDark: isDark,
                            suffix: 'cigs',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            label: 'YEARS SMOKED',
                            controller: _yearsSmokedController,
                            isDark: isDark,
                            suffix: 'years',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'FIRST CIGARETTE TIMING',
                            controller: _firstCigTimeController,
                            isDark: isDark,
                            suffix: 'min',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            label: 'AVERAGE INTERVAL',
                            controller: _intervalController,
                            isDark: isDark,
                            suffix: 'min',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 3. Cigarette Economics (Section 35: Strictly INR ₹)
              SectionHeader(
                title: 'Cigarette Economics',
                subtitle: 'All financial calculations use Indian Rupees (₹)',
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'PACK PRICE (INR ₹)',
                            controller: _packPriceController,
                            isDark: isDark,
                            suffix: '₹',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            label: 'CIGARETTES PER PACK',
                            controller: _packSizeController,
                            isDark: isDark,
                            suffix: 'cigs',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Derived Cost per Cigarette:',
                            style: TextStyle(fontSize: 12, color: textSec),
                          ),
                          Text(
                            '₹${costPerCig.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 4. Reduction Strategy & Target
              SectionHeader(title: 'Active Target & Strategy'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      label: 'ACTIVE DAILY TARGET CEILING',
                      controller: _targetCpdController,
                      isDark: isDark,
                      suffix: 'cigs/day',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'STRATEGY MODE',
                      style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: StrategyMode.values.map((mode) {
                        final isSel = _strategyMode == mode;
                        return ChoiceChip(
                          label: Text(mode.label),
                          selected: isSel,
                          onSelected: _isEditing
                              ? (sel) {
                                  if (sel) {
                                    setState(() {
                                      _strategyMode = mode;
                                      if (mode == StrategyMode.quitNow) {
                                        _targetCpdController.text = '0';
                                      }
                                    });
                                  }
                                }
                              : null,
                          selectedColor: accent.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: isSel ? accent : textSec,
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_strategyMode == StrategyMode.quitByDate) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Target Quit Date:', style: TextStyle(color: textSec, fontSize: 13)),
                          TextButton(
                            onPressed: _isEditing
                                ? () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _targetQuitDate ??
                                          DateTime.now().add(const Duration(days: 30)),
                                      firstDate: DateTime.now(),
                                      lastDate:
                                          DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setState(() => _targetQuitDate = picked);
                                    }
                                  }
                                : null,
                            child: Text(
                              _targetQuitDate != null
                                  ? DateFormat('dd MMM yyyy').format(_targetQuitDate!)
                                  : 'Select date',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 5. Routines, Triggers & Motivation
              SectionHeader(title: 'Routines & Triggers'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ROUTINES', style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _routines.map((r) {
                        return Chip(
                          label: Text(r, style: TextStyle(color: textPrim, fontSize: 12)),
                          backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          deleteIcon: _isEditing ? const Icon(Icons.close, size: 14) : null,
                          onDeleted: _isEditing
                              ? () {
                                  setState(() => _routines.remove(r));
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text('TRIGGERS', style: AppTypography.labelUppercase.copyWith(color: textMut, fontSize: 10)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _triggers.map((t) {
                        return Chip(
                          label: Text(t, style: TextStyle(color: textPrim, fontSize: 12)),
                          backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          deleteIcon: _isEditing ? const Icon(Icons.close, size: 14) : null,
                          onDeleted: _isEditing
                              ? () {
                                  setState(() => _triggers.remove(t));
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label: 'PRIMARY MOTIVATION',
                      controller: _motivationController,
                      isDark: isDark,
                      isNumeric: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 6. Target History (Section 31: Immutable History)
              if (appState.targetHistory.isNotEmpty) ...[
                SectionHeader(title: 'Target History (Immutable Audit Log)'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: appState.targetHistory.take(5).map((th) {
                      final dateStr = DateFormat('dd MMM').format(th.effectiveDate);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr, style: TextStyle(color: textMut, fontSize: 12)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${th.previousTarget} → ${th.newTarget} cigs/day',
                                    style: TextStyle(
                                      color: textPrim,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    th.reason,
                                    style: TextStyle(color: textSec, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                th.source,
                                style: TextStyle(color: textMut, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 22),
              ],

              // 7. Save changes button
              if (_isEditing) ...[
                PrimaryButton(
                  label: 'SAVE CHANGES',
                  onPressed: _saveProfile,
                  height: 48,
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
