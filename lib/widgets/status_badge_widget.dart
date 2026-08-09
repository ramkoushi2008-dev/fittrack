import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BadgeStatus { completed, active, pending, warning, info, custom }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final BadgeStatus status;
  final Color? customColor;
  final double fontSize;

  const StatusBadgeWidget({
    required this.label,
    this.status = BadgeStatus.active,
    this.customColor,
    this.fontSize = 11,
    super.key,
  });

  Color _bgColor() {
    switch (status) {
      case BadgeStatus.completed:
        return const Color(0xFF2D7A4F).withAlpha(51);
      case BadgeStatus.active:
        return const Color(0xFFC6F135).withAlpha(38);
      case BadgeStatus.pending:
        return const Color(0xFFFFB300).withAlpha(38);
      case BadgeStatus.warning:
        return const Color(0xFFFF7043).withAlpha(38);
      case BadgeStatus.info:
        return const Color(0xFF64B5F6).withAlpha(38);
      case BadgeStatus.custom:
        return (customColor ?? const Color(0xFFC6F135)).withAlpha(38);
    }
  }

  Color _textColor() {
    switch (status) {
      case BadgeStatus.completed:
        return const Color(0xFF4CAF50);
      case BadgeStatus.active:
        return const Color(0xFFC6F135);
      case BadgeStatus.pending:
        return const Color(0xFFFFB300);
      case BadgeStatus.warning:
        return const Color(0xFFFF7043);
      case BadgeStatus.info:
        return const Color(0xFF64B5F6);
      case BadgeStatus.custom:
        return customColor ?? const Color(0xFFC6F135);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: _textColor(),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
