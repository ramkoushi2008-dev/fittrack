import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class WorkoutProgressCardWidget extends StatelessWidget {
  const WorkoutProgressCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withAlpha(38), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Progress',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.appTextSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.appSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: context.appTextSecondary,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusBadgeWidget(
                      label: 'Strength',
                      status: BadgeStatus.active,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Upper Body\nPush Day',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: context.appTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '55 min',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: context.appTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.signal_cellular_alt_rounded,
                          size: 14,
                          color: context.appTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Intermediate',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Circular progress
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _MiniRingPainter(progress: 0.65),
                  child: Center(
                    child: Text(
                      '65%',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // CTA Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Continue The Workout',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF1A1A1A),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double progress;
  _MiniRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    const strokeWidth = 7.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = context.appSurfaceVariant
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = AppTheme.primary
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
  bool shouldRepaint(_MiniRingPainter old) => old.progress != progress;
}
