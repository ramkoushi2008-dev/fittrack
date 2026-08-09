import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class FoodInputSheetWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onFoodLogged;

  const FoodInputSheetWidget({required this.onFoodLogged, super.key});

  @override
  State<FoodInputSheetWidget> createState() => _FoodInputSheetWidgetState();
}

class _FoodInputSheetWidgetState extends State<FoodInputSheetWidget> {
  // TODO: Replace with [Riverpod/Bloc] for production
  final _controller = TextEditingController();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analyzedFood;

  // Mock food analysis
  final Map<String, Map<String, dynamic>> _foodDatabase = {
    'egg': {
      'name': 'Eggs',
      'calories': 70,
      'protein': 6,
      'carbs': 0,
      'fat': 5,
      'portion': '1 egg (50g)',
    },
    'chapati': {
      'name': 'Chapati',
      'calories': 90,
      'protein': 3,
      'carbs': 18,
      'fat': 2,
      'portion': '1 chapati (40g)',
    },
    'dal': {
      'name': 'Dal',
      'calories': 280,
      'protein': 14,
      'carbs': 42,
      'fat': 6,
      'portion': '1 bowl (200g)',
    },
    'chicken': {
      'name': 'Chicken Breast',
      'calories': 165,
      'protein': 31,
      'carbs': 0,
      'fat': 4,
      'portion': '100g',
    },
    'paneer': {
      'name': 'Paneer',
      'calories': 265,
      'protein': 18,
      'carbs': 4,
      'fat': 20,
      'portion': '100g',
    },
    'rice': {
      'name': 'Rice',
      'calories': 215,
      'protein': 4,
      'carbs': 46,
      'fat': 0,
      'portion': '1 cup cooked',
    },
  };

  Future<void> _analyzeFood() async {
    if (_controller.text.isEmpty) return;
    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    // Simple keyword matching for mock analysis
    final input = _controller.text.toLowerCase();
    Map<String, dynamic>? found;
    for (final key in _foodDatabase.keys) {
      if (input.contains(key)) {
        found = Map<String, dynamic>.from(_foodDatabase[key]!);
        break;
      }
    }

    // Default if not found
    found ??= {
      'name': _controller.text.trim(),
      'calories': 250,
      'protein': 8,
      'carbs': 30,
      'fat': 10,
      'portion': '1 serving (estimated)',
    };

    setState(() {
      _isAnalyzing = false;
      _analyzedFood = found;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Log Food',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Describe what you ate in natural language',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // Input field
          TextFormField(
            controller: _controller,
            style: GoogleFonts.manrope(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. "3 eggs, 2 chapatis and a bowl of dal"',
              hintStyle: GoogleFonts.manrope(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeFood,
              child: _isAnalyzing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Analyzing...',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : const Text('Analyze Food'),
            ),
          ),
          // Analyzed result
          if (_analyzedFood != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withAlpha(77)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Estimated nutrition values',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _analyzedFood!['name'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _analyzedFood!['portion'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NutrientBadge(
                        label: 'Cal',
                        value: '${_analyzedFood!['calories']}',
                        color: AppTheme.caloriesColor,
                      ),
                      _NutrientBadge(
                        label: 'Protein',
                        value: '${_analyzedFood!['protein']}g',
                        color: AppTheme.proteinColor,
                      ),
                      _NutrientBadge(
                        label: 'Carbs',
                        value: '${_analyzedFood!['carbs']}g',
                        color: AppTheme.stepsColor,
                      ),
                      _NutrientBadge(
                        label: 'Fat',
                        value: '${_analyzedFood!['fat']}g',
                        color: AppTheme.sleepColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onFoodLogged(_analyzedFood!);
                        Navigator.pop(context);
                      },
                      child: const Text('Add to Log'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NutrientBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _NutrientBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
