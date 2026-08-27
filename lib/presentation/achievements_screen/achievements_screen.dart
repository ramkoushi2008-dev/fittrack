import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Stats from existing tables
  int _totalWorkouts = 0;
  double _totalCaloriesBurned = 0;
  int _currentStreak = 0;
  double _totalHoursSlept = 0;
  int _totalNutritionLogs = 0;

  // Weekly workout data for chart (last 8 weeks)
  List<double> _weeklyWorkoutCounts = List.filled(8, 0);
  List<double> _weeklyCalories = List.filled(8, 0);

  // Personal records
  List<Map<String, dynamic>> _personalRecords = [];

  // Unlocked achievements
  Set<String> _unlockedKeys = {};

  static const List<_BadgeDef> _allBadges = [
    _BadgeDef(
      key: 'first_workout',
      title: 'First Step',
      description: 'Complete your first workout',
      icon: Icons.directions_run_rounded,
      color: Color(0xFFC6F135),
      requirement: 1,
      type: _BadgeType.workouts,
    ),
    _BadgeDef(
      key: 'workouts_10',
      title: 'Getting Warmed Up',
      description: '10 workouts completed',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF7043),
      requirement: 10,
      type: _BadgeType.workouts,
    ),
    _BadgeDef(
      key: 'workouts_25',
      title: 'Committed',
      description: '25 workouts completed',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF64B5F6),
      requirement: 25,
      type: _BadgeType.workouts,
    ),
    _BadgeDef(
      key: 'workouts_50',
      title: 'Half Century',
      description: '50 workouts completed',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFFFB300),
      requirement: 50,
      type: _BadgeType.workouts,
    ),
    _BadgeDef(
      key: 'workouts_100',
      title: 'Century Club',
      description: '100 workouts completed',
      icon: Icons.military_tech_rounded,
      color: Color(0xFFBA68C8),
      requirement: 100,
      type: _BadgeType.workouts,
    ),
    _BadgeDef(
      key: 'calories_1000',
      title: 'Calorie Crusher',
      description: 'Burn 1,000 total calories',
      icon: Icons.whatshot_rounded,
      color: Color(0xFFFF7043),
      requirement: 1000,
      type: _BadgeType.calories,
    ),
    _BadgeDef(
      key: 'calories_5000',
      title: 'Inferno',
      description: 'Burn 5,000 total calories',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFCF6679),
      requirement: 5000,
      type: _BadgeType.calories,
    ),
    _BadgeDef(
      key: 'calories_10000',
      title: 'Furnace',
      description: 'Burn 10,000 total calories',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFB300),
      requirement: 10000,
      type: _BadgeType.calories,
    ),
    _BadgeDef(
      key: 'streak_7',
      title: '7-Day Streak',
      description: 'Log activity 7 days in a row',
      icon: Icons.calendar_today_rounded,
      color: Color(0xFF4CAF50),
      requirement: 7,
      type: _BadgeType.streak,
    ),
    _BadgeDef(
      key: 'streak_30',
      title: '30-Day Streak',
      description: 'Log activity 30 days in a row',
      icon: Icons.date_range_rounded,
      color: Color(0xFFC6F135),
      requirement: 30,
      type: _BadgeType.streak,
    ),
    _BadgeDef(
      key: 'nutrition_10',
      title: 'Mindful Eater',
      description: 'Log 10 nutrition entries',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFFB74D),
      requirement: 10,
      type: _BadgeType.nutrition,
    ),
    _BadgeDef(
      key: 'sleep_7',
      title: 'Rest Master',
      description: 'Log 7 nights of sleep',
      icon: Icons.bedtime_rounded,
      color: Color(0xFFBA68C8),
      requirement: 7,
      type: _BadgeType.sleep,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadWorkoutStats(),
        _loadNutritionStats(),
        _loadSleepStats(),
        _loadPersonalRecords(),
        _loadUnlockedAchievements(),
      ]);
      _computeAndUnlockBadges();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadWorkoutStats() async {
    final logs = await SupabaseService.instance.fetchWorkoutLogs(limit: 500);
    if (logs.isEmpty) return;

    _totalWorkouts = logs.length;
    _totalCaloriesBurned = logs.fold(
      0.0,
      (sum, l) => sum + ((l['calories_burned'] as num?)?.toDouble() ?? 0),
    );

    // Compute streak
    final dates =
        logs
            .map((l) {
              final raw = l['logged_at'] as String?;
              if (raw == null) return null;
              final dt = DateTime.tryParse(raw);
              if (dt == null) return null;
              return DateTime(dt.year, dt.month, dt.day);
            })
            .whereType<DateTime>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime check = DateTime.now();
    check = DateTime(check.year, check.month, check.day);
    for (final d in dates) {
      if (d == check || d == check.subtract(const Duration(days: 1))) {
        streak++;
        check = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    _currentStreak = streak;

    // Weekly workout counts (last 8 weeks)
    final now = DateTime.now();
    final weekCounts = List<double>.filled(8, 0);
    final weekCalories = List<double>.filled(8, 0);
    for (final l in logs) {
      final raw = l['logged_at'] as String?;
      if (raw == null) continue;
      final dt = DateTime.tryParse(raw);
      if (dt == null) continue;
      final diff = now.difference(dt).inDays;
      final weekIdx = diff ~/ 7;
      if (weekIdx < 8) {
        weekCounts[7 - weekIdx] += 1;
        weekCalories[7 - weekIdx] +=
            (l['calories_burned'] as num?)?.toDouble() ?? 0;
      }
    }
    _weeklyWorkoutCounts = weekCounts;
    _weeklyCalories = weekCalories;
  }

  Future<void> _loadNutritionStats() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return;
    try {
      final response = await SupabaseService.instance.client
          .from('nutrition_logs')
          .select('id')
          .eq('user_id', uid);
      _totalNutritionLogs = (response as List).length;
    } catch (_) {}
  }

  Future<void> _loadSleepStats() async {
    final logs = await SupabaseService.instance.fetchWeeklySleepLogs();
    _totalHoursSlept = logs.fold(
      0.0,
      (sum, l) => sum + ((l['hours_slept'] as num?)?.toDouble() ?? 0),
    );
  }

  Future<void> _loadPersonalRecords() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return;
    try {
      final response = await SupabaseService.instance.client
          .from('personal_records')
          .select()
          .eq('user_id', uid)
          .order('achieved_at', ascending: false);
      _personalRecords = List<Map<String, dynamic>>.from(response);
    } catch (_) {}
  }

  Future<void> _loadUnlockedAchievements() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return;
    try {
      final response = await SupabaseService.instance.client
          .from('user_achievements')
          .select('achievement_key')
          .eq('user_id', uid);
      _unlockedKeys = (response as List)
          .map((r) => r['achievement_key'] as String)
          .toSet();
    } catch (_) {}
  }

  Future<void> _computeAndUnlockBadges() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return;

    for (final badge in _allBadges) {
      if (_unlockedKeys.contains(badge.key)) continue;
      bool earned = false;
      switch (badge.type) {
        case _BadgeType.workouts:
          earned = _totalWorkouts >= badge.requirement;
          break;
        case _BadgeType.calories:
          earned = _totalCaloriesBurned >= badge.requirement;
          break;
        case _BadgeType.streak:
          earned = _currentStreak >= badge.requirement;
          break;
        case _BadgeType.nutrition:
          earned = _totalNutritionLogs >= badge.requirement;
          break;
        case _BadgeType.sleep:
          earned = _totalHoursSlept >= badge.requirement;
          break;
      }
      if (earned) {
        try {
          await SupabaseService.instance.client
              .from('user_achievements')
              .upsert({
                'user_id': uid,
                'achievement_key': badge.key,
                'achievement_title': badge.title,
                'achievement_description': badge.description,
                'unlocked_at': DateTime.now().toIso8601String(),
              }, onConflict: 'user_id,achievement_key');
          _unlockedKeys.add(badge.key);
        } catch (_) {}
      }
    }
  }

  Future<void> _addPersonalRecord() async {
    final exerciseCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String unit = 'kg';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Personal Record',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: exerciseCtrl,
                style: GoogleFonts.manrope(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g. Bench Press',
                  filled: true,
                  fillColor: AppTheme.surfaceVariantDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: valueCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.manrope(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Value',
                        filled: true,
                        fillColor: AppTheme.surfaceVariantDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: unit,
                        dropdownColor: AppTheme.surfaceVariantDark,
                        style: GoogleFonts.manrope(color: AppTheme.textPrimary),
                        items: ['kg', 'lbs', 'reps', 'km', 'min']
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (v) => setModal(() => unit = v ?? unit),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final name = exerciseCtrl.text.trim();
                    final val = double.tryParse(valueCtrl.text.trim());
                    if (name.isEmpty || val == null) return;
                    final uid = SupabaseService.instance.currentUserId;
                    if (uid == null) return;
                    try {
                      await SupabaseService.instance.client
                          .from('personal_records')
                          .insert({
                            'user_id': uid,
                            'exercise_name': name,
                            'record_value': val,
                            'record_unit': unit,
                            'achieved_at': DateTime.now().toIso8601String(),
                          });
                    } catch (_) {}
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadPersonalRecords();
                    if (mounted) setState(() {});
                  },
                  child: Text(
                    'Save Record',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Achievements',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (!_isLoading)
                    GestureDetector(
                      onTap: _loadData,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats summary row
            if (!_isLoading)
              _StatsRow(
                totalWorkouts: _totalWorkouts,
                streak: _currentStreak,
                totalCalories: _totalCaloriesBurned,
              ),
            if (!_isLoading) const SizedBox(height: 16),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF1A1A1A),
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Badges'),
                  Tab(text: 'Records'),
                  Tab(text: 'Progress'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _BadgesTab(
                          badges: _allBadges,
                          unlockedKeys: _unlockedKeys,
                          totalWorkouts: _totalWorkouts,
                          totalCalories: _totalCaloriesBurned,
                          streak: _currentStreak,
                          nutritionLogs: _totalNutritionLogs,
                          sleepHours: _totalHoursSlept,
                        ),
                        _RecordsTab(
                          records: _personalRecords,
                          onAdd: _addPersonalRecord,
                          onDelete: (id) async {
                            final uid = SupabaseService.instance.currentUserId;
                            if (uid == null) return;
                            try {
                              await SupabaseService.instance.client
                                  .from('personal_records')
                                  .delete()
                                  .eq('id', id)
                                  .eq('user_id', uid);
                            } catch (_) {}
                            await _loadPersonalRecords();
                            if (mounted) setState(() {});
                          },
                        ),
                        _ProgressTab(
                          weeklyWorkouts: _weeklyWorkoutCounts,
                          weeklyCalories: _weeklyCalories,
                          totalWorkouts: _totalWorkouts,
                          totalCalories: _totalCaloriesBurned,
                          streak: _currentStreak,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int totalWorkouts;
  final int streak;
  final double totalCalories;

  const _StatsRow({
    required this.totalWorkouts,
    required this.streak,
    required this.totalCalories,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _StatChip(
            label: 'Workouts',
            value: '$totalWorkouts',
            color: AppTheme.workoutColor,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Streak',
            value: '${streak}d',
            color: AppTheme.success,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Calories',
            value: totalCalories >= 1000
                ? '${(totalCalories / 1000).toStringAsFixed(1)}k'
                : totalCalories.toStringAsFixed(0),
            color: AppTheme.caloriesColor,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badges Tab ──────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  final List<_BadgeDef> badges;
  final Set<String> unlockedKeys;
  final int totalWorkouts;
  final double totalCalories;
  final int streak;
  final int nutritionLogs;
  final double sleepHours;

  const _BadgesTab({
    required this.badges,
    required this.unlockedKeys,
    required this.totalWorkouts,
    required this.totalCalories,
    required this.streak,
    required this.nutritionLogs,
    required this.sleepHours,
  });

  double _progress(_BadgeDef badge) {
    double current = 0;
    switch (badge.type) {
      case _BadgeType.workouts:
        current = totalWorkouts.toDouble();
        break;
      case _BadgeType.calories:
        current = totalCalories;
        break;
      case _BadgeType.streak:
        current = streak.toDouble();
        break;
      case _BadgeType.nutrition:
        current = nutritionLogs.toDouble();
        break;
      case _BadgeType.sleep:
        current = sleepHours;
        break;
    }
    return (current / badge.requirement).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = badges.where((b) => unlockedKeys.contains(b.key)).toList();
    final locked = badges.where((b) => !unlockedKeys.contains(b.key)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
      children: [
        if (unlocked.isNotEmpty) ...[
          _SectionHeader(
            title: 'Unlocked',
            count: unlocked.length,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: unlocked.length,
            itemBuilder: (_, i) =>
                _BadgeCard(badge: unlocked[i], isUnlocked: true, progress: 1.0),
          ),
          const SizedBox(height: 20),
        ],
        _SectionHeader(
          title: 'In Progress',
          count: locked.length,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: locked.length,
          itemBuilder: (_, i) => _BadgeCard(
            badge: locked[i],
            isUnlocked: false,
            progress: _progress(locked[i]),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(38),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final _BadgeDef badge;
  final bool isUnlocked;
  final double progress;

  const _BadgeCard({
    required this.badge,
    required this.isUnlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked ? badge.color.withAlpha(20) : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? badge.color.withAlpha(77)
              : AppTheme.surfaceVariantDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? badge.color.withAlpha(38)
                      : AppTheme.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  badge.icon,
                  size: 20,
                  color: isUnlocked ? badge.color : AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              if (isUnlocked)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            badge.title,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isUnlocked ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            badge.description,
            style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.surfaceVariantDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                isUnlocked ? badge.color : badge.color.withAlpha(128),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isUnlocked ? 'Completed!' : '${(progress * 100).toInt()}%',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? badge.color : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Records Tab ─────────────────────────────────────────────────────────────

class _RecordsTab extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final VoidCallback onAdd;
  final void Function(String id) onDelete;

  const _RecordsTab({
    required this.records,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Personal Records',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
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
        Expanded(
          child: records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 48,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No records yet',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap + Add to log your first PR',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = records[i];
                    final date = r['achieved_at'] != null
                        ? DateTime.tryParse(r['achieved_at'] as String)
                        : null;
                    return Dismissible(
                      key: Key(r['id'] as String),
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
                      onDismissed: (_) => onDelete(r['id'] as String),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.surfaceVariantDark,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['exercise_name'] as String? ?? '',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (date != null)
                                    Text(
                                      '${date.day}/${date.month}/${date.year}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${r['record_value']} ${r['record_unit']}',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Progress Tab ─────────────────────────────────────────────────────────────

class _ProgressTab extends StatefulWidget {
  final List<double> weeklyWorkouts;
  final List<double> weeklyCalories;
  final int totalWorkouts;
  final double totalCalories;
  final int streak;

  const _ProgressTab({
    required this.weeklyWorkouts,
    required this.weeklyCalories,
    required this.totalWorkouts,
    required this.totalCalories,
    required this.streak,
  });

  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  bool _showCalories = false;

  @override
  Widget build(BuildContext context) {
    final data = _showCalories ? widget.weeklyCalories : widget.weeklyWorkouts;
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final chartMax = maxY == 0 ? 5.0 : (maxY * 1.3);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
      children: [
        // Toggle
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _ToggleBtn(
                label: 'Workouts',
                isActive: !_showCalories,
                onTap: () => setState(() => _showCalories = false),
              ),
              _ToggleBtn(
                label: 'Calories',
                isActive: _showCalories,
                onTap: () => setState(() => _showCalories = true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Chart
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceVariantDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showCalories ? 'Weekly Calories Burned' : 'Weekly Workouts',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Last 8 weeks',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    maxY: chartMax,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: chartMax / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppTheme.surfaceVariantDark,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: chartMax / 4,
                          getTitlesWidget: (v, _) => Text(
                            _showCalories
                                ? v >= 1000
                                      ? '${(v / 1000).toStringAsFixed(0)}k'
                                      : v.toInt().toString()
                                : v.toInt().toString(),
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final labels = [
                              'W1',
                              'W2',
                              'W3',
                              'W4',
                              'W5',
                              'W6',
                              'W7',
                              'W8',
                            ];
                            final idx = v.toInt();
                            if (idx < 0 || idx >= labels.length)
                              return const SizedBox.shrink();
                            return Text(
                              labels[idx],
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barGroups: List.generate(data.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i],
                            color: _showCalories
                                ? AppTheme.caloriesColor
                                : AppTheme.primary,
                            width: 18,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: chartMax,
                              color: AppTheme.surfaceVariantDark,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Workouts',
                value: '${widget.totalWorkouts}',
                icon: Icons.fitness_center_rounded,
                color: AppTheme.workoutColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Total Calories',
                value: widget.totalCalories >= 1000
                    ? '${(widget.totalCalories / 1000).toStringAsFixed(1)}k'
                    : widget.totalCalories.toStringAsFixed(0),
                icon: Icons.local_fire_department_rounded,
                color: AppTheme.caloriesColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          label: 'Current Streak',
          value: '${widget.streak} days',
          icon: Icons.bolt_rounded,
          color: AppTheme.success,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? const Color(0xFF1A1A1A)
                  : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

enum _BadgeType { workouts, calories, streak, nutrition, sleep }

class _BadgeDef {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requirement;
  final _BadgeType type;

  const _BadgeDef({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requirement,
    required this.type,
  });
}
