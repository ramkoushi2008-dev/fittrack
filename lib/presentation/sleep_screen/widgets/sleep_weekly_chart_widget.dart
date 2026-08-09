import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';

class SleepWeeklyChartWidget extends StatelessWidget {
  const SleepWeeklyChartWidget({super.key});

  static const List<double> _sleepData = [6.5, 7.2, 5.8, 8.0, 7.5, 6.0, 7.75];
  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const double _target = 8.0;

  @override
  Widget build(BuildContext context) {
    final avg = _sleepData.reduce((a, b) => a + b) / _sleepData.length;
    final avgH = avg.floor();
    final avgM = ((avg - avgH) * 60).round();

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Sleep',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Avg: ${avgH}h ${avgM.toString().padLeft(2, '0')}m / night',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppTheme.sleepColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'This week',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final h = rod.toY.floor();
                      final m = ((rod.toY - h) * 60).round();
                      return BarTooltipItem(
                        '${h}h ${m.toString().padLeft(2, '0')}m',
                        GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
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
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 != 0) return const SizedBox();
                        return Text(
                          '${value.toInt()}h',
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            color: AppTheme.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= _days.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _days[i],
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: i == 6
                                  ? AppTheme.sleepColor
                                  : AppTheme.textMuted,
                              fontWeight: i == 6
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    if (value == _target) {
                      return FlLine(
                        color: AppTheme.sleepColor.withAlpha(80),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      );
                    }
                    return FlLine(
                      color: AppTheme.surfaceVariantDark,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _sleepData.asMap().entries.map((entry) {
                  final isToday = entry.key == 6;
                  final metTarget = entry.value >= _target;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: isToday
                            ? AppTheme.sleepColor
                            : metTarget
                            ? AppTheme.sleepColor.withAlpha(140)
                            : AppTheme.sleepColor.withAlpha(70),
                        width: 22,
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
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: AppTheme.sleepColor, label: 'Met target'),
              const SizedBox(width: 16),
              _LegendDot(
                color: AppTheme.sleepColor.withAlpha(70),
                label: 'Below target',
              ),
              const Spacer(),
              Container(
                width: 24,
                height: 2,
                decoration: BoxDecoration(
                  color: AppTheme.sleepColor.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '8h target',
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
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
