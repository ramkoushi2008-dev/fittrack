import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SleepQuickAddWidget extends StatefulWidget {
  final Function(double hours) onSleepAdded;
  const SleepQuickAddWidget({required this.onSleepAdded, super.key});

  @override
  State<SleepQuickAddWidget> createState() => _SleepQuickAddWidgetState();
}

class _SleepQuickAddWidgetState extends State<SleepQuickAddWidget> {
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  bool _showCustom = false;

  static const List<Map<String, dynamic>> _quickOptions = [
    {'label': '6h', 'hours': 6.0, 'icon': Icons.bedtime_outlined},
    {'label': '6h 30m', 'hours': 6.5, 'icon': Icons.bedtime_outlined},
    {'label': '7h', 'hours': 7.0, 'icon': Icons.bedtime_rounded},
    {'label': '7h 30m', 'hours': 7.5, 'icon': Icons.bedtime_rounded},
    {'label': '8h', 'hours': 8.0, 'icon': Icons.nightlight_round},
    {'label': '9h', 'hours': 9.0, 'icon': Icons.nightlight_round},
  ];

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _logCustomSleep() {
    final h = double.tryParse(_hoursController.text) ?? 0;
    final m = double.tryParse(_minutesController.text) ?? 0;
    final total = h + (m / 60);
    if (total > 0 && total <= 24) {
      widget.onSleepAdded(total);
      _hoursController.clear();
      _minutesController.clear();
      setState(() => _showCustom = false);
      _showSnack(total);
    }
  }

  void _showSnack(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sleep logged: ${h}h ${m.toString().padLeft(2, '0')}m',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.sleepColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.sleepColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppTheme.sleepColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Log Sleep',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showCustom = !_showCustom),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _showCustom
                        ? AppTheme.sleepColor.withAlpha(30)
                        : AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(50),
                    border: _showCustom
                        ? Border.all(color: AppTheme.sleepColor.withAlpha(80))
                        : null,
                  ),
                  child: Text(
                    'Custom',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _showCustom
                          ? AppTheme.sleepColor
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickOptions.map((opt) {
              return GestureDetector(
                onTap: () {
                  widget.onSleepAdded(opt['hours'] as double);
                  _showSnack(opt['hours'] as double);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppTheme.sleepColor.withAlpha(40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        opt['icon'] as IconData,
                        size: 14,
                        color: AppTheme.sleepColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        opt['label'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // Custom input
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _showCustom
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter duration',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _hoursController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.manrope(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Hours',
                                  hintStyle: GoogleFonts.manrope(
                                    color: AppTheme.textMuted,
                                    fontSize: 13,
                                  ),
                                  suffixText: 'h',
                                  suffixStyle: GoogleFonts.manrope(
                                    color: AppTheme.sleepColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.surfaceVariantDark,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _minutesController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.manrope(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Minutes',
                                  hintStyle: GoogleFonts.manrope(
                                    color: AppTheme.textMuted,
                                    fontSize: 13,
                                  ),
                                  suffixText: 'm',
                                  suffixStyle: GoogleFonts.manrope(
                                    color: AppTheme.sleepColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.surfaceVariantDark,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _logCustomSleep,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.sleepColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
