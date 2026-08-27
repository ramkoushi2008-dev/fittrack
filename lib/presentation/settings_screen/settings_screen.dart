import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _workoutNotifications = true;
  bool _nutritionNotifications = true;
  bool _sleepNotifications = false;
  bool _isExporting = false;

  static const String _kWorkoutNotif = 'notif_workout';
  static const String _kNutritionNotif = 'notif_nutrition';
  static const String _kSleepNotif = 'notif_sleep';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workoutNotifications = prefs.getBool(_kWorkoutNotif) ?? true;
      _nutritionNotifications = prefs.getBool(_kNutritionNotif) ?? true;
      _sleepNotifications = prefs.getBool(_kSleepNotif) ?? false;
    });
  }

  Future<void> _saveNotif(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final Map<String, dynamic> data = {};
      for (final key in keys) {
        final val = prefs.get(key);
        data[key] = val;
      }
      final jsonStr = const JsonEncoder.withIndent('  ').convert({
        'exported_at': DateTime.now().toIso8601String(),
        'app': 'FitTrack',
        'data': data,
      });

      final bytes = utf8.encode(jsonStr);
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'fittrack_data_${DateTime.now().millisecondsSinceEpoch}.json',
        )
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data exported successfully!',
              style: GoogleFonts.manrope(color: const Color(0xFF1A1A1A)),
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export failed. Please try again.',
              style: GoogleFonts.manrope(color: AppTheme.textPrimary),
            ),
            backgroundColor: AppTheme.surfaceVariantDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _resetQuestionnaire() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Questionnaire?',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'This will clear all your personalisation answers and your workout plan will revert to defaults. This cannot be undone.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Reset',
              style: GoogleFonts.manrope(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final questionnaireKeys = [
        'experience_level',
        'fitness_goal',
        'training_preference',
        'equipment',
        'days_per_week',
        'schedule',
        'lifestyle',
        'questionnaire_completed',
      ];
      for (final key in questionnaireKeys) {
        await prefs.remove(key);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Questionnaire reset. Restart the app to redo it.',
              style: GoogleFonts.manrope(color: const Color(0xFF1A1A1A)),
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Text(
                    'Settings',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                children: [
                  // Notifications section
                  _SectionLabel(label: 'Notifications'),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _ToggleRow(
                        icon: Icons.fitness_center_rounded,
                        iconColor: AppTheme.workoutColor,
                        title: 'Workout Reminders',
                        subtitle: 'Daily nudges to hit your training sessions',
                        value: _workoutNotifications,
                        onChanged: (v) {
                          setState(() => _workoutNotifications = v);
                          _saveNotif(_kWorkoutNotif, v);
                        },
                      ),
                      _Divider(),
                      _ToggleRow(
                        icon: Icons.restaurant_rounded,
                        iconColor: AppTheme.proteinColor,
                        title: 'Nutrition Reminders',
                        subtitle: 'Meal logging and hydration prompts',
                        value: _nutritionNotifications,
                        onChanged: (v) {
                          setState(() => _nutritionNotifications = v);
                          _saveNotif(_kNutritionNotif, v);
                        },
                      ),
                      _Divider(),
                      _ToggleRow(
                        icon: Icons.bedtime_rounded,
                        iconColor: AppTheme.sleepColor,
                        title: 'Sleep Reminders',
                        subtitle: 'Wind-down alerts for better recovery',
                        value: _sleepNotifications,
                        onChanged: (v) {
                          setState(() => _sleepNotifications = v);
                          _saveNotif(_kSleepNotif, v);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Data section
                  _SectionLabel(label: 'Data'),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _ActionRow(
                        icon: Icons.download_rounded,
                        iconColor: AppTheme.info,
                        title: 'Export All Data',
                        subtitle: 'Download your logs as a JSON file',
                        trailing: _isExporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                        onTap: _isExporting ? null : _exportData,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Account section
                  _SectionLabel(label: 'Account'),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _ActionRow(
                        icon: Icons.refresh_rounded,
                        iconColor: AppTheme.warning,
                        title: 'Reset Questionnaire',
                        subtitle: 'Clear personalisation and start fresh',
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                        onTap: _resetQuestionnaire,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Footer
                  _Footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable sub-widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppTheme.surfaceVariantDark,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primaryContainer,
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.surfaceVariantDark,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'FitTrack',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version 1.0.0',
          style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {},
              child: Text(
                'Terms of Service',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '·',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Privacy Policy',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '© 2026 FitTrack. All rights reserved.',
          style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
