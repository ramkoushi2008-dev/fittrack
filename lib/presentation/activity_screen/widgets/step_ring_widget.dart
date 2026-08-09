import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';

class StepRingWidget extends StatefulWidget {
  final int selectedMetric;
  const StepRingWidget({required this.selectedMetric, super.key});

  @override
  State<StepRingWidget> createState() => _StepRingWidgetState();
}

class _StepRingWidgetState extends State<StepRingWidget>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with [Riverpod/Bloc] for production
  late AnimationController _controller;
  late Animation<double> _anim;

  static const List<Map<String, dynamic>> _metricData = [
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

  @override
  void initState() {
    super.initState();
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
    if (old.selectedMetric != widget.selectedMetric) {
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
        color: AppTheme.surfaceDark,
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
                    trackColor: AppTheme.surfaceVariantDark,
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
                            color: AppTheme.textSecondary,
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
                      color: AppTheme.textPrimary,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    sub['label'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.textMuted,
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
