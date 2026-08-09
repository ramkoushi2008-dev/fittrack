import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';

class HealthScoreRingWidget extends StatefulWidget {
  const HealthScoreRingWidget({super.key});

  @override
  State<HealthScoreRingWidget> createState() => _HealthScoreRingWidgetState();
}

class _HealthScoreRingWidgetState extends State<HealthScoreRingWidget>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with [Riverpod/Bloc] for production
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;

  static const double _targetScore = 0.72;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = Tween<double>(
      begin: 0,
      end: _targetScore,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceDark, AppTheme.primary.withAlpha(13)],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Today\'s Health Score',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _HealthRingPainter(
                    progress: _scoreAnimation.value,
                    ringColor: AppTheme.primary,
                    trackColor: AppTheme.surfaceVariantDark,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(_scoreAnimation.value * 100).toInt()}%',
                          style: GoogleFonts.manrope(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          'Completed',
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
          const SizedBox(height: 16),
          Text(
            '72% of today\'s health goals completed',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HealthRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;

  _HealthRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 14;
    const strokeWidth = 14.0;
    const startAngle = -math.pi / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = ringColor
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
  bool shouldRepaint(_HealthRingPainter old) => old.progress != progress;
}
