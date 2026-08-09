import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class QuestionnaireStepWidget extends StatefulWidget {
  final Map<String, dynamic> step;
  final int stepIndex;
  final Map<String, dynamic> answers;
  final Function(String key, dynamic value) onAnswerChanged;
  final VoidCallback onNext;
  final bool isLast;

  const QuestionnaireStepWidget({
    required this.step,
    required this.stepIndex,
    required this.answers,
    required this.onAnswerChanged,
    required this.onNext,
    required this.isLast,
    super.key,
  });

  @override
  State<QuestionnaireStepWidget> createState() =>
      _QuestionnaireStepWidgetState();
}

class _QuestionnaireStepWidgetState extends State<QuestionnaireStepWidget> {
  // TODO: Replace with [Riverpod/Bloc] for production
  final _ageController = TextEditingController(text: '28');
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '72');
  String _selectedGender = 'Male';
  String _selectedActivity = 'Moderately Active';

  // Schedule
  int _daysPerWeek = 4;
  int _workoutDuration = 60;

  // Lifestyle
  int _sleepHours = 7;
  int _dailySteps = 6000;

  @override
  void initState() {
    super.initState();
    // Seed default values into answers so they're always present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncBasicInfo();
      _syncSchedule();
      _syncLifestyle();
    });
    _ageController.addListener(_syncBasicInfo);
    _heightController.addListener(_syncBasicInfo);
    _weightController.addListener(_syncBasicInfo);
  }

  void _syncBasicInfo() {
    widget.onAnswerChanged('age', _ageController.text);
    widget.onAnswerChanged('height', _heightController.text);
    widget.onAnswerChanged('weight', _weightController.text);
    widget.onAnswerChanged('gender', _selectedGender);
    widget.onAnswerChanged('activityLevel', _selectedActivity);
  }

  void _syncSchedule() {
    widget.onAnswerChanged('daysPerWeek', _daysPerWeek);
    widget.onAnswerChanged('workoutDuration', _workoutDuration);
  }

  void _syncLifestyle() {
    widget.onAnswerChanged('sleepHours', _sleepHours);
    widget.onAnswerChanged('dailySteps', _dailySteps);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            widget.step['title'] as String,
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.step['subtitle'] as String,
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildStepContent(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              child: Text(widget.isLast ? 'Create My Plan' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (widget.step['type'] as String) {
      case 'basic_info':
        return _buildBasicInfo();
      case 'experience':
        return _buildSingleSelect('experience');
      case 'multi_select':
        return _buildMultiSelect();
      case 'schedule':
        return _buildSchedule();
      case 'single_select':
        return _buildSingleSelect('preference');
      case 'lifestyle':
        return _buildLifestyle();
      case 'final_info':
        return _buildFinalInfo();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLabeledField(
                label: 'Age',
                controller: _ageController,
                suffix: 'yrs',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledField(
                label: 'Height',
                controller: _heightController,
                suffix: 'cm',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildLabeledField(
                label: 'Weight',
                controller: _weightController,
                suffix: 'kg',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gender',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF3A3A3A)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        dropdownColor: AppTheme.surfaceVariantDark,
                        style: GoogleFonts.manrope(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                        items: ['Male', 'Female', 'Other', 'Prefer not to say']
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedGender = v!);
                          _syncBasicInfo();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Level',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    'Sedentary',
                    'Lightly Active',
                    'Moderately Active',
                    'Very Active',
                    'Extremely Active',
                  ].map((level) {
                    final isSelected = _selectedActivity == level;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedActivity = level);
                        _syncBasicInfo();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryContainer
                              : AppTheme.surfaceVariantDark,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          level,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.manrope(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: GoogleFonts.manrope(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleSelect(String key) {
    final options = (widget.step['options'] as List<String>);
    final selected = widget.answers[key] as String?;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () {
            setState(() {});
            widget.onAnswerChanged(key, opt);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryContainer
                  : AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              opt,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelect() {
    final key = widget.step['type'] == 'multi_select'
        ? 'goals_${widget.stepIndex}'
        : 'equipment';
    final options = (widget.step['options'] as List<String>);
    final selected = (widget.answers[key] as List<String>?) ?? <String>[];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: () {
            final newSelected = List<String>.from(selected);
            if (isSelected) {
              newSelected.remove(opt);
            } else {
              newSelected.add(opt);
            }
            setState(() {});
            widget.onAnswerChanged(key, newSelected);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryContainer
                  : AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  opt,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSchedule() {
    return Column(
      children: [
        _buildStepperRow(
          label: 'Days per week',
          value: _daysPerWeek,
          min: 1,
          max: 7,
          onChanged: (v) {
            setState(() => _daysPerWeek = v);
            _syncSchedule();
          },
        ),
        const SizedBox(height: 20),
        _buildStepperRow(
          label: 'Workout duration',
          value: _workoutDuration,
          min: 20,
          max: 120,
          step: 10,
          suffix: 'min',
          onChanged: (v) {
            setState(() => _workoutDuration = v);
            _syncSchedule();
          },
        ),
      ],
    );
  }

  Widget _buildLifestyle() {
    return Column(
      children: [
        _buildStepperRow(
          label: 'Average sleep duration',
          value: _sleepHours,
          min: 4,
          max: 12,
          suffix: 'hrs',
          onChanged: (v) {
            setState(() => _sleepHours = v);
            _syncLifestyle();
          },
        ),
        const SizedBox(height: 20),
        _buildStepperRow(
          label: 'Daily steps (approx)',
          value: _dailySteps,
          min: 1000,
          max: 20000,
          step: 1000,
          suffix: 'steps',
          onChanged: (v) {
            setState(() => _dailySteps = v);
            _syncLifestyle();
          },
        ),
      ],
    );
  }

  Widget _buildFinalInfo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppTheme.primary,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'You\'re all set!',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll create a personalized fitness plan based on your goals, experience, and lifestyle.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recommendations are general fitness guidance. Consult a qualified professional for medical concerns.',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepperRow({
    required String label,
    required int value,
    required int min,
    required int max,
    int step = 1,
    String suffix = '',
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value $suffix',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                onTap: value - step >= min
                    ? () => onChanged(value - step)
                    : null,
              ),
              const SizedBox(width: 8),
              _StepperButton(
                icon: Icons.add_rounded,
                onTap: value + step <= max
                    ? () => onChanged(value + step)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap != null ? AppTheme.primary : AppTheme.surfaceVariantDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? const Color(0xFF1A1A1A) : AppTheme.textMuted,
        ),
      ),
    );
  }
}
