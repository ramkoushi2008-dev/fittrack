import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ProteinProgressCardWidget extends StatefulWidget {
  final int consumed;
  final int target;
  final ValueChanged<int>? onProteinAdded;

  const ProteinProgressCardWidget({
    super.key,
    this.consumed = 82,
    this.target = 120,
    this.onProteinAdded,
  });

  @override
  State<ProteinProgressCardWidget> createState() =>
      _ProteinProgressCardWidgetState();
}

class _ProteinProgressCardWidgetState extends State<ProteinProgressCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _calcController;
  late Animation<double> _expandAnimation;
  late Animation<double> _calcAnimation;

  bool _isExpanded = false;
  bool _isCalcExpanded = false;

  // Available food selection
  final List<String> _allFoods = [
    'Chicken',
    'Eggs',
    'Paneer',
    'Dal',
    'Milk',
    'Greek Yogurt',
    'Soy Chunks',
    'Fish',
    'Tofu',
    'Curd',
    'Whey Protein',
    'Chickpeas',
  ];
  final Set<String> _availableFoods = {'Eggs', 'Paneer', 'Dal', 'Milk', 'Curd'};
  bool _showFoodPicker = false;

  // Protein calculator state
  final TextEditingController _calcController2 = TextEditingController();
  String? _selectedCalcFood;
  double _calcGrams = 100;
  int _calcProtein = 0;
  late int _currentConsumed;

  // Food protein data (per 100g)
  static const Map<String, Map<String, dynamic>> _foodData = {
    'Chicken': {
      'protein_per_100g': 31,
      'icon': Icons.set_meal_rounded,
      'color': AppTheme.caloriesColor,
      'unit': 'g',
    },
    'Eggs': {
      'protein_per_100g': 13,
      'icon': Icons.egg_outlined,
      'color': AppTheme.proteinColor,
      'unit': 'g',
      'per_piece': 6,
      'piece_weight': 50,
    },
    'Paneer': {
      'protein_per_100g': 18,
      'icon': Icons.restaurant_rounded,
      'color': AppTheme.proteinColor,
      'unit': 'g',
    },
    'Dal': {
      'protein_per_100g': 9,
      'icon': Icons.soup_kitchen_rounded,
      'color': AppTheme.workoutColor,
      'unit': 'g',
    },
    'Milk': {
      'protein_per_100g': 3.4,
      'icon': Icons.local_drink_rounded,
      'color': AppTheme.stepsColor,
      'unit': 'ml',
    },
    'Greek Yogurt': {
      'protein_per_100g': 10,
      'icon': Icons.local_dining_rounded,
      'color': AppTheme.sleepColor,
      'unit': 'g',
    },
    'Soy Chunks': {
      'protein_per_100g': 52,
      'icon': Icons.grain_rounded,
      'color': AppTheme.stepsColor,
      'unit': 'g',
    },
    'Fish': {
      'protein_per_100g': 26,
      'icon': Icons.set_meal_rounded,
      'color': AppTheme.stepsColor,
      'unit': 'g',
    },
    'Tofu': {
      'protein_per_100g': 8,
      'icon': Icons.restaurant_menu_rounded,
      'color': AppTheme.sleepColor,
      'unit': 'g',
    },
    'Curd': {
      'protein_per_100g': 3.5,
      'icon': Icons.local_dining_rounded,
      'color': AppTheme.proteinColor,
      'unit': 'g',
    },
    'Whey Protein': {
      'protein_per_100g': 80,
      'icon': Icons.fitness_center_rounded,
      'color': AppTheme.workoutColor,
      'unit': 'g',
    },
    'Chickpeas': {
      'protein_per_100g': 19,
      'icon': Icons.grain_rounded,
      'color': AppTheme.caloriesColor,
      'unit': 'g',
    },
  };

  @override
  void initState() {
    super.initState();
    _currentConsumed = widget.consumed;

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _calcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _calcAnimation = CurvedAnimation(
      parent: _calcController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _calcController.dispose();
    _calcController2.dispose();
    super.dispose();
  }

  int get _remaining =>
      (widget.target - _currentConsumed).clamp(0, widget.target);
  double get _progress => (_currentConsumed / widget.target).clamp(0.0, 1.0);

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
      if (_isCalcExpanded) {
        setState(() => _isCalcExpanded = false);
        _calcController.reverse();
      }
    }
  }

  void _toggleCalc() {
    setState(() => _isCalcExpanded = !_isCalcExpanded);
    if (_isCalcExpanded) {
      _calcController.forward();
    } else {
      _calcController.reverse();
    }
  }

  List<Map<String, dynamic>> _getRecommendations() {
    final remaining = _remaining;
    final available = _availableFoods.toList();
    final recs = <Map<String, dynamic>>[];

    for (final food in available) {
      final data = _foodData[food];
      if (data == null) continue;
      final proteinPer100g = (data['protein_per_100g'] as num).toDouble();
      if (proteinPer100g <= 0) continue;

      // Calculate how many grams needed to cover remaining protein
      final gramsNeeded = (remaining / proteinPer100g * 100).round();
      final proteinIn100g = proteinPer100g.round();

      String suggestion;
      if (food == 'Eggs') {
        final eggs = (remaining / 6.0).ceil();
        suggestion =
            '$eggs egg${eggs > 1 ? 's' : ''} (~${(eggs * 6)}g protein)';
      } else if (gramsNeeded <= 150) {
        suggestion = '${gramsNeeded}g → ~${remaining}g protein';
      } else {
        // Show what 100g gives
        suggestion = '100g → ~${proteinIn100g}g protein';
      }

      recs.add({
        'food': food,
        'suggestion': suggestion,
        'protein': proteinIn100g,
        'icon': data['icon'],
        'color': data['color'],
      });
    }

    recs.sort((a, b) => (b['protein'] as int).compareTo(a['protein'] as int));
    return recs.take(5).toList();
  }

  void _updateCalcProtein() {
    if (_selectedCalcFood == null) return;
    final data = _foodData[_selectedCalcFood!];
    if (data == null) return;
    final proteinPer100g = (data['protein_per_100g'] as num).toDouble();
    setState(() {
      _calcProtein = (proteinPer100g * _calcGrams / 100).round();
    });
  }

  void _consumeProtein() {
    if (_calcProtein <= 0) return;
    setState(() {
      _currentConsumed = (_currentConsumed + _calcProtein).clamp(
        0,
        widget.target + 50,
      );
      _calcProtein = 0;
      _calcGrams = 100;
      _selectedCalcFood = null;
      _calcController2.clear();
    });
    widget.onProteinAdded?.call(_calcProtein);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.proteinColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              '+$_calcProtein g protein added to today\'s intake!',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceVariantDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recs = _getRecommendations();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border(
          left: BorderSide(color: AppTheme.proteinColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (always visible, tappable) ──
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.proteinColor.withAlpha(38),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.egg_outlined,
                          color: AppTheme.proteinColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Protein',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_currentConsumed}g',
                                  style: GoogleFonts.manrope(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.proteinColor,
                                    fontFeatures: [
                                      const FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Text(
                                  ' / ${widget.target}g',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    fontFeatures: [
                                      const FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.proteinColor.withAlpha(38),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _remaining > 0
                              ? '${_remaining}g left'
                              : '✓ Goal met!',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.proteinColor,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: AppTheme.proteinColor.withAlpha(38),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.proteinColor,
                      ),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Collapsible section ──
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Divider
                Divider(
                  height: 1,
                  color: AppTheme.surfaceVariantDark,
                  indent: 20,
                  endIndent: 20,
                ),
                const SizedBox(height: 16),

                // "What to eat today" header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 16,
                        color: AppTheme.proteinColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _remaining > 0
                              ? 'Eat today to hit your goal (${_remaining}g left)'
                              : 'You\'ve hit your protein goal! 🎉',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      // Edit available foods
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showFoodPicker = !_showFoodPicker),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariantDark,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _showFoodPicker
                                    ? Icons.close_rounded
                                    : Icons.tune_rounded,
                                size: 12,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _showFoodPicker ? 'Done' : 'My foods',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Food picker (available foods selection)
                if (_showFoodPicker) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select foods you have available:',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allFoods.map((food) {
                            final isSelected = _availableFoods.contains(food);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _availableFoods.remove(food);
                                  } else {
                                    _availableFoods.add(food);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.proteinColor.withAlpha(38)
                                      : AppTheme.surfaceVariantDark,
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.proteinColor.withAlpha(120)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  food,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.proteinColor
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: AppTheme.surfaceVariantDark),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],

                // Recommendations list
                if (_remaining > 0 && recs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: recs.map((rec) {
                        final color = rec['color'] as Color;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: color.withAlpha(18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withAlpha(50)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(38),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  rec['icon'] as IconData,
                                  size: 15,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rec['food'] as String,
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      rec['suggestion'] as String,
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(38),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  '${rec['protein']}g/100g',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                else if (_availableFoods.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tap "My foods" to select what you have available.',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Protein Calculator toggle ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _toggleCalc,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isCalcExpanded
                              ? AppTheme.proteinColor.withAlpha(100)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.proteinColor.withAlpha(38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calculate_rounded,
                              size: 16,
                              color: AppTheme.proteinColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Protein Calculator',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isCalcExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Calculator expanded section ──
                SizeTransition(
                  sizeFactor: _calcAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select food & quantity',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Food dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF3A3A3A),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCalcFood,
                                hint: Text(
                                  'Choose a food...',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                isExpanded: true,
                                dropdownColor: AppTheme.surfaceDark,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 18,
                                ),
                                items: _foodData.keys.map((food) {
                                  final data = _foodData[food]!;
                                  return DropdownMenuItem<String>(
                                    value: food,
                                    child: Row(
                                      children: [
                                        Icon(
                                          data['icon'] as IconData,
                                          size: 14,
                                          color: data['color'] as Color,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          food,
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${(data['protein_per_100g'] as num).toStringAsFixed(0)}g/100g',
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCalcFood = val;
                                    _calcGrams = 100;
                                    _calcController2.text = '100';
                                  });
                                  _updateCalcProtein();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Grams input + slider
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Amount (${_selectedCalcFood != null ? (_foodData[_selectedCalcFood!]?['unit'] ?? 'g') : 'g'})',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _calcController2,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                        hintText: '100',
                                        hintStyle: GoogleFonts.manrope(
                                          color: AppTheme.textMuted,
                                          fontSize: 13,
                                        ),
                                        filled: true,
                                        fillColor: AppTheme.surfaceDark,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF3A3A3A),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF3A3A3A),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.proteinColor,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        final parsed = double.tryParse(val);
                                        if (parsed != null && parsed > 0) {
                                          setState(
                                            () => _calcGrams = parsed.clamp(
                                              1,
                                              1000,
                                            ),
                                          );
                                          _updateCalcProtein();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Live protein result
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.proteinColor.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.proteinColor.withAlpha(80),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${_calcProtein}g',
                                      style: GoogleFonts.manrope(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.proteinColor,
                                        fontFeatures: [
                                          const FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'protein',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Slider for quick amount selection
                          if (_selectedCalcFood != null) ...[
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppTheme.proteinColor,
                                inactiveTrackColor: AppTheme.proteinColor
                                    .withAlpha(38),
                                thumbColor: AppTheme.proteinColor,
                                overlayColor: AppTheme.proteinColor.withAlpha(
                                  30,
                                ),
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                              ),
                              child: Slider(
                                value: _calcGrams.clamp(10, 500),
                                min: 10,
                                max: 500,
                                divisions: 49,
                                onChanged: (val) {
                                  setState(() {
                                    _calcGrams = val;
                                    _calcController2.text = val
                                        .round()
                                        .toString();
                                  });
                                  _updateCalcProtein();
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '10g',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                Text(
                                  '500g',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Consumed button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _calcProtein > 0
                                  ? _consumeProtein
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _calcProtein > 0
                                    ? AppTheme.proteinColor
                                    : AppTheme.surfaceDark,
                                foregroundColor: _calcProtein > 0
                                    ? const Color(0xFF1A1A1A)
                                    : AppTheme.textMuted,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.add_circle_rounded,
                                size: 18,
                              ),
                              label: Text(
                                _calcProtein > 0
                                    ? 'Mark as Consumed (+${_calcProtein}g)'
                                    : 'Select food & amount',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
