import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class ActivityCardGridWidget extends StatefulWidget {
  const ActivityCardGridWidget({super.key});

  @override
  State<ActivityCardGridWidget> createState() => _ActivityCardGridWidgetState();
}

class _ActivityCardGridWidgetState extends State<ActivityCardGridWidget> {
  // TODO: Replace with [Riverpod/Bloc] for production
  int _selectedFilter = 0;
  final List<String> _filters = ['Cycling', 'Running', 'Rowing', 'HIIT'];

  static final List<Map<String, dynamic>> _activities = [
    {
      'title': 'Spin Bike',
      'duration': '30 Min',
      'reps': '4×30 reps',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1f208e6e0-1772818397257.png',
      'semanticLabel':
          'Person on a stationary spin bike in a gym class with blue lighting',
    },
    {
      'title': 'Indoor Cycling',
      'duration': '45 Min',
      'reps': '4×30 reps',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1f208e6e0-1772818397257.png',
      'semanticLabel':
          'Group indoor cycling class with multiple people on bikes in bright gym',
    },
    {
      'title': 'Trail Run',
      'duration': '40 Min',
      'reps': '5 km',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_142a1916a-1772168375622.png',
      'semanticLabel':
          'Runner on a forest trail path in morning sunlight wearing running gear',
    },
    {
      'title': 'Rowing',
      'duration': '25 Min',
      'reps': '3×500m',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_193541fc5-1786141847341.png',
      'semanticLabel':
          'Person using rowing machine in modern gym with focused expression',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final isSelected = i == _selectedFilter;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : context.appSurface,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    _filters[i],
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF1A1A1A)
                          : context.appTextSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // 2-col grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _activities.length,
            itemBuilder: (context, i) {
              return _ActivityCard(activity: _activities[i]);
            },
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomImageWidget(
            imageUrl: activity['imageUrl'] as String,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: activity['semanticLabel'] as String,
          ),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
                stops: [0.4, 1.0],
              ),
            ),
          ),
          // Meta chips top-left
          Positioned(
            top: 10,
            left: 10,
            child: Row(
              children: [
                _MetaChip(
                  label: activity['duration'] as String,
                  icon: Icons.timer_outlined,
                ),
                const SizedBox(width: 6),
                _MetaChip(
                  label: activity['reps'] as String,
                  icon: Icons.repeat_rounded,
                ),
              ],
            ),
          ),
          // Title bottom
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Text(
              activity['title'] as String,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
