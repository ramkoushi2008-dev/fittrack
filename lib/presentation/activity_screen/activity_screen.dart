import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/health_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import './widgets/activity_bar_chart_widget.dart';
import './widgets/metric_tab_selector_widget.dart';
import './widgets/step_ring_widget.dart';
import './widgets/workout_history_card_widget.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with WidgetsBindingObserver {
  // TODO: Replace with [Riverpod/Bloc] for production
  int _selectedMetric = 0;

  bool _isConnected = false;
  bool _isConnecting = false;
  DailySummary? _summary;
  List<double>? _dailySteps;
  List<double>? _dailyActiveMinutes;
  List<double>? _dailyCalories;
  Timer? _pollTimer;

  static const _pollInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final connected = await HealthService.instance.isConnected();
    if (!mounted) return;
    setState(() => _isConnected = connected);
    // Calories come from the user's own logged meals (Supabase), so they
    // refresh regardless of whether Health Connect / HealthKit is linked.
    await _refreshCalories();
    if (connected) {
      await _refreshHealthData();
    }
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      _refreshCalories();
      if (_isConnected) _refreshHealthData();
    });
  }

  Future<void> _refreshCalories() async {
    try {
      final calories = await SupabaseService.instance
          .fetchDailyCaloriesSeries();
      if (!mounted) return;
      setState(() => _dailyCalories = calories);
    } catch (_) {
      // Keep last known values; next poll will retry.
    }
  }

  Future<void> _refreshHealthData() async {
    try {
      final results = await Future.wait([
        HealthService.instance.fetchTodaySummary(),
        HealthService.instance.fetchDailyStepsSeries(),
        HealthService.instance.fetchDailyActiveMinutesSeries(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as DailySummary;
        _dailySteps = results[1] as List<double>;
        _dailyActiveMinutes = results[2] as List<double>;
      });
    } catch (_) {
      // Keep showing the last known values if a single refresh fails
      // (e.g. transient Health Connect hiccup); next poll will retry.
    }
  }

  Future<void> _handleConnectTap() async {
    setState(() => _isConnecting = true);
    try {
      final granted = await HealthService.instance.requestPermissions();
      if (!mounted) return;
      setState(() {
        _isConnected = granted;
        _isConnecting = false;
      });
      if (granted) {
        await _refreshHealthData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Permission wasn't granted. You can allow access from your "
              "phone's Health Connect / Health app settings any time.",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            backgroundColor: context.appSurfaceVariant,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not connect to health data: ${e.toString()}',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            backgroundColor: AppTheme.error,
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh as soon as the user comes back from the Health / Health
    // Connect app (or backgrounds and returns), so numbers feel live rather
    // than stale.
    if (state == AppLifecycleState.resumed) {
      _refreshCalories();
      if (_isConnected) _refreshHealthData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: context.appSurface,
          onRefresh: () async {
            await _refreshCalories();
            if (_isConnected) {
              await _refreshHealthData();
            } else {
              await Future.delayed(const Duration(milliseconds: 400));
            }
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
                        child: Text(
                          'My Statistic',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.appSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Connect Health Data banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _HealthConnectBanner(
                    isConnected: _isConnected,
                    isConnecting: _isConnecting,
                    onConnectTap: _handleConnectTap,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Metric tab selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: MetricTabSelectorWidget(
                    selectedIndex: _selectedMetric,
                    onTabSelected: (i) => setState(() => _selectedMetric = i),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Step ring / metric display
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: StepRingWidget(
                    selectedMetric: _selectedMetric,
                    summary: _summary,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Bar chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ActivityBarChartWidget(
                    selectedMetric: _selectedMetric,
                    dailySteps: _dailySteps,
                    dailyCalories: _dailyCalories,
                    dailyActiveMinutes: _dailyActiveMinutes,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Recent workouts header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Workouts',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        'See All',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Workout history cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: WorkoutHistoryCardWidget(
                        workoutData: _workoutHistory[i],
                      ),
                    ),
                    childCount: _workoutHistory.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final List<Map<String, dynamic>> _workoutHistory = [
    {
      'name': 'Spin Bike Program',
      'date': '08 Aug 2026',
      'duration': '30 Min',
      'reps': '4×30 reps',
      'calories': '802 Kcal',
      'heartRate': '99 Bpm',
      'bpm': '18 Bpm',
    },
    {
      'name': 'Running Program',
      'date': '07 Aug 2026',
      'duration': '45 Min',
      'reps': '5.2 km',
      'calories': '634 Kcal',
      'heartRate': '142 Bpm',
      'bpm': '22 Bpm',
    },
    {
      'name': 'Upper Body Strength',
      'date': '06 Aug 2026',
      'duration': '55 Min',
      'reps': '6 exercises',
      'calories': '410 Kcal',
      'heartRate': '118 Bpm',
      'bpm': '14 Bpm',
    },
    {
      'name': 'HIIT Cardio',
      'date': '04 Aug 2026',
      'duration': '25 Min',
      'reps': '8 rounds',
      'calories': '520 Kcal',
      'heartRate': '161 Bpm',
      'bpm': '28 Bpm',
    },
  ];
}

class _HealthConnectBanner extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onConnectTap;

  const _HealthConnectBanner({
    required this.isConnected,
    required this.isConnecting,
    required this.onConnectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(
            isConnected
                ? Icons.check_circle_outline_rounded
                : Icons.health_and_safety_outlined,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isConnected
                  ? 'Synced live with Health / Health Connect'
                  : 'Connect Health Data for live step tracking',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: context.appTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!isConnected)
            InkWell(
              onTap: isConnecting ? null : onConnectTap,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: isConnecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1A1A1A),
                        ),
                      )
                    : Text(
                        'Connect',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
