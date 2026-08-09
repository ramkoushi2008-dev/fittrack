import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';

class ActivityBarChartWidget extends StatelessWidget {
  final int selectedMetric;
  const ActivityBarChartWidget({required this.selectedMetric, super.key});

  static const List<List<double>> _chartData = [
    // Steps (thousands)
    [6.2, 8.4, 7.2, 9.1, 5.8, 10.2, 7.4, 8.8, 7.2],
    // Calories (hundreds)
    [8.0, 12.4, 10.2, 14.0, 7.2, 16.8, 11.0, 13.9, 10.2],
    // Active minutes
    [35, 52, 48, 61, 30, 72, 44, 58, 48],
  ];

  static const List<String> _dateLabels = [
    '09',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
  ];

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
    'Mon',
    'Tue',
  ];

  @override
  Widget build(BuildContext context) {
    final data = _chartData[selectedMetric];
    final color = selectedMetric == 0
        ? AppTheme.stepsColor
        : selectedMetric == 1
        ? AppTheme.caloriesColor
        : AppTheme.workoutColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedMetric == 0
                    ? '7,240 steps today'
                    : selectedMetric == 1
                    ? '1,390 Kcal today'
                    : '48 min today',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    Text(
                      'Days',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.reduce((a, b) => a > b ? a : b) * 1.3,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toStringAsFixed(1),
                        GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= _dateLabels.length) return const SizedBox();
                        return Column(
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              _dateLabels[i],
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Text(
                              _dayLabels[i],
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        );
                      },
                      reservedSize: 36,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.surfaceVariantDark,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final isToday = entry.key == 2;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: isToday ? color : color.withAlpha(102),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
