import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for a single set
// ─────────────────────────────────────────────────────────────────────────────
class ExerciseSet {
  int reps;
  double weight; // kg
  bool done;
  ExerciseSet({this.reps = 0, this.weight = 0, this.done = false});
}

class ActiveExercise {
  final String name;
  final String muscleGroup;
  final IconData icon;
  final int defaultRestSec;
  final double suggestedWeight;
  List<ExerciseSet> sets;

  ActiveExercise({
    required this.name,
    required this.muscleGroup,
    required this.icon,
    required this.defaultRestSec,
    required int numSets,
    int defaultReps = 0,
    this.suggestedWeight = 0,
  }) : sets = List.generate(
         numSets,
         (_) => ExerciseSet(reps: defaultReps, weight: suggestedWeight),
       );
}

// ─────────────────────────────────────────────────────────────────────────────
// Weight suggestion logic
// ─────────────────────────────────────────────────────────────────────────────
double _suggestWeight(String exerciseName, String experience) {
  final name = exerciseName.toLowerCase();
  final isAdv = experience == 'Advanced';
  final isBeg = experience == 'Beginner';

  // Bodyweight exercises → 0 kg
  const bodyweightKeywords = [
    'push-up',
    'push up',
    'pull-up',
    'pull up',
    'dip',
    'squat',
    'lunge',
    'plank',
    'crunch',
    'burpee',
    'mountain climber',
    'high knee',
    'jump',
    'superman',
    'glute bridge',
    'calf raise',
    'inverted row',
    'pike',
    'band pull',
    'reverse lunge',
    'leg raise',
    'russian twist',
    'wide push',
  ];
  for (final kw in bodyweightKeywords) {
    if (name.contains(kw)) return 0;
  }

  // Resistance band exercises → 0 (band tension, not kg)
  if (name.contains('band')) return 0;

  // Heavy compound lifts
  if (name.contains('deadlift') && !name.contains('romanian')) {
    return isAdv ? 100.0 : (isBeg ? 40.0 : 60.0);
  }
  if (name.contains('barbell squat') || name.contains('back squat')) {
    return isAdv ? 80.0 : (isBeg ? 30.0 : 50.0);
  }
  if (name.contains('barbell bench') || name.contains('bench press')) {
    return isAdv ? 70.0 : (isBeg ? 25.0 : 45.0);
  }
  if (name.contains('overhead press') || name.contains('barbell shoulder')) {
    return isAdv ? 50.0 : (isBeg ? 20.0 : 35.0);
  }

  // Romanian / stiff-leg deadlift
  if (name.contains('romanian deadlift')) {
    return isAdv ? 60.0 : (isBeg ? 20.0 : 40.0);
  }

  // Dumbbell compounds
  if (name.contains('dumbbell incline') || name.contains('incline press')) {
    return isAdv ? 24.0 : (isBeg ? 8.0 : 14.0);
  }
  if (name.contains('dumbbell shoulder press') ||
      name.contains('dumbbell press')) {
    return isAdv ? 20.0 : (isBeg ? 6.0 : 12.0);
  }
  if (name.contains('dumbbell row')) {
    return isAdv ? 28.0 : (isBeg ? 10.0 : 18.0);
  }
  if (name.contains('dumbbell lunge') || name.contains('dumbbell squat')) {
    return isAdv ? 20.0 : (isBeg ? 8.0 : 14.0);
  }
  if (name.contains('dumbbell fl')) {
    return isAdv ? 14.0 : (isBeg ? 5.0 : 9.0);
  }

  // Isolation — curls
  if (name.contains('barbell curl')) {
    return isAdv ? 30.0 : (isBeg ? 10.0 : 18.0);
  }
  if (name.contains('hammer curl') ||
      name.contains('bicep curl') ||
      name.contains('dumbbell curl')) {
    return isAdv ? 16.0 : (isBeg ? 6.0 : 10.0);
  }

  // Isolation — triceps
  if (name.contains('skull crusher')) {
    return isAdv ? 24.0 : (isBeg ? 8.0 : 14.0);
  }
  if (name.contains('tricep pushdown') || name.contains('cable')) {
    return isAdv ? 30.0 : (isBeg ? 10.0 : 18.0);
  }

  // Shoulders isolation
  if (name.contains('lateral raise') || name.contains('front raise')) {
    return isAdv ? 10.0 : (isBeg ? 3.0 : 6.0);
  }
  if (name.contains('face pull')) {
    return isAdv ? 20.0 : (isBeg ? 8.0 : 13.0);
  }

  // Leg press / leg curl
  if (name.contains('leg press')) {
    return isAdv ? 100.0 : (isBeg ? 40.0 : 60.0);
  }
  if (name.contains('leg curl') || name.contains('leg extension')) {
    return isAdv ? 40.0 : (isBeg ? 15.0 : 25.0);
  }

  // Seated cable row
  if (name.contains('seated cable row') || name.contains('cable row')) {
    return isAdv ? 50.0 : (isBeg ? 18.0 : 30.0);
  }

  // Default for any other weighted exercise
  return isAdv ? 20.0 : (isBeg ? 8.0 : 12.0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point: WorkoutActiveScreen
// ─────────────────────────────────────────────────────────────────────────────
class WorkoutActiveScreen extends StatefulWidget {
  final String workoutLabel;
  final List<Map<String, dynamic>> exercises;

  const WorkoutActiveScreen({
    required this.workoutLabel,
    required this.exercises,
    super.key,
  });

  @override
  State<WorkoutActiveScreen> createState() => _WorkoutActiveScreenState();
}

class _WorkoutActiveScreenState extends State<WorkoutActiveScreen> {
  late List<ActiveExercise> _activeExercises;
  int _elapsedSeconds = 0;
  Timer? _workoutTimer;
  bool _paused = false;
  String _experience = 'Beginner';

  @override
  void initState() {
    super.initState();
    _activeExercises = [];
    _loadExperienceAndBuild();
    _startTimer();
  }

  Future<void> _loadExperienceAndBuild() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('questionnaire_answers');
      if (raw != null) {
        final Map<String, dynamic> saved =
            jsonDecode(raw) as Map<String, dynamic>;
        _experience = saved['experience'] as String? ?? 'Beginner';
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _activeExercises = widget.exercises.map((e) {
        final repsRaw = e['reps'];
        final defaultReps = repsRaw is int ? repsRaw : 0;
        final suggested = _suggestWeight(e['name'] as String, _experience);
        return ActiveExercise(
          name: e['name'] as String,
          muscleGroup: e['muscleGroup'] as String,
          icon: e['icon'] as IconData,
          defaultRestSec: (e['restSec'] as int?) ?? 60,
          numSets: (e['sets'] as int?) ?? 3,
          defaultReps: defaultReps,
          suggestedWeight: suggested,
        );
      }).toList();
    });
  }

  void _startTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  int get _totalSets =>
      _activeExercises.fold(0, (sum, e) => sum + e.sets.length);
  int get _doneSets => _activeExercises.fold(
    0,
    (sum, e) => sum + e.sets.where((s) => s.done).length,
  );

  bool get _allDone => _doneSets == _totalSets && _totalSets > 0;

  double _estimateCalories() {
    final minutes = _elapsedSeconds / 60.0;
    return (5.0 * 70 * 3.5 / 200) * minutes;
  }

  void _onSetDone(ActiveExercise exercise, int setIndex) {
    final set = exercise.sets[setIndex];
    if (set.reps == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter reps before marking set as done',
            style: GoogleFonts.manrope(color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    setState(() => set.done = true);

    final allSetsOfExerciseDone = exercise.sets.every((s) => s.done);
    if (allSetsOfExerciseDone && !_allDone) {
      _showRestPage(exercise.defaultRestSec);
    } else if (_allDone) {
      Future.delayed(const Duration(milliseconds: 400), _showCompletion);
    } else {
      _showRestPage(exercise.defaultRestSec);
    }
  }

  void _showRestPage(int restSec) {
    _workoutTimer?.cancel();
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => RestTimerPage(
              initialRestSeconds: restSec,
              onDone: () {
                Navigator.of(context).pop();
                _startTimer();
              },
            ),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        )
        .then((_) => _startTimer());
  }

  void _showCompletion() {
    _workoutTimer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => WorkoutCompletionScreen(
          workoutLabel: widget.workoutLabel,
          durationSeconds: _elapsedSeconds,
          caloriesBurned: _estimateCalories(),
          totalSets: _totalSets,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _confirmExit(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workoutLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$_doneSets / $_totalSets sets done',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pause/Resume
                  GestureDetector(
                    onTap: () => setState(() => _paused = !_paused),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _paused
                            ? AppTheme.primaryContainer
                            : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: _paused
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Timer pill ───────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _paused
                        ? Icons.pause_circle_outline_rounded
                        : Icons.timer_rounded,
                    color: const Color(0xFF1A1A1A),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _paused
                        ? 'Paused — ${_formatTime(_elapsedSeconds)}'
                        : _formatTime(_elapsedSeconds),
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Exercise list ────────────────────────────────────────────
            Expanded(
              child: _activeExercises.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: _activeExercises.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        return _ActiveExerciseCard(
                          exercise: _activeExercises[i],
                          onSetDone: (setIdx) =>
                              _onSetDone(_activeExercises[i], setIdx),
                        );
                      },
                    ),
            ),
            // ── Finish button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allDone ? _showCompletion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allDone
                        ? AppTheme.primary
                        : AppTheme.surfaceDark,
                    foregroundColor: _allDone
                        ? const Color(0xFF1A1A1A)
                        : AppTheme.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _allDone
                        ? '🎉 Finish Workout'
                        : 'Complete all sets to finish',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    // Capture navigator before async gap
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'End Workout?',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Stats will be calculated for completed sets only.',
          style: GoogleFonts.manrope(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Going',
              style: GoogleFonts.manrope(color: AppTheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              _workoutTimer?.cancel();
              // Close dialog first
              Navigator.pop(context);
              // Only show completion if at least one set was done
              if (_doneSets > 0) {
                navigator.pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => WorkoutCompletionScreen(
                      workoutLabel: widget.workoutLabel,
                      durationSeconds: _elapsedSeconds,
                      caloriesBurned: _estimateCalories(),
                      totalSets: _doneSets,
                    ),
                    transitionsBuilder: (_, anim, __, child) => FadeTransition(
                      opacity: CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOutCubic,
                      ),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              } else {
                // Nothing done — just go back to workout plan screen
                navigator.pop();
              }
            },
            child: Text(
              'End',
              style: GoogleFonts.manrope(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active Exercise Card
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveExerciseCard extends StatefulWidget {
  final ActiveExercise exercise;
  final void Function(int setIndex) onSetDone;

  const _ActiveExerciseCard({required this.exercise, required this.onSetDone});

  @override
  State<_ActiveExerciseCard> createState() => _ActiveExerciseCardState();
}

class _ActiveExerciseCardState extends State<_ActiveExerciseCard> {
  late List<TextEditingController> _repControllers;
  late List<TextEditingController> _weightControllers;

  @override
  void initState() {
    super.initState();
    _repControllers = widget.exercise.sets
        .map((s) => TextEditingController(text: s.reps > 0 ? '${s.reps}' : ''))
        .toList();
    _weightControllers = widget.exercise.sets.map((s) {
      final suggested = s.weight > 0
          ? s.weight.toStringAsFixed(s.weight % 1 == 0 ? 0 : 1)
          : '';
      return TextEditingController(text: suggested);
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _repControllers) {
      c.dispose();
    }
    for (final c in _weightControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final allDone = exercise.sets.every((s) => s.done);
    final hasSuggestedWeight = exercise.suggestedWeight > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: allDone ? AppTheme.primaryContainer : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allDone ? AppTheme.primary.withAlpha(100) : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: allDone
                        ? AppTheme.primary.withAlpha(50)
                        : AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    exercise.icon,
                    size: 18,
                    color: allDone ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: allDone
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                          decoration: allDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppTheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        exercise.muscleGroup,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (allDone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '✓ Done',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
              ],
            ),
            // Suggested weight hint
            if (hasSuggestedWeight && !allDone) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Suggested: ${exercise.suggestedWeight.toStringAsFixed(exercise.suggestedWeight % 1 == 0 ? 0 : 1)} kg — edit below',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            // Column headers
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    'Set',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reps',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasSuggestedWeight ? 'Weight (kg) ✏️' : 'Weight (kg)',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: hasSuggestedWeight
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 8),
            // Sets
            ...List.generate(exercise.sets.length, (i) {
              final set = exercise.sets[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Set number
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: set.done
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Reps input
                    Expanded(
                      child: _SetInputField(
                        controller: _repControllers[i],
                        hint: '0',
                        enabled: !set.done,
                        onChanged: (v) {
                          set.reps = int.tryParse(v) ?? 0;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Weight input (pre-filled with suggestion, editable)
                    Expanded(
                      child: _SetInputField(
                        controller: _weightControllers[i],
                        hint: hasSuggestedWeight
                            ? exercise.suggestedWeight.toStringAsFixed(
                                exercise.suggestedWeight % 1 == 0 ? 0 : 1,
                              )
                            : '0',
                        enabled: !set.done,
                        isDecimal: true,
                        highlighted: hasSuggestedWeight && !set.done,
                        onChanged: (v) {
                          set.weight = double.tryParse(v) ?? 0;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Done button
                    GestureDetector(
                      onTap: set.done
                          ? null
                          : () {
                              set.reps =
                                  int.tryParse(_repControllers[i].text) ?? 0;
                              set.weight =
                                  double.tryParse(_weightControllers[i].text) ??
                                  0;
                              setState(() {});
                              widget.onSetDone(i);
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 38,
                        decoration: BoxDecoration(
                          color: set.done
                              ? AppTheme.primary
                              : AppTheme.surfaceVariantDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: set.done
                                ? AppTheme.primary
                                : AppTheme.textMuted.withAlpha(80),
                          ),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: set.done
                              ? const Color(0xFF1A1A1A)
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SetInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final bool isDecimal;
  final bool highlighted;
  final void Function(String) onChanged;

  const _SetInputField({
    required this.controller,
    required this.hint,
    required this.enabled,
    required this.onChanged,
    this.isDecimal = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: enabled
            ? (highlighted
                  ? AppTheme.primaryContainer
                  : AppTheme.surfaceVariantDark)
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled
              ? (highlighted
                    ? AppTheme.primary.withAlpha(120)
                    : AppTheme.textMuted.withAlpha(80))
              : Colors.transparent,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        keyboardType: isDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: enabled
              ? (highlighted ? AppTheme.primary : AppTheme.textPrimary)
              : AppTheme.textMuted,
          fontFeatures: [const FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
            fontSize: 14,
            color: highlighted
                ? AppTheme.primary.withAlpha(150)
                : AppTheme.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rest Timer Page
// ─────────────────────────────────────────────────────────────────────────────
class RestTimerPage extends StatefulWidget {
  final int initialRestSeconds;
  final VoidCallback onDone;

  const RestTimerPage({
    required this.initialRestSeconds,
    required this.onDone,
    super.key,
  });

  @override
  State<RestTimerPage> createState() => _RestTimerPageState();
}

class _RestTimerPageState extends State<RestTimerPage>
    with SingleTickerProviderStateMixin {
  late int _totalSeconds;
  late int _remaining;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialRestSeconds;
    _remaining = _totalSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        setState(() => _remaining = 0);
        Future.delayed(const Duration(milliseconds: 500), widget.onDone);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _addTime(int seconds) {
    setState(() {
      _remaining += seconds;
      _totalSeconds += seconds;
    });
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  double get _progress =>
      _totalSeconds > 0 ? (_totalSeconds - _remaining) / _totalSeconds : 1.0;

  @override
  Widget build(BuildContext context) {
    final isDone = _remaining == 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                isDone ? 'Rest Complete!' : 'Rest Time',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isDone
                    ? 'Ready for the next set?'
                    : 'Take a breather. You earned it.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 10,
                        backgroundColor: AppTheme.surfaceDark,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDone ? AppTheme.primary : AppTheme.sleepColor,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isDone)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) => Opacity(
                              opacity: 0.6 + 0.4 * _pulseController.value,
                              child: Icon(
                                Icons.self_improvement_rounded,
                                size: 28,
                                color: AppTheme.sleepColor,
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 28,
                            color: AppTheme.primary,
                          ),
                        const SizedBox(height: 6),
                        Text(
                          isDone ? '00:00' : _formatTime(_remaining),
                          style: GoogleFonts.manrope(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: isDone
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          'remaining',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              if (!isDone) ...[
                Text(
                  'Need more rest?',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AddTimeButton(label: '+15s', onTap: () => _addTime(15)),
                    const SizedBox(width: 10),
                    _AddTimeButton(label: '+30s', onTap: () => _addTime(30)),
                    const SizedBox(width: 10),
                    _AddTimeButton(label: '+60s', onTap: () => _addTime(60)),
                  ],
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _timer?.cancel();
                    widget.onDone();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDone
                        ? AppTheme.primary
                        : AppTheme.surfaceDark,
                    foregroundColor: isDone
                        ? const Color(0xFF1A1A1A)
                        : AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isDone ? 'Continue Workout →' : 'Skip Rest',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddTimeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppTheme.sleepColor.withAlpha(100)),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.sleepColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Workout Completion Screen
// ─────────────────────────────────────────────────────────────────────────────
class WorkoutCompletionScreen extends StatefulWidget {
  final String workoutLabel;
  final int durationSeconds;
  final double caloriesBurned;
  final int totalSets;

  const WorkoutCompletionScreen({
    required this.workoutLabel,
    required this.durationSeconds,
    required this.caloriesBurned,
    required this.totalSets,
    super.key,
  });

  @override
  State<WorkoutCompletionScreen> createState() =>
      _WorkoutCompletionScreenState();
}

class _WorkoutCompletionScreenState extends State<WorkoutCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scaleController.forward();
        _fadeController.forward();
      }
    });
    // Sync workout log to cloud
    _saveToCloud();
  }

  Future<void> _saveToCloud() async {
    await SupabaseService.instance.saveWorkoutLog(
      workoutLabel: widget.workoutLabel,
      durationSeconds: widget.durationSeconds,
      caloriesBurned: widget.caloriesBurned,
      totalSets: widget.totalSets,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _formatDuration(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}h ${m}m ${sec}s';
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary.withAlpha(150),
                        width: 3,
                      ),
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 52)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Yay! Workout Done! 🎉',
                  style: GoogleFonts.manrope(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.workoutLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppTheme.caloriesColor,
                        value:
                            '${widget.caloriesBurned.toStringAsFixed(0)} kcal',
                        label: 'Calories Burned',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.timer_rounded,
                        iconColor: AppTheme.stepsColor,
                        value: _formatDuration(widget.durationSeconds),
                        label: 'Duration',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.repeat_rounded,
                        iconColor: AppTheme.proteinColor,
                        value: '${widget.totalSets}',
                        label: 'Sets Completed',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bolt_rounded,
                        iconColor: AppTheme.primary,
                        value: 'Great!',
                        label: 'Performance',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.primary.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Text('💪', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You crushed it! Every rep counts. Rest up and come back stronger.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Back to Workouts',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
