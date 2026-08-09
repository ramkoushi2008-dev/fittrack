import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class ExerciseCardWidget extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onToggleComplete;
  final VoidCallback onAdjust;

  const ExerciseCardWidget({
    required this.exercise,
    required this.onToggleComplete,
    required this.onAdjust,
    super.key,
  });

  BadgeStatus _difficultyStatus(String difficulty) {
    switch (difficulty) {
      case 'Advanced':
        return BadgeStatus.warning;
      case 'Intermediate':
        return BadgeStatus.active;
      default:
        return BadgeStatus.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = exercise['completed'] as bool;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.primaryContainer : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? AppTheme.primary.withAlpha(102)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.primary.withAlpha(51)
                      : AppTheme.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  exercise['icon'] as IconData,
                  color: isCompleted
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['name'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise['muscleGroup'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggleComplete,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.primary
                        : AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCompleted
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Color(0xFF1A1A1A),
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Metrics row
          Row(
            children: [
              _ExerciseStat(
                icon: Icons.repeat_rounded,
                label: '${exercise['sets']} × ${exercise['reps']}',
              ),
              const SizedBox(width: 16),
              _ExerciseStat(
                icon: Icons.timer_outlined,
                label: '${exercise['restSec']}s rest',
              ),
              const SizedBox(width: 16),
              _ExerciseStat(
                icon: Icons.monitor_weight_outlined,
                label: exercise['weight'] as String,
              ),
              const Spacer(),
              StatusBadgeWidget(
                label: exercise['difficulty'] as String,
                status: _difficultyStatus(exercise['difficulty'] as String),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Adjust button
          GestureDetector(
            onTap: onAdjust,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantDark,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Adjust',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ExerciseStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
