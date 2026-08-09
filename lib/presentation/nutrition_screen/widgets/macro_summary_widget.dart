import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';

class MacroSummaryWidget extends StatelessWidget {
  const MacroSummaryWidget({super.key});

  static const List<Map<String, dynamic>> _macros = [
    {
      'label': 'Calories',
      'current': 1390,
      'target': 2200,
      'unit': 'kcal',
      'color': AppTheme.caloriesColor,
      'progress': 0.63,
    },
    {
      'label': 'Protein',
      'current': 82,
      'target': 120,
      'unit': 'g',
      'color': AppTheme.proteinColor,
      'progress': 0.68,
    },
    {
      'label': 'Carbs',
      'current': 195,
      'target': 280,
      'unit': 'g',
      'color': AppTheme.stepsColor,
      'progress': 0.70,
    },
    {
      'label': 'Fat',
      'current': 52,
      'target': 75,
      'unit': 'g',
      'color': AppTheme.sleepColor,
      'progress': 0.69,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Nutrition',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _macros.map((macro) {
              return _MacroArcWidget(macro: macro);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MacroArcWidget extends StatelessWidget {
  final Map<String, dynamic> macro;
  const _MacroArcWidget({required this.macro});

  @override
  Widget build(BuildContext context) {
    final color = macro['color'] as Color;
    final progress = macro['progress'] as double;

    return Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: CustomPaint(
            painter: _ArcPainter(
              progress: progress,
              color: color,
              trackColor: AppTheme.surfaceVariantDark,
            ),
            child: Center(
              child: Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${macro['current']}${macro['unit']}',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
        Text(
          macro['label'] as String,
          style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    const strokeWidth = 6.0;
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
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
