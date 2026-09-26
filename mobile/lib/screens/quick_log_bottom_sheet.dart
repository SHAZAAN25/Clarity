import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/trigger_chip.dart';

class QuickLogBottomSheet extends StatefulWidget {
  const QuickLogBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const QuickLogBottomSheet(),
    );
  }

  @override
  State<QuickLogBottomSheet> createState() => _QuickLogBottomSheetState();
}

class _QuickLogBottomSheetState extends State<QuickLogBottomSheet> {
  final DateTime _logTime = DateTime.now();
  String _selectedTrigger = 'Stress';
  String _selectedSituation = 'Work';
  int _cravingIntensity = 5;
  bool _delayedFirst = false;
  final TextEditingController _noteController = TextEditingController();

  final List<String> _triggers = [
    'Stress',
    'Coffee',
    'After food',
    'Work',
    'Boredom',
    'Social',
    'Alcohol',
    'Habit',
  ];

  final List<String> _situations = [
    'Work',
    'Home',
    'Commute',
    'Social',
    'Outdoor',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveLog() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.logCigarette(
      trigger: _selectedTrigger,
      situation: _selectedSituation,
      mood: 'Logged',
      location: _selectedSituation,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      cravingIntensity: _cravingIntensity,
      delayedFirst: _delayedFirst,
      delayMinutes: _delayedFirst ? appState.adaptiveDelayMinutes : null,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cigarette logged. Thank you for keeping track.'),
          backgroundColor: AppColors.sagePrimary,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final elevatedBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 24 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: border, width: 1.0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Cigarette',
                  style: AppTypography.titleMedium.copyWith(
                    color: textPrim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('h:mm a').format(_logTime),
                  style: TextStyle(fontSize: 13, color: textMut),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Trigger Selection
            Text(
              'PRIMARY TRIGGER',
              style: AppTypography.labelUppercase.copyWith(
                color: textMut,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _triggers.map((t) {
                final isSelected = _selectedTrigger == t;
                return TriggerChip(
                  label: t,
                  isSelected: isSelected,
                  onSelected: (_) => setState(() => _selectedTrigger = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Situation / Location
            Text(
              'SITUATION',
              style: AppTypography.labelUppercase.copyWith(
                color: textMut,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _situations.map((s) {
                final isSelected = _selectedSituation == s;
                return TriggerChip(
                  label: s,
                  isSelected: isSelected,
                  onSelected: (_) => setState(() => _selectedSituation = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Craving Intensity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CRAVING INTENSITY: $_cravingIntensity / 10',
                  style: AppTypography.labelUppercase.copyWith(
                    color: textMut,
                    fontSize: 10,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            Slider(
              value: _cravingIntensity.toDouble(),
              min: 1.0,
              max: 10.0,
              divisions: 9,
              activeColor: accent,
              onChanged: (val) => setState(() => _cravingIntensity = val.round()),
            ),
            const SizedBox(height: 10),

            // Optional Delay checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'I practiced conscious delay first',
                style: TextStyle(fontSize: 13, color: textPrim),
              ),
              value: _delayedFirst,
              activeColor: AppColors.sagePrimary,
              onChanged: (val) => setState(() => _delayedFirst = val ?? false),
            ),
            const SizedBox(height: 10),

            // Optional note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: elevatedBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border, width: 1.0),
              ),
              child: TextField(
                controller: _noteController,
                style: TextStyle(color: textPrim, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Add an optional note (e.g., after client call)',
                  hintStyle: TextStyle(color: textMut, fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              label: 'Save Cigarette Log',
              onPressed: _saveLog,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
