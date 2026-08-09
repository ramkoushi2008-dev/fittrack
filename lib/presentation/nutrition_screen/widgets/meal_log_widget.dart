import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/empty_state_widget.dart';

class MealLogWidget extends StatelessWidget {
  final int mealIndex;
  final List<Map<String, dynamic>> foods;
  final Function(int) onRemoveFood;

  const MealLogWidget({
    required this.mealIndex,
    required this.foods,
    required this.onRemoveFood,
    super.key,
  });

  int get _totalCalories =>
      foods.fold(0, (sum, f) => sum + (f['calories'] as int));
  int get _totalProtein =>
      foods.fold(0, (sum, f) => sum + (f['protein'] as int));

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: EmptyStateWidget(
          icon: Icons.restaurant_outlined,
          title: 'No foods logged yet',
          subtitle: 'Tap "+ Log Food" to add what you\'ve eaten in this meal.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        children: [
          // Meal totals
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _TotalChip(
                  label: 'Total Calories',
                  value: '$_totalCalories kcal',
                  color: AppTheme.caloriesColor,
                ),
                const SizedBox(width: 12),
                _TotalChip(
                  label: 'Total Protein',
                  value: '$_totalProtein g',
                  color: AppTheme.proteinColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Food items
          ...foods.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: Key('food_${mealIndex}_${entry.key}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(51),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                  ),
                ),
                onDismissed: (_) => onRemoveFood(entry.key),
                child: _FoodLogCard(food: entry.value),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TotalChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.textMuted),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodLogCard extends StatelessWidget {
  final Map<String, dynamic> food;
  const _FoodLogCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.caloriesColor.withAlpha(31),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppTheme.caloriesColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food['name'] as String,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  food['portion'] as String,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${food['calories']} kcal',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.caloriesColor,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'P: ${food['protein']}g  C: ${food['carbs']}g  F: ${food['fat']}g',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
