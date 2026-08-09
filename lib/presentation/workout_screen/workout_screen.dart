import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
import './widgets/workout_day_header_widget.dart';
import './workout_active_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _selectedDayIndex = 0;
  bool _isLoading = true;

  // Derived from questionnaire answers
  String _experience = 'Beginner';
  List<String> _goals = ['Improve Fitness'];
  String _preference = 'Gym';
  List<String> _equipment = ['No Equipment'];
  int _daysPerWeek = 4;

  late List<Map<String, dynamic>> _weekPlan;
  late Map<int, List<Map<String, dynamic>>> _dayExercises;
  late List<Map<String, dynamic>> _exercises;

  @override
  void initState() {
    super.initState();
    _weekPlan = [];
    _dayExercises = {};
    _exercises = [];
    _loadPersonalizedPlan();
  }

  Future<void> _loadPersonalizedPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('questionnaire_answers');
      if (raw != null) {
        final Map<String, dynamic> saved = jsonDecode(raw) as Map<String, dynamic>;

        _experience = saved['experience'] as String? ?? 'Beginner';
        _preference = saved['preference'] as String? ?? 'Gym';
        _daysPerWeek = int.tryParse(saved['daysPerWeek']?.toString() ?? '4') ?? 4;

        // Goals are stored as JSON-encoded list
        final goalsRaw = saved['goals_2'] as String?;
        if (goalsRaw != null) {
          _goals = List<String>.from(jsonDecode(goalsRaw) as List);
        }

        // Equipment is stored as JSON-encoded list
        final equipRaw = saved['goals_5'] as String?;
        if (equipRaw != null) {
          _equipment = List<String>.from(jsonDecode(equipRaw) as List);
        }
      }
    } catch (_) {}

    _buildPersonalizedPlan();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _buildPersonalizedPlan() {
    // ── Build week schedule based on daysPerWeek ──────────────────────────
    final allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final bool isBodyweight = _preference == 'Bodyweight' ||
        _equipment.contains('No Equipment') ||
        (_preference == 'Home' && !_equipment.any((e) =>
            e == 'Dumbbells' || e == 'Barbells' || e == 'Machines'));
    final bool isStrength = _goals.any((g) =>
        g == 'Increase Strength' || g == 'Build Muscle');
    final bool isCardio = _goals.any((g) =>
        g == 'Improve Endurance' || g == 'Improve Fitness' || g == 'Lose Fat');

    // Determine muscle split based on days
    final List<String> labels = _buildDayLabels(isBodyweight, isStrength, isCardio);

    _weekPlan = [];
    _dayExercises = {};

    int workoutDayCount = 0;
    for (int i = 0; i < 7; i++) {
      final bool isRest = workoutDayCount >= _daysPerWeek;
      _weekPlan.add({
        'day': allDays[i],
        'label': isRest ? 'Rest Day' : labels[workoutDayCount % labels.length],
        'isRest': isRest,
      });
      if (!isRest) {
        _dayExercises[i] = _buildExercisesForLabel(
          labels[workoutDayCount % labels.length],
          isBodyweight,
        );
        workoutDayCount++;
      }
    }

    _loadExercisesForDay(0);
  }

  List<String> _buildDayLabels(bool isBodyweight, bool isStrength, bool isCardio) {
    if (_daysPerWeek <= 2) {
      return ['Full Body A', 'Full Body B'];
    } else if (_daysPerWeek == 3) {
      if (isBodyweight) return ['Push', 'Pull', 'Legs'];
      return ['Chest + Triceps', 'Back + Biceps', 'Legs'];
    } else if (_daysPerWeek == 4) {
      if (isBodyweight) return ['Push', 'Pull', 'Legs', 'Core + Cardio'];
      if (isCardio && !isStrength) {
        return ['Upper Body', 'HIIT Cardio', 'Lower Body', 'Cardio + Core'];
      }
      return ['Chest + Triceps', 'Back + Biceps', 'Legs', 'Shoulders + Core'];
    } else if (_daysPerWeek == 5) {
      if (isBodyweight) return ['Push', 'Pull', 'Legs', 'Core', 'Full Body'];
      return ['Chest', 'Back + Biceps', 'Legs', 'Shoulders', 'Arms + Core'];
    } else {
      // 6-7 days
      if (isBodyweight) return ['Push A', 'Pull A', 'Legs A', 'Push B', 'Pull B', 'Legs B'];
      return ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'HIIT Cardio'];
    }
  }

  List<Map<String, dynamic>> _buildExercisesForLabel(String label, bool isBodyweight) {
    final bool isAdv = _experience == 'Advanced';
    final bool isBeg = _experience == 'Beginner';
    final bool hasBarbells = _equipment.contains('Barbells') && !isBodyweight;
    final bool hasDumbbells = _equipment.contains('Dumbbells') && !isBodyweight;
    final bool hasBands = _equipment.contains('Resistance Bands');
    final bool hasPullupBar = _equipment.contains('Pull-up Bar');
    final bool hasMachines = _equipment.contains('Machines') && !isBodyweight;

    // Sets/reps based on experience & goal
    final bool isStrength = _goals.any((g) => g == 'Increase Strength' || g == 'Build Muscle');
    final bool isEndurance = _goals.any((g) => g == 'Improve Endurance' || g == 'Lose Fat');

    int baseSets = isBeg ? 3 : (isAdv ? 4 : 3);
    int baseReps = isStrength ? (isBeg ? 10 : (isAdv ? 6 : 8))
        : (isEndurance ? (isBeg ? 15 : (isAdv ? 20 : 15)) : 12);

    switch (label) {
      case 'Chest + Triceps':
      case 'Chest':
        return [
          if (hasBarbells) _ex('Barbell Bench Press', 'Chest', baseSets, baseReps, 90, isAdv ? 'Advanced' : (isBeg ? 'Beginner' : 'Intermediate'), Icons.fitness_center_rounded),
          if (hasDumbbells) _ex('Dumbbell Incline Press', 'Upper Chest', baseSets, baseReps, 75, isBeg ? 'Beginner' : 'Intermediate', Icons.fitness_center_rounded),
          if (isBodyweight || (!hasBarbells && !hasDumbbells)) _ex('Push-Ups', 'Chest', baseSets, baseReps + 3, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (isBodyweight) _ex('Wide Push-Ups', 'Outer Chest', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasMachines) _ex('Cable Flyes', 'Chest', baseSets, baseReps + 3, 60, 'Beginner', Icons.cable_rounded),
          if (hasDumbbells) _ex('Dumbbell Flyes', 'Chest', baseSets, baseReps + 3, 60, 'Beginner', Icons.fitness_center_rounded),
          if (hasBarbells || hasDumbbells) _ex('Skull Crushers', 'Triceps', baseSets, baseReps, 75, isBeg ? 'Beginner' : 'Intermediate', Icons.fitness_center_rounded),
          if (isBodyweight || hasBands) _ex('Tricep Dips', 'Triceps', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasMachines) _ex('Tricep Pushdown', 'Triceps', baseSets, baseReps + 3, 60, 'Beginner', Icons.cable_rounded),
        ].take(5).toList();

      case 'Back + Biceps':
      case 'Back':
        return [
          if (hasBarbells) _ex('Deadlift', 'Back', isAdv ? 4 : 3, isAdv ? 5 : 8, 120, isAdv ? 'Advanced' : 'Intermediate', Icons.fitness_center_rounded),
          if (hasPullupBar || isBodyweight) _ex('Pull-Ups', 'Lats', baseSets, isBeg ? 6 : baseReps, 90, isBeg ? 'Intermediate' : 'Advanced', Icons.sports_gymnastics_rounded),
          if (hasMachines) _ex('Seated Cable Row', 'Mid Back', baseSets, baseReps, 75, 'Beginner', Icons.cable_rounded),
          if (hasDumbbells) _ex('Dumbbell Row', 'Mid Back', baseSets, baseReps, 75, 'Beginner', Icons.fitness_center_rounded),
          if (isBodyweight && !hasPullupBar) _ex('Inverted Rows', 'Back', baseSets, baseReps, 75, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasBarbells || hasDumbbells) _ex('Barbell Curl', 'Biceps', baseSets, baseReps, 60, 'Beginner', Icons.fitness_center_rounded),
          if (hasDumbbells) _ex('Hammer Curl', 'Biceps', baseSets, baseReps, 60, 'Beginner', Icons.fitness_center_rounded),
          if (hasBands) _ex('Band Bicep Curl', 'Biceps', baseSets, baseReps + 3, 45, 'Beginner', Icons.sports_gymnastics_rounded),
        ].take(5).toList();

      case 'Legs':
      case 'Legs A':
      case 'Legs B':
        return [
          if (hasBarbells) _ex('Barbell Squat', 'Quads', isAdv ? 4 : 3, isAdv ? 6 : 10, 120, isAdv ? 'Advanced' : 'Intermediate', Icons.fitness_center_rounded),
          if (isBodyweight || !hasBarbells) _ex('Bodyweight Squat', 'Quads', baseSets, baseReps + 5, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasBarbells) _ex('Romanian Deadlift', 'Hamstrings', baseSets, baseReps, 90, 'Intermediate', Icons.fitness_center_rounded),
          if (hasDumbbells) _ex('Dumbbell Lunges', 'Quads', baseSets, baseReps, 75, 'Beginner', Icons.fitness_center_rounded),
          if (isBodyweight && !hasDumbbells) _ex('Reverse Lunges', 'Quads', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasMachines) _ex('Leg Press', 'Quads', baseSets, baseReps, 75, 'Beginner', Icons.fitness_center_rounded),
          if (hasMachines) _ex('Leg Curl', 'Hamstrings', baseSets, baseReps, 60, 'Beginner', Icons.fitness_center_rounded),
          _ex('Calf Raises', 'Calves', baseSets, 20, 45, 'Beginner', Icons.sports_gymnastics_rounded),
        ].take(5).toList();

      case 'Shoulders':
      case 'Shoulders + Core':
        return [
          if (hasBarbells || hasDumbbells) _ex(hasBarbells ? 'Overhead Press' : 'Dumbbell Shoulder Press', 'Shoulders', baseSets, baseReps, 90, isBeg ? 'Beginner' : 'Intermediate', Icons.fitness_center_rounded),
          if (isBodyweight && !hasDumbbells) _ex('Pike Push-Ups', 'Shoulders', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasDumbbells) _ex('Lateral Raises', 'Side Delts', baseSets, baseReps + 3, 60, 'Beginner', Icons.fitness_center_rounded),
          if (hasDumbbells) _ex('Front Raises', 'Front Delts', baseSets, baseReps, 60, 'Beginner', Icons.fitness_center_rounded),
          if (hasMachines) _ex('Face Pulls', 'Rear Delts', baseSets, baseReps + 3, 60, 'Beginner', Icons.cable_rounded),
          _ex('Plank', 'Core', baseSets, 30, 45, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Crunches', 'Core', baseSets, 20, 45, 'Beginner', Icons.sports_gymnastics_rounded),
        ].take(5).toList();

      case 'Push':
      case 'Push A':
      case 'Push B':
        return [
          if (hasBarbells) _ex('Bench Press', 'Chest', baseSets, baseReps, 90, isBeg ? 'Beginner' : 'Intermediate', Icons.fitness_center_rounded),
          _ex('Push-Ups', 'Chest', baseSets, baseReps + 3, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasDumbbells) _ex('Dumbbell Shoulder Press', 'Shoulders', baseSets, baseReps, 75, 'Beginner', Icons.fitness_center_rounded),
          if (isBodyweight && !hasDumbbells) _ex('Pike Push-Ups', 'Shoulders', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Tricep Dips', 'Triceps', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasDumbbells) _ex('Lateral Raises', 'Side Delts', baseSets, baseReps + 3, 45, 'Beginner', Icons.fitness_center_rounded),
        ].take(5).toList();

      case 'Pull':
      case 'Pull A':
      case 'Pull B':
        return [
          if (hasPullupBar) _ex('Pull-Ups', 'Lats', baseSets, isBeg ? 5 : baseReps, 90, isBeg ? 'Intermediate' : 'Advanced', Icons.sports_gymnastics_rounded),
          if (!hasPullupBar) _ex('Inverted Rows', 'Back', baseSets, baseReps, 75, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasDumbbells) _ex('Dumbbell Row', 'Mid Back', baseSets, baseReps, 75, 'Beginner', Icons.fitness_center_rounded),
          if (hasBands) _ex('Band Pull-Apart', 'Rear Delts', baseSets, baseReps + 5, 45, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasDumbbells) _ex('Hammer Curl', 'Biceps', baseSets, baseReps, 60, 'Beginner', Icons.fitness_center_rounded),
          _ex('Superman Hold', 'Lower Back', baseSets, 15, 45, 'Beginner', Icons.sports_gymnastics_rounded),
        ].take(5).toList();

      case 'Full Body A':
      case 'Full Body B':
      case 'Full Body':
        return [
          if (hasBarbells) _ex('Barbell Squat', 'Quads', baseSets, baseReps, 90, isBeg ? 'Beginner' : 'Intermediate', Icons.fitness_center_rounded),
          if (isBodyweight || !hasBarbells) _ex('Bodyweight Squat', 'Quads', baseSets, baseReps + 5, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Push-Ups', 'Chest', baseSets, baseReps + 3, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasPullupBar) _ex('Pull-Ups', 'Back', baseSets, isBeg ? 5 : baseReps, 75, 'Intermediate', Icons.sports_gymnastics_rounded),
          if (!hasPullupBar) _ex('Inverted Rows', 'Back', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Plank', 'Core', baseSets, 30, 45, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Reverse Lunges', 'Legs', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
        ].take(5).toList();

      case 'Upper Body':
        return [
          _ex('Push-Ups', 'Chest', baseSets, baseReps + 3, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasDumbbells) _ex('Dumbbell Row', 'Back', baseSets, baseReps, 75, 'Beginner', Icons.fitness_center_rounded),
          if (!hasDumbbells) _ex('Inverted Rows', 'Back', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasDumbbells) _ex('Dumbbell Shoulder Press', 'Shoulders', baseSets, baseReps, 75, 'Beginner', Icons.fitness_center_rounded),
          _ex('Tricep Dips', 'Triceps', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasDumbbells) _ex('Bicep Curl', 'Biceps', baseSets, baseReps, 60, 'Beginner', Icons.fitness_center_rounded),
        ].take(5).toList();

      case 'Lower Body':
        return [
          if (hasBarbells) _ex('Barbell Squat', 'Quads', baseSets, baseReps, 90, 'Intermediate', Icons.fitness_center_rounded),
          if (!hasBarbells) _ex('Bodyweight Squat', 'Quads', baseSets, baseReps + 5, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Reverse Lunges', 'Quads', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          if (hasDumbbells) _ex('Romanian Deadlift', 'Hamstrings', baseSets, baseReps, 75, 'Intermediate', Icons.fitness_center_rounded),
          _ex('Glute Bridge', 'Glutes', baseSets, baseReps + 3, 45, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Calf Raises', 'Calves', baseSets, 20, 45, 'Beginner', Icons.sports_gymnastics_rounded),
        ].take(5).toList();

      case 'HIIT Cardio':
      case 'Cardio + Core':
        return [
          _ex('Burpees', 'Full Body', baseSets, isBeg ? 8 : (isAdv ? 20 : 12), 45, isAdv ? 'Advanced' : 'Intermediate', Icons.sports_gymnastics_rounded),
          _ex('Jump Squats', 'Legs', baseSets, isBeg ? 10 : 15, 30, 'Intermediate', Icons.sports_gymnastics_rounded),
          _ex('Mountain Climbers', 'Core', baseSets, isBeg ? 15 : 20, 30, 'Intermediate', Icons.sports_gymnastics_rounded),
          _ex('High Knees', 'Cardio', baseSets, 30, 30, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Plank', 'Core', baseSets, 30, 30, 'Beginner', Icons.sports_gymnastics_rounded),
        ];

      case 'Core':
        return [
          _ex('Plank', 'Core', baseSets, 40, 45, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Crunches', 'Abs', baseSets, 20, 45, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Leg Raises', 'Lower Abs', baseSets, 15, 45, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Russian Twists', 'Obliques', baseSets, 20, 45, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Mountain Climbers', 'Core', baseSets, 20, 30, 'Intermediate', Icons.sports_gymnastics_rounded),
        ];

      case 'Arms + Core':
        return [
          if (hasDumbbells || hasBarbells) _ex('Barbell Curl', 'Biceps', baseSets, baseReps, 60, 'Beginner', Icons.fitness_center_rounded),
          if (hasDumbbells) _ex('Hammer Curl', 'Biceps', baseSets, baseReps, 60, 'Beginner', Icons.fitness_center_rounded),
          if (hasBarbells || hasDumbbells) _ex('Skull Crushers', 'Triceps', baseSets, baseReps, 75, 'Intermediate', Icons.fitness_center_rounded),
          _ex('Tricep Dips', 'Triceps', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Plank', 'Core', baseSets, 40, 45, 'Beginner', Icons.sports_gymnastics_rounded),
        ].take(5).toList();

      default:
        return [
          _ex('Push-Ups', 'Chest', baseSets, baseReps + 3, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Bodyweight Squat', 'Quads', baseSets, baseReps + 5, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Plank', 'Core', baseSets, 30, 45, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Reverse Lunges', 'Legs', baseSets, baseReps, 60, 'Beginner', Icons.sports_gymnastics_rounded),
          _ex('Mountain Climbers', 'Core', baseSets, 20, 30, 'Intermediate', Icons.sports_gymnastics_rounded),
        ];
    }
  }

  Map<String, dynamic> _ex(String name, String muscle, int sets, int reps,
      int restSec, String difficulty, IconData icon) {
    return {
      'name': name,
      'muscleGroup': muscle,
      'sets': sets,
      'reps': reps,
      'restSec': restSec,
      'difficulty': difficulty,
      'icon': icon,
    };
  }

  void _loadExercisesForDay(int dayIndex) {
    final templates = _dayExercises[dayIndex] ?? [];
    _exercises = templates.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  void _onDayChanged(int index) {
    setState(() {
      _selectedDayIndex = index;
      _loadExercisesForDay(index);
    });
  }

  void _adjustSets(int index, int delta) {
    setState(() {
      final current = _exercises[index]['sets'] as int;
      _exercises[index]['sets'] = (current + delta).clamp(1, 10);
    });
  }

  void _adjustReps(int index, int delta) {
    setState(() {
      final current = _exercises[index]['reps'] as int;
      _exercises[index]['reps'] = (current + delta).clamp(1, 50);
    });
  }

  void _startWorkout(BuildContext context) {
    final currentDay = _weekPlan[_selectedDayIndex];
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => WorkoutActiveScreen(
          workoutLabel: currentDay['label'] as String,
          exercises: _exercises,
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  String _getPlanTagline() {
    if (_goals.contains('Build Muscle')) return 'Muscle Building Plan';
    if (_goals.contains('Lose Fat')) return 'Fat Loss Plan';
    if (_goals.contains('Increase Strength')) return 'Strength Plan';
    if (_goals.contains('Improve Endurance')) return 'Endurance Plan';
    return 'Personalized Plan';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final currentDay = _weekPlan.isNotEmpty ? _weekPlan[_selectedDayIndex] : <String, dynamic>{};
    final isRestDay = currentDay['isRest'] as bool? ?? true;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Workout Plan',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Adjust sets & reps, then tap Start',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getPlanTagline(),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Week day selector ─────────────────────────────────────────
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _weekPlan.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final day = _weekPlan[i];
                  final isSelected = i == _selectedDayIndex;
                  final isRest = day['isRest'] as bool;
                  return GestureDetector(
                    onTap: () => _onDayChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day['day'] as String,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF1A1A1A)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            isRest
                                ? Icons.self_improvement_rounded
                                : Icons.fitness_center_rounded,
                            size: 16,
                            color: isSelected
                                ? const Color(0xFF1A1A1A)
                                : isRest
                                ? AppTheme.sleepColor
                                : AppTheme.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Day header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: WorkoutDayHeaderWidget(
                dayPlan: currentDay,
                completedCount: 0,
                totalCount: _exercises.length,
              ),
            ),
            const SizedBox(height: 12),

            // ── Exercise plan list or rest day ────────────────────────────
            Expanded(
              child: isRestDay
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.self_improvement_rounded,
                            size: 64,
                            color: AppTheme.sleepColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Rest & Recover',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your muscles grow during rest.\nTake it easy today.',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      itemCount: _exercises.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        return _PlanExerciseCard(
                          exercise: _exercises[i],
                          onIncreaseSets: () => _adjustSets(i, 1),
                          onDecreaseSets: () => _adjustSets(i, -1),
                          onIncreaseReps: () => _adjustReps(i, 1),
                          onDecreaseReps: () => _adjustReps(i, -1),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // ── Start Workout bottom bar ──────────────────────────────────────────
      bottomSheet: isRestDay
          ? null
          : Container(
              color: AppTheme.backgroundDark,
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                MediaQuery.of(context).padding.bottom + 80,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Summary row
                  if (_exercises.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SummaryChip(
                            icon: Icons.layers_rounded,
                            label:
                                '${_exercises.fold(0, (s, e) => s + (e['sets'] as int))} total sets',
                          ),
                          const SizedBox(width: 10),
                          _SummaryChip(
                            icon: Icons.repeat_rounded,
                            label: '${_exercises.length} exercises',
                          ),
                          const SizedBox(width: 10),
                          _SummaryChip(
                            icon: Icons.timer_outlined,
                            label:
                                '~${(_exercises.fold(0, (s, e) => s + (e['sets'] as int) * ((e['restSec'] as int) + 45)) ~/ 60)} min',
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startWorkout(context),
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: Text(
                        'Start Workout',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: const Color(0xFF1A1A1A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan Exercise Card — shows assigned plan with inline +/- controls
// ─────────────────────────────────────────────────────────────────────────────
class _PlanExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onIncreaseSets;
  final VoidCallback onDecreaseSets;
  final VoidCallback onIncreaseReps;
  final VoidCallback onDecreaseReps;

  const _PlanExerciseCard({
    required this.exercise,
    required this.onIncreaseSets,
    required this.onDecreaseSets,
    required this.onIncreaseReps,
    required this.onDecreaseReps,
  });

  Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFFFFC107);
      case 'advanced':
        return const Color(0xFFFF5722);
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sets = exercise['sets'] as int;
    final reps = exercise['reps'] as int;
    final restSec = exercise['restSec'] as int;
    final difficulty = exercise['difficulty'] as String;
    final icon = exercise['icon'] as IconData;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceVariantDark, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + name + difficulty badge ──────────────────
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        exercise['muscleGroup'] as String,
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
                    color: _difficultyColor(difficulty).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    difficulty,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _difficultyColor(difficulty),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Divider ──────────────────────────────────────────────────
            Container(height: 1, color: AppTheme.surfaceVariantDark),
            const SizedBox(height: 14),

            // ── Sets & Reps adjusters ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _AdjusterTile(
                    label: 'Sets',
                    value: sets,
                    onIncrease: onIncreaseSets,
                    onDecrease: onDecreaseSets,
                    minValue: 1,
                    maxValue: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdjusterTile(
                    label: 'Reps',
                    value: reps,
                    onIncrease: onIncreaseReps,
                    onDecrease: onDecreaseReps,
                    minValue: 1,
                    maxValue: 50,
                  ),
                ),
                const SizedBox(width: 12),
                // Rest time (display only)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Rest',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${restSec}s',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Ideal plan hint ───────────────────────────────────────────
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Ideal plan: $sets sets × $reps reps',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Adjuster Tile — +/- stepper for sets or reps
// ─────────────────────────────────────────────────────────────────────────────
class _AdjusterTile extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final int minValue;
  final int maxValue;

  const _AdjusterTile({
    required this.label,
    required this.value,
    required this.onIncrease,
    required this.onDecrease,
    required this.minValue,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: value > minValue ? onDecrease : null,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: value > minValue
                        ? AppTheme.surfaceDark
                        : AppTheme.surfaceDark.withAlpha(80),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 14,
                    color: value > minValue
                        ? AppTheme.textPrimary
                        : AppTheme.textMuted,
                  ),
                ),
              ),
              Text(
                '$value',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: value < maxValue ? onIncrease : null,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: value < maxValue
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceDark.withAlpha(80),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 14,
                    color: value < maxValue
                        ? AppTheme.primary
                        : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary chip for bottom bar
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}