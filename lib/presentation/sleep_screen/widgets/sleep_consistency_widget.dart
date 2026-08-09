import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SleepConsistencyWidget extends StatelessWidget {
  const SleepConsistencyWidget({super.key});

  static const List<Map<String, dynamic>> _metrics = [
    {
      'label': 'Consistency',
      'value': '78%',
      'sub': 'Last 7 days',
      'icon': Icons.repeat_rounded,
      'color': Color(0xFFBA68C8),
    },
    {
      'label': 'Weekly Avg',
      'value': '7h 09m',
      'sub': 'vs 8h goal',
      'icon': Icons.bar_chart_rounded,
      'color': Color(0xFF64B5F6),
    },
    {
      'label': 'Best Night',
      'value': '8h 00m',
      'sub': 'Thursday',
      'icon': Icons.star_rounded,
      'color': Color(0xFFFFB300),
    },
    {
      'label': 'Streak',
      'value': '3 days',
      'sub': 'On target',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFFF7043),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sleep Insights',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: _metrics.length,
          itemBuilder: (context, i) {
            final m = _metrics[i];
            final color = m['color'] as Color;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withAlpha(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          m['icon'] as IconData,
                          size: 14,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['value'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        m['label'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        m['sub'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
