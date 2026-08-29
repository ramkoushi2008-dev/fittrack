import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class WorkoutHistoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> workoutData;

  const WorkoutHistoryCardWidget({required this.workoutData, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + date row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                workoutData['name'] as String,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
              Text(
                workoutData['date'] as String,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: context.appTextMuted,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Duration + reps row
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 13,
                color: context.appTextSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                workoutData['duration'] as String,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: context.appTextSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.repeat_rounded,
                size: 13,
                color: context.appTextSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                workoutData['reps'] as String,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 3-metric row: Calories / Heart Rate / Bpm
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.local_fire_department_outlined,
                  color: AppTheme.caloriesColor,
                  label: 'Calories',
                  value: workoutData['calories'] as String,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.favorite_outline_rounded,
                  color: AppTheme.error,
                  label: 'Heart Rate',
                  value: workoutData['heartRate'] as String,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.speed_rounded,
                  color: AppTheme.stepsColor,
                  label: 'Bpm',
                  value: workoutData['bpm'] as String,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: context.appTextMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
