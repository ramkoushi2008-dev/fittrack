import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';

class ActivityBarChartWidget extends StatelessWidget {
  final int selectedMetric;

  /// Live daily series for each tab, oldest first. Null falls back to demo
  /// data for that tab.
  final List<double>? dailySteps;
  final List<double>? dailyCalories;
  final List<double>? dailyActiveMinutes;

  const ActivityBarChartWidget({
    required this.selectedMetric,
    this.dailySteps,
    this.dailyCalories,
    this.dailyActiveMinutes,
    super.key,
  });

  static const List<List<double>> _demoChartData = [
    // Steps (thousands)
    [6.2, 8.4, 7.2, 9.1, 5.8, 10.2, 7.4, 8.8, 7.2],
    // Calories (hundreds)
    [8.0, 12.4, 10.2, 14.0, 7.2, 16.8, 11.0, 13.9, 10.2],
    // Active minutes
    [35, 52, 48, 61, 30, 72, 44, 58, 48],
  ];

  List<String> _dateLabels(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final day = now.subtract(Duration(days: count - 1 - i));
      return day.day.toString().padLeft(2, '0');
    });
  }

  List<String> _dayLabels(int count) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return List.generate(count, (i) {
      final day = now.subtract(Duration(days: count - 1 - i));
      return names[day.weekday - 1];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Steps display in thousands, calories in hundreds, to keep bars a
    // readable height; active minutes are shown as-is.
    List<double> data;
    switch (selectedMetric) {
      case 0:
        data = dailySteps != null
            ? dailySteps!.map((v) => v / 1000).toList()
            : _demoChartData[0];
        break;
      case 1:
        data = dailyCalories != null
            ? dailyCalories!.map((v) => v / 100).toList()
            : _demoChartData[1];
        break;
      default:
        data = dailyActiveMinutes ?? _demoChartData[2];
    }
    final dateLabels = _dateLabels(data.length);
    final dayLabels = _dayLabels(data.length);
    final color = selectedMetric == 0
        ? AppTheme.stepsColor
        : selectedMetric == 1
        ? AppTheme.caloriesColor
        : AppTheme.workoutColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurface,
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
                    ? (dailySteps != null && dailySteps!.isNotEmpty
                          ? '${dailySteps!.last.round()} steps today'
                          : '7,240 steps today')
                    : selectedMetric == 1
                    ? (dailyCalories != null && dailyCalories!.isNotEmpty
                          ? '${dailyCalories!.last.round()} Kcal today'
                          : '1,390 Kcal today')
                    : (dailyActiveMinutes != null &&
                              dailyActiveMinutes!.isNotEmpty
                          ? '${dailyActiveMinutes!.last.round()} min today'
                          : '48 min today'),
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
                  color: context.appSurfaceVariant,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    Text(
                      'Days',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: context.appTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: context.appTextSecondary,
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
                maxY:
                    (data.isEmpty
                        ? 1.0
                        : data.reduce((a, b) => a > b ? a : b)) *
                    1.3,
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
                        if (i >= dateLabels.length) return const SizedBox();
                        return Column(
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              dateLabels[i],
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: context.appTextMuted,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Text(
                              dayLabels[i],
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                color: context.appTextMuted,
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
                    color: context.appSurfaceVariant,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final isToday = entry.key == data.length - 1;
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
