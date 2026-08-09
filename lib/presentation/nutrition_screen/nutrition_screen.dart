import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import './widgets/food_input_sheet_widget.dart';
import './widgets/macro_summary_widget.dart';
import './widgets/meal_log_widget.dart';
import './widgets/protein_progress_card_widget.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with [Riverpod/Bloc] for production
  late TabController _tabController;
  int _selectedMeal = 0;

  // Protein tracking state
  int _proteinConsumed = 82;
  static const int _proteinTarget = 120;

  static const List<String> _mealTabs = [
    'Breakfast',
    'Lunch',
    'Snack',
    'Dinner',
  ];

  // Mock food log data
  static final Map<int, List<Map<String, dynamic>>> _foodLogs = {
    0: [
      {
        'name': '3 Boiled Eggs',
        'calories': 210,
        'protein': 18,
        'carbs': 2,
        'fat': 15,
        'portion': '3 eggs',
      },
      {
        'name': '2 Whole Wheat Chapati',
        'calories': 180,
        'protein': 6,
        'carbs': 36,
        'fat': 3,
        'portion': '2 pieces',
      },
      {
        'name': 'Greek Yogurt',
        'calories': 120,
        'protein': 12,
        'carbs': 8,
        'fat': 4,
        'portion': '1 cup (200g)',
      },
    ],
    1: [
      {
        'name': 'Dal Tadka',
        'calories': 280,
        'protein': 14,
        'carbs': 42,
        'fat': 6,
        'portion': '1 bowl',
      },
      {
        'name': 'Brown Rice',
        'calories': 215,
        'protein': 5,
        'carbs': 44,
        'fat': 2,
        'portion': '1 cup cooked',
      },
      {
        'name': 'Paneer Bhurji',
        'calories': 320,
        'protein': 22,
        'carbs': 8,
        'fat': 22,
        'portion': '150g',
      },
    ],
    2: [
      {
        'name': 'Banana',
        'calories': 89,
        'protein': 1,
        'carbs': 23,
        'fat': 0,
        'portion': '1 medium',
      },
      {
        'name': 'Roasted Chana',
        'calories': 164,
        'protein': 9,
        'carbs': 27,
        'fat': 3,
        'portion': '50g',
      },
    ],
    3: [
      {
        'name': 'Grilled Chicken Breast',
        'calories': 165,
        'protein': 31,
        'carbs': 0,
        'fat': 4,
        'portion': '100g',
      },
      {
        'name': 'Sautéed Vegetables',
        'calories': 80,
        'protein': 3,
        'carbs': 14,
        'fat': 2,
        'portion': '1 cup',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mealTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedMeal = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFoodInputSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FoodInputSheetWidget(
        onFoodLogged: (foodEntry) {
          setState(() {
            _foodLogs[_selectedMeal]!.add(foodEntry);
          });
        },
      ),
    );
  }

  void _removeFood(int mealIndex, int foodIndex) {
    setState(() {
      _foodLogs[mealIndex]!.removeAt(foodIndex);
    });
  }

  void _onProteinAdded(int amount) {
    setState(() {
      _proteinConsumed = (_proteinConsumed + amount).clamp(
        0,
        _proteinTarget + 50,
      );
    });
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
                  Expanded(
                    child: Text(
                      'Nutrition',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Today',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Scrollable content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Macro summary
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: MacroSummaryWidget(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Protein card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ProteinProgressCardWidget(
                        consumed: _proteinConsumed,
                        target: _proteinTarget,
                        onProteinAdded: _onProteinAdded,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Disclaimer
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariantDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Nutrition values are estimates. Actual values may vary based on portion size and preparation method.',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Meal tabs
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _MealTabDelegate(
                      tabController: _tabController,
                      tabs: _mealTabs,
                    ),
                  ),

                  // Food log
                  SliverToBoxAdapter(
                    child: MealLogWidget(
                      mealIndex: _selectedMeal,
                      foods: _foodLogs[_selectedMeal] ?? [],
                      onRemoveFood: (foodIndex) =>
                          _removeFood(_selectedMeal, foodIndex),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFoodInputSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: const Color(0xFF1A1A1A),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Log Food',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}

class _MealTabDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<String> tabs;

  _MealTabDelegate({required this.tabController, required this.tabs});

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.backgroundDark,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(50),
        ),
        child: TabBar(
          controller: tabController,
          indicator: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(50),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          labelColor: const Color(0xFF1A1A1A),
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_MealTabDelegate old) =>
      old.tabController != tabController;
}
