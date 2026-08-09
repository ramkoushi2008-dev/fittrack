import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../../theme/app_theme.dart';

class WorkoutTimerBarWidget extends StatefulWidget {
  final bool workoutStarted;
  final int completedCount;
  final int totalCount;
  final VoidCallback onStartStop;

  const WorkoutTimerBarWidget({
    required this.workoutStarted,
    required this.completedCount,
    required this.totalCount,
    required this.onStartStop,
    super.key,
  });

  @override
  State<WorkoutTimerBarWidget> createState() => _WorkoutTimerBarWidgetState();
}

class _WorkoutTimerBarWidgetState extends State<WorkoutTimerBarWidget> {
  // TODO: Replace with [Riverpod/Bloc] for production
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void didUpdateWidget(WorkoutTimerBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workoutStarted && !oldWidget.workoutStarted) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsedSeconds++);
      });
    } else if (!widget.workoutStarted && oldWidget.workoutStarted) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundDark,
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 80,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: widget.workoutStarted
              ? AppTheme.primary
              : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: widget.workoutStarted
              ? null
              : Border.all(color: AppTheme.primary.withAlpha(77)),
        ),
        child: Row(
          children: [
            // Timer
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.workoutStarted ? 'Active Workout' : 'Ready to Train',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: widget.workoutStarted
                        ? const Color(0xFF1A1A1A).withAlpha(179)
                        : AppTheme.textSecondary,
                  ),
                ),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: widget.workoutStarted
                        ? const Color(0xFF1A1A1A)
                        : AppTheme.textPrimary,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Progress
            Text(
              '${widget.completedCount}/${widget.totalCount}',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.workoutStarted
                    ? const Color(0xFF1A1A1A)
                    : AppTheme.textSecondary,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 16),
            // Start/Stop button
            GestureDetector(
              onTap: widget.onStartStop,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.workoutStarted
                      ? const Color(0xFF1A1A1A)
                      : AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.workoutStarted
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: widget.workoutStarted
                      ? AppTheme.primary
                      : const Color(0xFF1A1A1A),
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
