import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../services/screen_time_service.dart';

class SleepSuggestionCardWidget extends StatelessWidget {
  final SleepSuggestion suggestion;
  final VoidCallback onConfirm;
  final VoidCallback onAdjust;
  final VoidCallback onDismiss;

  const SleepSuggestionCardWidget({
    required this.suggestion,
    required this.onConfirm,
    required this.onAdjust,
    required this.onDismiss,
    super.key,
  });

  String _fmtTime(DateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final h = suggestion.duration.inMinutes ~/ 60;
    final m = suggestion.duration.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.sleepColor.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.sleepColor.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.sleepColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your screen was off from ${_fmtTime(suggestion.bedtime)} '
                  'to ${_fmtTime(suggestion.wakeTime)} (${h}h '
                  '${m.toString().padLeft(2, '0')}m). Log this as last '
                  "night's sleep?",
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.sleepColor,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onAdjust,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: AppTheme.sleepColor.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      'Adjust',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
