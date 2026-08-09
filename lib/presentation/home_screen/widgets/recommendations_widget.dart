import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class RecommendationsWidget extends StatelessWidget {
  const RecommendationsWidget({super.key});

  static final List<Map<String, dynamic>> _recommendations = [
    {
      'icon': Icons.directions_walk_rounded,
      'color': AppTheme.stepsColor,
      'text':
          'Take a 20-minute walk to reach your step goal — you\'re 2,760 steps away.',
    },
    {
      'icon': Icons.water_drop_outlined,
      'color': AppTheme.waterColor,
      'text':
          'You\'re 1.2L below your water target. Drink a glass before your next meal.',
    },
    {
      'icon': Icons.egg_outlined,
      'color': AppTheme.proteinColor,
      'text':
          '38g protein remaining. Consider adding curd or paneer to your dinner.',
    },
    {
      'icon': Icons.bedtime_outlined,
      'color': AppTheme.sleepColor,
      'text':
          'Great sleep last night! Aim for the same bedtime tonight for consistency.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Recommendations',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '4 tips',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._recommendations.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecommendationCard(
              recommendation: entry.value,
              index: entry.key,
            ),
          );
        }),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> recommendation;
  final int index;
  const _RecommendationCard({
    required this.recommendation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = recommendation['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              recommendation['icon'] as IconData,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation['text'] as String,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
