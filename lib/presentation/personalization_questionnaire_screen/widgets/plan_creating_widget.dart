import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PlanCreatingWidget extends StatefulWidget {
  const PlanCreatingWidget({super.key});

  @override
  State<PlanCreatingWidget> createState() => _PlanCreatingWidgetState();
}

class _PlanCreatingWidgetState extends State<PlanCreatingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulse;
  late Animation<double> _progress;
  int _currentMessage = 0;

  final List<String> _messages = [
    'Analyzing your fitness goals...',
    'Calculating your optimal training volume...',
    'Selecting the best exercises for you...',
    'Building your personalized plan...',
    'Almost ready!',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Cycle through messages
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted && _currentMessage < _messages.length - 1) {
        setState(() => _currentMessage++);
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withAlpha(128),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppTheme.primary,
                    size: 52,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Creating Your\nPersonalized Plan',
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _messages[_currentMessage],
                  key: ValueKey(_currentMessage),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: _progress,
                builder: (context, child) {
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress.value,
                          backgroundColor: AppTheme.surfaceVariantDark,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progress.value * 100).toInt()}%',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
