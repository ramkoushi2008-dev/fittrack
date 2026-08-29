import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class MetricTabSelectorWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const MetricTabSelectorWidget({
    required this.selectedIndex,
    required this.onTabSelected,
    super.key,
  });

  static const List<Map<String, dynamic>> _tabs = [
    {'label': 'Steps', 'icon': Icons.directions_walk_rounded},
    {'label': 'Calories', 'icon': Icons.local_fire_department_outlined},
    {'label': 'Active Min', 'icon': Icons.timer_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isSelected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _tabs[i]['icon'] as IconData,
                      size: 14,
                      color: isSelected
                          ? const Color(0xFF1A1A1A)
                          : context.appTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _tabs[i]['label'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF1A1A1A)
                            : context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
