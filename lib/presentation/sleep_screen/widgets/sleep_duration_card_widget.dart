import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SleepDurationCardWidget extends StatelessWidget {
  final double hoursSlept;
  final double targetHours;

  const SleepDurationCardWidget({
    required this.hoursSlept,
    required this.targetHours,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (hoursSlept / targetHours).clamp(0.0, 1.0);
    final h = hoursSlept.floor();
    final m = ((hoursSlept - h) * 60).round();
    final remaining = targetHours - hoursSlept;
    final rh = remaining.floor();
    final rm = ((remaining - rh) * 60).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.sleepColor.withAlpha(40)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.sleepColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bedtime_rounded,
                  color: AppTheme.sleepColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Last Night',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: progress >= 0.85
                      ? AppTheme.success.withAlpha(30)
                      : AppTheme.warning.withAlpha(30),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  progress >= 0.85 ? 'Good' : 'Below target',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: progress >= 0.85
                        ? AppTheme.success
                        : AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _SleepArcPainter(progress: progress),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      '${h}h ${m.toString().padLeft(2, '0')}m',
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      'of ${targetHours.toStringAsFixed(0)}h goal',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(progress * 100).round()}%',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.sleepColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Bedtime',
                  value: '10:45 PM',
                  icon: Icons.nights_stay_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  label: 'Wake up',
                  value: '6:30 AM',
                  icon: Icons.wb_sunny_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  label: 'Remaining',
                  value: remaining > 0
                      ? '${rh}h ${rm.toString().padLeft(2, '0')}m'
                      : 'Done!',
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppTheme.sleepColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepArcPainter extends CustomPainter {
  final double progress;
  _SleepArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Track
    final trackPaint = Paint()
      ..color = AppTheme.surfaceVariantDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Progress
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9C27B0), Color(0xFFBA68C8), Color(0xFFE1BEE7)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_SleepArcPainter old) => old.progress != progress;
}
