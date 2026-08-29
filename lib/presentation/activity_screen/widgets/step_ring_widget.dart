import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';
import '../../../services/health_service.dart';

class StepRingWidget extends StatefulWidget {
  final int selectedMetric;

  /// Live data pulled from HealthKit / Health Connect. When null, demo
  /// placeholder data is shown instead (e.g. before the user connects).
  final DailySummary? summary;

  const StepRingWidget({
    required this.selectedMetric,
    this.summary,
    super.key,
  });

  @override
  State<StepRingWidget> createState() => _StepRingWidgetState();
}

class _StepRingWidgetState extends State<StepRingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  static const int _stepsTarget = 10000;
  static const int _caloriesTarget = 2200;
  static const int _activeMinTarget = 60;

  List<Map<String, dynamic>> _buildMetricData() {
    final summary = widget.summary;
    if (summary == null) {
      return _demoMetricData;
    }

    final stepsProgress = (summary.steps / _stepsTarget).clamp(0.0, 1.0);
    final caloriesProgress =
        (summary.caloriesKcal / _caloriesTarget).clamp(0.0, 1.0);
    final activeProgress =
        (summary.activeMinutes / _activeMinTarget).clamp(0.0, 1.0);

    return [
      {
        'value': _formatInt(summary.steps),
        'target': _formatInt(_stepsTarget),
        'unit': 'steps',
        'progress': stepsProgress,
        'color': AppTheme.stepsColor,
        'sub': [
          {
            'label': 'Distance',
            'value': '${summary.distanceKm.toStringAsFixed(1)} km',
            'icon': Icons.route_rounded,
          },
          {
            'label': 'Calories',
            'value': '${summary.caloriesKcal.round()} kcal',
            'icon': Icons.local_fire_department_outlined,
          },
          {
            'label': 'Active Min',
            'value': '${summary.activeMinutes} min',
            'icon': Icons.timer_outlined,
          },
        ],
      },
      {
        'value': summary.caloriesKcal.round().toString(),
        'target': _caloriesTarget.toString(),
        'unit': 'kcal',
        'progress': caloriesProgress,
        'color': AppTheme.caloriesColor,
        'sub': [
          {
            'label': 'Heart Rate',
            'value': summary.avgHeartRateBpm == null
                ? '— bpm'
                : '${summary.avgHeartRateBpm!.round()} bpm',
            'icon': Icons.favorite_outline_rounded,
          },
          {
            'label': 'Steps',
            'value': _formatInt(summary.steps),
            'icon': Icons.directions_walk_rounded,
          },
          {
            'label': 'Distance',
            'value': '${summary.distanceKm.toStringAsFixed(1)} km',
            'icon': Icons.route_rounded,
          },
        ],
      },
      {
        'value': summary.activeMinutes.toString(),
        'target': _activeMinTarget.toString(),
        'unit': 'min',
        'progress': activeProgress,
        'color': AppTheme.workoutColor,
        'sub': [
          {
            'label': 'Workouts',
            'value': '${summary.workoutsToday} done',
            'icon': Icons.fitness_center_rounded,
          },
          {
            'label': 'Heart Rate',
            'value': summary.avgHeartRateBpm == null
                ? '— bpm'
                : '${summary.avgHeartRateBpm!.round()} bpm',
            'icon': Icons.favorite_outline_rounded,
          },
          {
            'label': 'Steps',
            'value': _formatInt(summary.steps),
            'icon': Icons.directions_walk_rounded,
          },
        ],
      },
    ];
  }

  static String _formatInt(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static const List<Map<String, dynamic>> _demoMetricData = [
    {
      'value': '7,240',
      'target': '10,000',
      'unit': 'steps',
      'progress': 0.724,
      'color': AppTheme.stepsColor,
      'sub': [
        {'label': 'Distance', 'value': '5.2 km', 'icon': Icons.route_rounded},
        {
          'label': 'Calories',
          'value': '312 kcal',
          'icon': Icons.local_fire_department_outlined,
        },
        {
          'label': 'Active Min',
          'value': '48 min',
          'icon': Icons.timer_outlined,
        },
      ],
    },
    {
      'value': '1,390',
      'target': '2,200',
      'unit': 'kcal',
      'progress': 0.63,
      'color': AppTheme.caloriesColor,
      'sub': [
        {'label': 'Protein', 'value': '82 g', 'icon': Icons.egg_outlined},
        {'label': 'Carbs', 'value': '180 g', 'icon': Icons.grain_rounded},
        {'label': 'Fat', 'value': '48 g', 'icon': Icons.opacity_rounded},
      ],
    },
    {
      'value': '48',
      'target': '60',
      'unit': 'min',
      'progress': 0.8,
      'color': AppTheme.workoutColor,
      'sub': [
        {
          'label': 'Workouts',
          'value': '1 done',
          'icon': Icons.fitness_center_rounded,
        },
        {
          'label': 'Heart Rate',
          'value': '118 bpm',
          'icon': Icons.favorite_outline_rounded,
        },
        {
          'label': 'Steps',
          'value': '7,240',
          'icon': Icons.directions_walk_rounded,
        },
      ],
    },
  ];

  late List<Map<String, dynamic>> _metricData;

  @override
  void initState() {
    super.initState();
    _metricData = _buildMetricData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween<double>(
      begin: 0,
      end: _metricData[widget.selectedMetric]['progress'] as double,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(StepRingWidget old) {
    super.didUpdateWidget(old);
    _metricData = _buildMetricData();
    // Re-animate whenever the selected tab changes OR fresh live data comes
    // in (e.g. from the periodic health refresh), so the ring reflects the
    // latest progress in near real time.
    if (old.selectedMetric != widget.selectedMetric ||
        old.summary != widget.summary) {
      _anim =
          Tween<double>(
            begin: 0,
            end: _metricData[widget.selectedMetric]['progress'] as double,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _metricData[widget.selectedMetric];
    final color = data['color'] as Color;
    final subs = data['sub'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (context, child) {
              return SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: _anim.value,
                    color: color,
                    trackColor: context.appSurfaceVariant,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data['value'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: color,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          data['unit'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: subs.map((sub) {
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withAlpha(31),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      sub['icon'] as IconData,
                      size: 18,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sub['value'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    sub['label'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: context.appTextMuted,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;
    const strokeWidth = 12.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
