import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class MetricCardsRowWidget extends StatelessWidget {
  final bool vertical;
  const MetricCardsRowWidget({this.vertical = false, super.key});

  static final List<Map<String, dynamic>> _metrics = [
    {
      'label': 'Steps',
      'current': '7,240',
      'target': '10,000',
      'unit': 'steps',
      'progress': 0.724,
      'color': AppTheme.stepsColor,
      'icon': Icons.directions_walk_rounded,
    },
    {
      'label': 'Water',
      'current': '1.8L',
      'target': '3.0L',
      'unit': '',
      'progress': 0.6,
      'color': AppTheme.waterColor,
      'icon': Icons.water_drop_outlined,
    },
    {
      'label': 'Protein',
      'current': '82g',
      'target': '120g',
      'unit': '',
      'progress': 0.68,
      'color': AppTheme.proteinColor,
      'icon': Icons.egg_outlined,
    },
    {
      'label': 'Sleep',
      'current': '7h 10m',
      'target': '8h',
      'unit': '',
      'progress': 0.89,
      'color': AppTheme.sleepColor,
      'icon': Icons.bedtime_outlined,
    },
    {
      'label': 'Workout',
      'current': 'Done',
      'target': 'Today',
      'unit': '',
      'progress': 1.0,
      'color': AppTheme.workoutColor,
      'icon': Icons.fitness_center_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        children: _metrics
            .map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MetricCard(metric: m),
              ),
            )
            .toList(),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _MetricCard(metric: _metrics[i]),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final Map<String, dynamic> metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final color = metric['color'] as Color;
    final progress = metric['progress'] as double;

    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(metric['icon'] as IconData, color: color, size: 18),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            metric['label'] as String,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: context.appTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric['current'] as String,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.appTextPrimary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withAlpha(38),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
