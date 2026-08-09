import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class WeekDaySelectorWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDaySelected;

  const WeekDaySelectorWidget({
    required this.selectedIndex,
    required this.onDaySelected,
    super.key,
  });

  static final List<Map<String, String>> _days = [
    {'day': 'Mon', 'date': '04'},
    {'day': 'Tue', 'date': '05'},
    {'day': 'Wed', 'date': '06'},
    {'day': 'Thu', 'date': '07'},
    {'day': 'Fri', 'date': '08'},
    {'day': 'Sat', 'date': '09'},
    {'day': 'Sun', 'date': '10'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onDaySelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _days[i]['day']!,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF1A1A1A)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _days[i]['date']!,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? const Color(0xFF1A1A1A)
                          : AppTheme.textPrimary,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
