import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/section_header.dart';
import 'welcome_auth_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showExportDataDialog(BuildContext context) async {
    final jsonStr = await StorageService.exportUserData();
    if (!context.mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        title: Text(
          'Exported User Data (JSON)',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonStr,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyModal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: border, width: 1.0)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Zero Ad-Monopolies & Profiling\nClarity does not sell, license, or monetize your personal health data, cigarette logs, or craving history with advertisers or data brokers.\n\n'
                '2. Local-First Storage Architecture\nAll daily smoking timestamps, situation tags, and delay logs are stored securely on your local device. Network communication occurs exclusively when user sync is configured.\n\n'
                '3. Context Minimization for Coaching\nWhen AI coaching suggestions are generated, only anonymized aggregate counts (such as today\'s count and top trigger) are processed. Personal identifiers and full history are never exposed.\n\n'
                '4. Data Portability & Complete Erasure\nYou retain 100% ownership of your data. You may download a full unencrypted JSON backup or erase all local records permanently with one tap.',
                style: TextStyle(
                  fontSize: 13,
                  color: textSec,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Close',
                onPressed: () => Navigator.of(ctx).pop(),
                height: 44,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsModal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: border, width: 1.0)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Behavioral Support Tool\nClarity is an evidence-informed behavioral reduction companion based on Cognitive Behavioral Therapy (CBT) and cue-extinction principles. It is not a certified medical device.\n\n'
                '2. Medical Emergency Boundaries\nClarity does not provide clinical diagnoses, emergency psychiatric intervention, or pharmaceutical prescriptions. If you experience severe chest discomfort, acute shortness of breath, or distress, seek emergency medical care immediately.\n\n'
                '3. User Responsibility & Tracking\nThe accuracy of adaptive target schedules depends on honest user tracking. Clarity is non-punitive and treats all smoking events as data for personal habit transformation.\n\n'
                '4. Service Availability & Updates\nClarity is provided for personal health and habit self-regulation. Features and behavioral algorithms may be updated to reflect advancing clinical evidence.',
                style: TextStyle(
                  fontSize: 13,
                  color: textSec,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Close',
                onPressed: () => Navigator.of(ctx).pop(),
                height: 44,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        title: Text(
          'Delete account and data?',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will permanently erase all local cigarette logs, craving events, target history, and behavioral patterns. This action cannot be undone.',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.deleteAccount();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeAuthScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Erase Everything',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSignOut(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of Clarity?',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeAuthScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.sagePrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Application Settings',
          style: TextStyle(
            color: textPrim,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Appearance & Theme
              SectionHeader(title: 'Appearance'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            size: 20, color: textPrim),
                        const SizedBox(width: 12),
                        Text(
                          'Dark Appearance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrim,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isDark,
                      activeThumbColor: accent,
                      onChanged: (val) {
                        appState.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 2. Notification Preferences
              SectionHeader(title: 'Notifications & Alerts'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.0),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Gentle Craving Reminders',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrim),
                      ),
                      subtitle: Text(
                        'Encourages a 7-minute pause during high-risk trigger periods',
                        style: TextStyle(fontSize: 12, color: textSec),
                      ),
                      value: appState.profile.notificationsEnabled,
                      activeTrackColor: accent.withValues(alpha: 0.5),
                      activeThumbColor: accent,
                      onChanged: (val) => appState.toggleNotifications(val),
                    ),
                    Divider(color: border, height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'High-Risk Trigger Window Alerts',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrim),
                      ),
                      subtitle: Text(
                        'Notifies you 15 minutes before typical routine smoking hours',
                        style: TextStyle(fontSize: 12, color: textSec),
                      ),
                      value: appState.profile.highRiskAlertsEnabled,
                      activeTrackColor: accent.withValues(alpha: 0.5),
                      activeThumbColor: accent,
                      onChanged: (val) => appState.toggleHighRiskAlerts(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 3. Currency (Section 35: Strictly INR)
              SectionHeader(title: 'Currency Standard'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Standard Currency',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrim)),
                        const SizedBox(height: 2),
                        Text('Indian Rupee (INR)', style: TextStyle(fontSize: 12, color: textSec)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('₹ INR',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 4. Privacy & Data Ownership (Section 9)
              SectionHeader(title: 'Privacy & Data Ownership'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                        const Icon(Icons.shield_outlined, size: 16, color: AppColors.sagePrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Local-First Privacy Architecture',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrim,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All your cigarette logs, craving delay records, and behavioral patterns are stored encrypted on your local device. No health data is sold or shared.',
                      style: AppTypography.bodySmall.copyWith(
                        color: textSec,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Privacy Policy',
                            onPressed: () => _showPrivacyPolicyModal(context),
                            height: 38,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SecondaryButton(
                            label: 'Terms of Use',
                            onPressed: () => _showTermsModal(context),
                            height: 38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SecondaryButton(
                      label: 'Export Data (JSON)',
                      onPressed: () => _showExportDataDialog(context),
                      height: 38,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 5. Medical Disclaimer (Section 41)
              SectionHeader(title: 'Medical Information & Safety'),
              Container(
                width: double.infinity,
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
                      'Behavioral Coaching — Not Medical Advice',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrim,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Clarity provides digital behavioral self-regulation support. It does not provide medical diagnosis, clinical pharmacology, or psychiatric emergency care. If you experience emergency medical symptoms, contact emergency medical services immediately.',
                      style: AppTypography.bodySmall.copyWith(
                        color: textSec,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Account Actions (Sign Out & Delete)
              SectionHeader(title: 'Account'),
              SecondaryButton(
                label: 'Sign Out',
                onPressed: () => _handleSignOut(context),
                height: 44,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => _confirmDeleteAccount(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete Account & Erase Data',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // App Version
              Center(
                child: Text(
                  'Clarity · Version 1.0.0+1 · Production',
                  style: TextStyle(color: textMut, fontSize: 11),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
