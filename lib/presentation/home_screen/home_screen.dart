import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import './widgets/activity_card_grid_widget.dart';
import './widgets/health_score_ring_widget.dart';
import './widgets/metric_cards_row_widget.dart';
import './widgets/recommendations_widget.dart';
import './widgets/week_day_selector_widget.dart';
import './widgets/workout_progress_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: Replace with [Riverpod/Bloc] for production
  final String _userName = 'Ram';
  final int _selectedDayIndex = 2; // Wednesday

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
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
                            '${_getGreeting()}, $_userName 👋',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: context.appTextPrimary,
                            ),
                          ),
                          Text(
                            _formatDate(),
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification bell
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.appSurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: context.appTextPrimary,
                            size: 22,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha(128),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: context.appSurfaceVariant,
                            child: Icon(
                              Icons.person_rounded,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Health Score Ring
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: isTablet
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(child: HealthScoreRingWidget()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTabletSidebar()),
                        ],
                      )
                    : const HealthScoreRingWidget(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Metric Cards
            if (!isTablet)
              const SliverToBoxAdapter(child: MetricCardsRowWidget()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Training Plan section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Training Plan',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                    Icon(
                      Icons.notifications_outlined,
                      color: context.appTextSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: WeekDaySelectorWidget(
                selectedIndex: _selectedDayIndex,
                onDaySelected: (i) => setState(() {}),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: WorkoutProgressCardWidget(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // My Activity
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Activity',
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
            const SliverToBoxAdapter(child: ActivityCardGridWidget()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Recommendations
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: RecommendationsWidget(),
              ),
            ),
            // Bottom nav padding
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletSidebar() {
    return const MetricCardsRowWidget(vertical: true);
  }

  String _formatDate() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
