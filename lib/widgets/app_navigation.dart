import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class _TabSpec {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int? branchIndex;

  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _pillController;
  int _selectedVisualIndex = 0;

  final List<_TabSpec> _tabs = const [
    _TabSpec(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Workout',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center_rounded,
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'Activity',
      icon: Icons.directions_run_outlined,
      selectedIcon: Icons.directions_run_rounded,
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'Nutrition',
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant_rounded,
      branchIndex: 3,
    ),
    _TabSpec(
      label: 'Sleep',
      icon: Icons.bedtime_outlined,
      selectedIcon: Icons.bedtime_rounded,
      branchIndex: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectedVisualIndex = widget.navigationShell.currentIndex;
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  void _onTabTap(int visualIndex) {
    final tab = _tabs[visualIndex];
    if (tab.branchIndex == null) {
      // Stub tab — silent ignore
      return;
    }
    setState(() => _selectedVisualIndex = visualIndex);
    widget.navigationShell.goBranch(
      tab.branchIndex!,
      initialLocation: tab.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantDark,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(89),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            final isActive = i == _selectedVisualIndex;
            final isStub = tab.branchIndex == null;

            return GestureDetector(
              onTap: () => _onTabTap(i),
              behavior: HitTestBehavior.opaque,
              child: Opacity(
                opacity: isStub ? 0.4 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? tab.selectedIcon : tab.icon,
                        size: 22,
                        color: isActive
                            ? const Color(0xFF1A1A1A)
                            : AppTheme.textSecondary,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: isActive
                            ? Row(
                                children: [
                                  const SizedBox(width: 6),
                                  Text(
                                    tab.label,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
