import 'package:flutter/material.dart';
import '../../../core/theme/wisteria_theme.dart';

/// Centralized age categories for patient avatar selection.
enum PatientAgeCategory {
  child,
  teenager,
  adult,
  senior,
}

/// Centralized deterministic age-to-category mapping.
PatientAgeCategory getPatientAgeCategory(int? age) {
  if (age == null) return PatientAgeCategory.adult;
  if (age <= 12) return PatientAgeCategory.child;
  if (age <= 19) return PatientAgeCategory.teenager;
  if (age <= 59) return PatientAgeCategory.adult;
  return PatientAgeCategory.senior;
}

/// Returns a human-readable label for the age category.
String getAgeCategoryLabel(PatientAgeCategory category) {
  switch (category) {
    case PatientAgeCategory.child:
      return 'Child (0–12 yrs)';
    case PatientAgeCategory.teenager:
      return 'Teenager (13–19 yrs)';
    case PatientAgeCategory.adult:
      return 'Adult (20–59 yrs)';
    case PatientAgeCategory.senior:
      return 'Senior (60+ yrs)';
  }
}

/// Theme-aware, age-appropriate offline vector avatar for patient records.
class PatientAgeAvatar extends StatelessWidget {
  final int? age;
  final double size;
  final Color? customAccent;

  const PatientAgeAvatar({
    super.key,
    required this.age,
    this.size = 48.0,
    this.customAccent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = WisteriaColors.of(context);
    final category = getPatientAgeCategory(age);
    final accent = customAccent ?? colors.primary;

    return Tooltip(
      message: getAgeCategoryLabel(category),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(WisteriaRadius.sm),
          border: Border.all(
            color: accent.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: CustomPaint(
          size: Size(size, size),
          painter: _AvatarPainter(
            category: category,
            accentColor: accent,
            textColor: colors.textPrimary,
            mutedColor: colors.textSecondary,
            borderColor: colors.border,
          ),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final PatientAgeCategory category;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;

  _AvatarPainter({
    required this.category,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final secondaryPaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    switch (category) {
      case PatientAgeCategory.child:
        // Child: Rounder smaller head, lower shoulders, playful medical star/badge accent
        final headRadius = size.width * 0.18;
        final headCenter = Offset(cx, cy - size.height * 0.14);
        canvas.drawCircle(headCenter, headRadius, fillPaint);

        // Child shoulders
        final bodyPath = Path()
          ..moveTo(cx - size.width * 0.28, size.height * 0.82)
          ..quadraticBezierTo(
            cx - size.width * 0.22,
            cy + size.height * 0.12,
            cx,
            cy + size.height * 0.12,
          )
          ..quadraticBezierTo(
            cx + size.width * 0.22,
            cy + size.height * 0.12,
            cx + size.width * 0.28,
            size.height * 0.82,
          )
          ..close();
        canvas.drawPath(bodyPath, fillPaint);

        // Child badge (small star dot)
        canvas.drawCircle(
          Offset(cx + headRadius * 0.8, headCenter.dy - headRadius * 0.3),
          size.width * 0.04,
          secondaryPaint,
        );
        break;

      case PatientAgeCategory.teenager:
        // Teenager: Sleek proportioned head with stylized modern posture haircut line
        final headRadius = size.width * 0.19;
        final headCenter = Offset(cx, cy - size.height * 0.15);
        canvas.drawCircle(headCenter, headRadius, fillPaint);

        // Hair / profile sweep accent
        final hairPath = Path()
          ..moveTo(cx - headRadius, headCenter.dy - headRadius * 0.2)
          ..cubicTo(
            cx - headRadius * 0.5,
            headCenter.dy - headRadius * 1.3,
            cx + headRadius * 0.5,
            headCenter.dy - headRadius * 1.3,
            cx + headRadius * 1.1,
            headCenter.dy - headRadius * 0.3,
          )
          ..lineTo(cx + headRadius * 0.8, headCenter.dy - headRadius * 0.8)
          ..close();
        canvas.drawPath(hairPath, secondaryPaint);

        // Teen shoulders
        final bodyPath = Path()
          ..moveTo(cx - size.width * 0.32, size.height * 0.85)
          ..quadraticBezierTo(
            cx - size.width * 0.24,
            cy + size.height * 0.10,
            cx,
            cy + size.height * 0.10,
          )
          ..quadraticBezierTo(
            cx + size.width * 0.24,
            cy + size.height * 0.10,
            cx + size.width * 0.32,
            size.height * 0.85,
          )
          ..close();
        canvas.drawPath(bodyPath, fillPaint);
        break;

      case PatientAgeCategory.adult:
        // Adult: Classic crisp medical profile with lapel V neck
        final headRadius = size.width * 0.20;
        final headCenter = Offset(cx, cy - size.height * 0.16);
        canvas.drawCircle(headCenter, headRadius, fillPaint);

        // Adult shoulders & V-neck collar
        final bodyPath = Path()
          ..moveTo(cx - size.width * 0.35, size.height * 0.88)
          ..quadraticBezierTo(
            cx - size.width * 0.28,
            cy + size.height * 0.08,
            cx,
            cy + size.height * 0.08,
          )
          ..quadraticBezierTo(
            cx + size.width * 0.28,
            cy + size.height * 0.08,
            cx + size.width * 0.35,
            size.height * 0.88,
          )
          ..close();
        canvas.drawPath(bodyPath, fillPaint);

        // V-neck notch cut out
        final vNotch = Path()
          ..moveTo(cx - size.width * 0.08, cy + size.height * 0.08)
          ..lineTo(cx, cy + size.height * 0.28)
          ..lineTo(cx + size.width * 0.08, cy + size.height * 0.08)
          ..close();
        final notchPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawPath(vNotch, notchPaint);
        break;

      case PatientAgeCategory.senior:
        // Senior: Mature profile with classic collar fold and glasses/silver hair accent line
        final headRadius = size.width * 0.20;
        final headCenter = Offset(cx, cy - size.height * 0.16);
        canvas.drawCircle(headCenter, headRadius, fillPaint);

        // Hair arc top accent (mature silver frame effect)
        final hairArc = Path()
          ..addArc(
            Rect.fromCircle(center: headCenter, radius: headRadius + 1.5),
            3.6,
            2.2,
          );
        canvas.drawPath(hairArc, outlinePaint);

        // Senior shoulders
        final bodyPath = Path()
          ..moveTo(cx - size.width * 0.36, size.height * 0.88)
          ..quadraticBezierTo(
            cx - size.width * 0.28,
            cy + size.height * 0.08,
            cx,
            cy + size.height * 0.08,
          )
          ..quadraticBezierTo(
            cx + size.width * 0.28,
            cy + size.height * 0.08,
            cx + size.width * 0.36,
            size.height * 0.88,
          )
          ..close();
        canvas.drawPath(bodyPath, fillPaint);

        // Glasses bridge / profile line
        final glassesBridge = Path()
          ..moveTo(cx - size.width * 0.10, headCenter.dy)
          ..lineTo(cx + size.width * 0.10, headCenter.dy);
        final gPaint = Paint()
          ..color = mutedColor.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawPath(glassesBridge, gPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.category != category ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.textColor != textColor;
  }
}
