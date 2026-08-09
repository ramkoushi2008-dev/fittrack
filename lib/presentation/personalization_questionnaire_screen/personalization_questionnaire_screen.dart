import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/plan_creating_widget.dart';
import './widgets/questionnaire_step_widget.dart';

class PersonalizationQuestionnaireScreen extends StatefulWidget {
  const PersonalizationQuestionnaireScreen({super.key});

  @override
  State<PersonalizationQuestionnaireScreen> createState() =>
      _PersonalizationQuestionnaireScreenState();
}

class _PersonalizationQuestionnaireScreenState
    extends State<PersonalizationQuestionnaireScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with [Riverpod/Bloc] for production
  int _currentStep = 0;
  bool _creatingPlan = false;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late PageController _pageController;

  final Map<String, dynamic> _answers = {};

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Basic Information',
      'subtitle': 'Let\'s start with the essentials',
      'type': 'basic_info',
    },
    {
      'title': 'Fitness Experience',
      'subtitle': 'How experienced are you?',
      'type': 'experience',
      'options': ['Beginner', 'Intermediate', 'Advanced'],
    },
    {
      'title': 'Main Goal',
      'subtitle': 'What do you want to achieve?',
      'type': 'multi_select',
      'options': [
        'Build Muscle',
        'Lose Fat',
        'Improve Fitness',
        'Increase Strength',
        'Improve Endurance',
        'Maintain Fitness',
      ],
    },
    {
      'title': 'Workout Schedule',
      'subtitle': 'How often can you train?',
      'type': 'schedule',
    },
    {
      'title': 'Training Preference',
      'subtitle': 'Where do you prefer to train?',
      'type': 'single_select',
      'options': ['Gym', 'Home', 'Bodyweight', 'Mixed'],
    },
    {
      'title': 'Available Equipment',
      'subtitle': 'What equipment do you have access to?',
      'type': 'multi_select',
      'options': [
        'Dumbbells',
        'Barbells',
        'Machines',
        'Resistance Bands',
        'Pull-up Bar',
        'No Equipment',
        'Other',
      ],
    },
    {
      'title': 'Lifestyle',
      'subtitle': 'Help us understand your daily routine',
      'type': 'lifestyle',
    },
    {
      'title': 'Almost Done!',
      'subtitle': 'A few more details to personalize your plan',
      'type': 'final_info',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnimation =
        Tween<double>(begin: 1 / _steps.length, end: 1 / _steps.length).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate current step before proceeding
    if (!_isCurrentStepAnswered()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one option to continue.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      final targetProgress = (_currentStep + 1) / _steps.length;
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: targetProgress,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeOutCubic,
            ),
          );
      _progressController
        ..reset()
        ..forward();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishQuestionnaire();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      final targetProgress = (_currentStep + 1) / _steps.length;
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: targetProgress,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeOutCubic,
            ),
          );
      _progressController
        ..reset()
        ..forward();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _isCurrentStepAnswered() {
    final stepType = _steps[_currentStep]['type'] as String;
    switch (stepType) {
      case 'experience':
        return _answers.containsKey('experience') &&
            (_answers['experience'] as String?)?.isNotEmpty == true;
      case 'multi_select':
        final key = 'goals_$_currentStep';
        final selected = _answers[key] as List<String>?;
        return selected != null && selected.isNotEmpty;
      case 'single_select':
        return _answers.containsKey('preference') &&
            (_answers['preference'] as String?)?.isNotEmpty == true;
      // basic_info, schedule, lifestyle, final_info have stepper/text inputs
      // that always have default values — no mandatory check needed
      default:
        return true;
    }
  }

  Future<void> _finishQuestionnaire() async {
    setState(() => _creatingPlan = true);
    // Save all answers to SharedPreferences so WorkoutScreen can use them
    try {
      final prefs = await SharedPreferences.getInstance();
      // Serialize answers — convert Lists to JSON strings
      final serializable = <String, dynamic>{};
      _answers.forEach((key, value) {
        if (value is List) {
          serializable[key] = jsonEncode(value);
        } else {
          serializable[key] = value.toString();
        }
      });
      await prefs.setString('questionnaire_answers', jsonEncode(serializable));
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go(AppRoutes.homeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_creatingPlan) {
      return const PlanCreatingWidget();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_currentStep > 0)
                        GestureDetector(
                          onTap: _prevStep,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariantDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppTheme.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        'Step ${_currentStep + 1} of ${_steps.length}',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: AppTheme.surfaceVariantDark,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                          minHeight: 4,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return QuestionnaireStepWidget(
                    step: _steps[index],
                    stepIndex: index,
                    answers: _answers,
                    onAnswerChanged: (key, value) {
                      setState(() => _answers[key] = value);
                    },
                    onNext: _nextStep,
                    isLast: index == _steps.length - 1,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
