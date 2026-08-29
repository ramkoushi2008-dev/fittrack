import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/screen_time_service.dart';
import './widgets/sleep_duration_card_widget.dart';
import './widgets/sleep_weekly_chart_widget.dart';
import './widgets/sleep_consistency_widget.dart';
import './widgets/sleep_quick_add_widget.dart';
import './widgets/sleep_suggestion_card_widget.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen>
    with WidgetsBindingObserver {
  double _hoursSlept = 7.75;
  static const double _targetHours = 8.0;
  bool _loadingLatest = true;

  bool _screenTimeSupported = false;
  bool _screenTimePermission = false;
  bool _requestingPermission = false;
  SleepSuggestion? _suggestion;
  bool _suggestionDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screenTimeSupported = Platform.isAndroid;
    _loadLatestSleepLog();
    _checkScreenTimeAndSuggest();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user grants Usage Access from system Settings, not an in-app
    // dialog, so re-check when they come back to the app.
    if (state == AppLifecycleState.resumed && _screenTimeSupported) {
      _checkScreenTimeAndSuggest();
    }
  }

  Future<void> _checkScreenTimeAndSuggest() async {
    if (!_screenTimeSupported) return;
    final granted = await ScreenTimeService.instance.hasPermission();
    if (!mounted) return;
    setState(() => _screenTimePermission = granted);
    if (!granted) return;

    final suggestion = await ScreenTimeService.instance
        .detectLastNightSleep();
    if (!mounted || suggestion == null) return;

    // Don't re-suggest if we already have a log for today.
    final log = await SupabaseService.instance.fetchLatestSleepLog();
    final loggedAt = log == null
        ? null
        : DateTime.tryParse(log['logged_at']?.toString() ?? '');
    final now = DateTime.now();
    final alreadyLoggedToday =
        loggedAt != null &&
        loggedAt.year == now.year &&
        loggedAt.month == now.month &&
        loggedAt.day == now.day;

    if (!mounted || alreadyLoggedToday || _suggestionDismissed) return;
    setState(() {
      _suggestion = suggestion;
      _suggestionDismissed = false;
    });
  }

  Future<void> _handleConnectScreenTimeTap() async {
    if (!_screenTimeSupported) return;
    setState(() => _requestingPermission = true);
    ScreenTimeService.instance.openPermissionSettings();
    // The permission screen is a separate system Activity; when the user
    // returns, didChangeAppLifecycleState re-checks. Clear the spinner
    // after a moment regardless so it doesn't hang if they don't grant it.
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _requestingPermission = false);
  }

  void _confirmSuggestion() {
    final s = _suggestion;
    if (s == null) return;
    _onSleepAdded(s.hours);
    setState(() => _suggestion = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged ${s.duration.inMinutes ~/ 60}h '
          '${(s.duration.inMinutes % 60).toString().padLeft(2, '0')}m of sleep',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.sleepColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _dismissSuggestion() {
    setState(() {
      _suggestion = null;
      _suggestionDismissed = true;
    });
  }

  void _adjustSuggestion() {
    _dismissSuggestion();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No problem — use Log Sleep below to enter the right amount.',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.surfaceVariantDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _loadLatestSleepLog() async {
    final log = await SupabaseService.instance.fetchLatestSleepLog();
    if (log != null && mounted) {
      setState(() {
        _hoursSlept = (log['hours_slept'] as num?)?.toDouble() ?? 7.75;
        _loadingLatest = false;
      });
    } else if (mounted) {
      setState(() => _loadingLatest = false);
    }
  }

  void _onSleepAdded(double hours) {
    setState(() {
      _hoursSlept = hours.clamp(0.0, 24.0);
    });
    // Sync to cloud
    SupabaseService.instance.saveSleepLog(hoursSlept: hours);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.sleepColor,
          backgroundColor: AppTheme.surfaceDark,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sleep',
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Track & improve your rest',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.sleepColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.bedtime_rounded,
                          color: AppTheme.sleepColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Screen-time sleep detection banner (Android only)
              if (_screenTimeSupported)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.sleepColor.withAlpha(30),
                            AppTheme.sleepColor.withAlpha(10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.sleepColor.withAlpha(50),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _screenTimePermission
                                ? Icons.check_circle_outline_rounded
                                : Icons.bedtime_outlined,
                            color: AppTheme.sleepColor,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _screenTimePermission
                                  ? "Suggesting sleep from your phone's "
                                        'screen-off time'
                                  : 'Detect sleep from screen-off time at '
                                        'night',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!_screenTimePermission) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _requestingPermission
                                  ? null
                                  : _handleConnectScreenTimeTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.sleepColor,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: _requestingPermission
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Connect',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // Detected sleep suggestion — always asks before logging
              if (_suggestion != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: SleepSuggestionCardWidget(
                      suggestion: _suggestion!,
                      onConfirm: _confirmSuggestion,
                      onAdjust: _adjustSuggestion,
                      onDismiss: _dismissSuggestion,
                    ),
                  ),
                ),

              // Duration card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: SleepDurationCardWidget(
                    hoursSlept: _hoursSlept,
                    targetHours: _targetHours,
                  ),
                ),
              ),

              // Quick add
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: SleepQuickAddWidget(onSleepAdded: _onSleepAdded),
                ),
              ),

              // Weekly chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: const SleepWeeklyChartWidget(),
                ),
              ),

              // Consistency metrics
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: const SleepConsistencyWidget(),
                ),
              ),

              // Tips section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _SleepTipsCard(
                    hoursSlept: _hoursSlept,
                    target: _targetHours,
                  ),
                ),
              ),

              // Bottom padding for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SleepTipsCard extends StatelessWidget {
  final double hoursSlept;
  final double target;

  const _SleepTipsCard({required this.hoursSlept, required this.target});

  @override
  Widget build(BuildContext context) {
    final deficit = target - hoursSlept;
    final tips = <Map<String, dynamic>>[];

    if (deficit > 1.0) {
      tips.add({
        'icon': Icons.alarm_rounded,
        'text':
            'Try going to bed ${deficit.toStringAsFixed(0)} hour(s) earlier tonight.',
        'color': AppTheme.warning,
      });
    }
    tips.add({
      'icon': Icons.phone_android_rounded,
      'text':
          'Avoid screens 30 minutes before bedtime for better sleep quality.',
      'color': AppTheme.sleepColor,
    });
    tips.add({
      'icon': Icons.thermostat_rounded,
      'text': 'Keep your room cool (18–20°C) for optimal sleep.',
      'color': AppTheme.info,
    });
    if (deficit <= 0) {
      tips.add({
        'icon': Icons.check_circle_rounded,
        'text': 'Great job! You met your sleep goal last night.',
        'color': AppTheme.success,
      });
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppTheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Sleep Tips',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: (tip['color'] as Color).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      tip['icon'] as IconData,
                      size: 12,
                      color: tip['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip['text'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '* Sleep recommendations are general guidance. Consult a healthcare professional for medical concerns.',
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppTheme.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
