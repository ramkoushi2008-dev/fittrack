import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _ActivityScreenState extends State<ActivityScreen> {
  // TODO: Replace with [Riverpod/Bloc] for production
  int _selectedMetric = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
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
                        child: Text(
                          'My Statistic',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          color: AppTheme.textSecondary,
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
                  child: _HealthConnectBanner(),
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
                  child: StepRingWidget(selectedMetric: _selectedMetric),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Bar chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ActivityBarChartWidget(
                    selectedMetric: _selectedMetric,
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
                          color: AppTheme.textPrimary,
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
          const Icon(
            Icons.health_and_safety_outlined,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Connect Health Data for live step tracking',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              'Connect',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
