import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/wisteria_theme.dart';

/// Legacy centralized age categories for patient avatar selection (preserved for backwards compatibility).
enum PatientAgeCategory { child, teenager, adult, senior }

/// Legacy deterministic age-to-category mapping.
PatientAgeCategory getPatientAgeCategory(int? age) {
  if (age == null) return PatientAgeCategory.adult;
  if (age <= 12) return PatientAgeCategory.child;
  if (age <= 19) return PatientAgeCategory.teenager;
  if (age <= 59) return PatientAgeCategory.adult;
  return PatientAgeCategory.senior;
}

/// Returns a human-readable label for the legacy age category.
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

/// Standardized age groups for clinical patient avatars:
/// - Child: 0–17 years
/// - Adult: 18–49 years
/// - Older adult: 50 years and above
enum PatientAgeGroup { child, adult, olderAdult }

/// Supported genders for dynamic patient avatars.
enum PatientAvatarGender { male, female }

/// Six age- and gender-based patient avatar categories plus neutral fallback.
enum PatientAvatarCategory {
  childMale,
  childFemale,
  adultMale,
  adultFemale,
  olderAdultMale,
  olderAdultFemale,
  childNeutral,
  adultNeutral,
  olderAdultNeutral,
  neutralFallback,
}

/// Resolves patient age.
/// Calculates age dynamically from [dateOfBirth] when available.
/// If only [age] is stored, that value is used.
int? resolvePatientAge({DateTime? dateOfBirth, int? age}) {
  if (dateOfBirth != null) {
    final now = DateTime.now();
    int calculated = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      calculated--;
    }
    return calculated >= 0 ? calculated : 0;
  }
  return age;
}

/// Maps an age in years to its respective [PatientAgeGroup].
PatientAgeGroup? getPatientAgeGroup(int? age) {
  if (age == null || age < 0) return null;
  if (age <= 17) return PatientAgeGroup.child;
  if (age <= 49) return PatientAgeGroup.adult;
  return PatientAgeGroup.olderAdult;
}

/// Parses gender string into [PatientAvatarGender].
PatientAvatarGender? parsePatientGender(String? gender) {
  if (gender == null) return null;
  final g = gender.trim().toLowerCase();
  if (g == 'male' || g == 'm') return PatientAvatarGender.male;
  if (g == 'female' || g == 'f') return PatientAvatarGender.female;
  return null;
}

/// Selects the appropriate avatar category based on age/DOB and gender.
/// If gender or age/DOB is missing or unrecognized, returns [PatientAvatarCategory.neutralFallback].
PatientAvatarCategory getPatientAvatarCategory({
  DateTime? dateOfBirth,
  int? age,
  String? gender,
}) {
  final resolvedAge = resolvePatientAge(dateOfBirth: dateOfBirth, age: age);
  final parsedGender = parsePatientGender(gender);

  if (resolvedAge == null) {
    return PatientAvatarCategory.neutralFallback;
  }

  if (parsedGender == null) {
    if (resolvedAge <= 17) return PatientAvatarCategory.childNeutral;
    if (resolvedAge <= 49) return PatientAvatarCategory.adultNeutral;
    return PatientAvatarCategory.olderAdultNeutral;
  }

  if (resolvedAge <= 17) {
    return parsedGender == PatientAvatarGender.male
        ? PatientAvatarCategory.childMale
        : PatientAvatarCategory.childFemale;
  } else if (resolvedAge <= 49) {
    return parsedGender == PatientAvatarGender.male
        ? PatientAvatarCategory.adultMale
        : PatientAvatarCategory.adultFemale;
  } else {
    return parsedGender == PatientAvatarGender.male
        ? PatientAvatarCategory.olderAdultMale
        : PatientAvatarCategory.olderAdultFemale;
  }
}

/// Returns a descriptive human-readable label for the avatar category.
String getAvatarCategoryLabel(PatientAvatarCategory category) {
  switch (category) {
    case PatientAvatarCategory.childMale:
      return 'Child (Male, 0–17 yrs)';
    case PatientAvatarCategory.childFemale:
      return 'Child (Female, 0–17 yrs)';
    case PatientAvatarCategory.adultMale:
      return 'Adult (Male, 18–49 yrs)';
    case PatientAvatarCategory.adultFemale:
      return 'Adult (Female, 18–49 yrs)';
    case PatientAvatarCategory.olderAdultMale:
      return 'Older Adult (Male, 50+ yrs)';
    case PatientAvatarCategory.olderAdultFemale:
      return 'Older Adult (Female, 50+ yrs)';
    case PatientAvatarCategory.childNeutral:
      return 'Child (Gender not provided, 0–17 yrs)';
    case PatientAvatarCategory.adultNeutral:
      return 'Adult (Gender not provided, 18–49 yrs)';
    case PatientAvatarCategory.olderAdultNeutral:
      return 'Older Adult (Gender not provided, 50+ yrs)';
    case PatientAvatarCategory.neutralFallback:
      return 'Patient Profile';
  }
}

/// Returns the built-in Material gender icon for a patient record.
///
/// - Male: [Icons.male]
/// - Female: [Icons.female]
/// - Missing, unrecognized, or other: [Icons.person] (neutral fallback)
IconData getPatientGenderIcon(String? gender) {
  if (gender == null) return Icons.person;
  final g = gender.trim().toLowerCase();
  if (g == 'male' || g == 'm') return Icons.male;
  if (g == 'female' || g == 'f') return Icons.female;
  return Icons.person;
}

/// Theme-aware, age- and gender-based silhouette portrait for patient records.
class PatientAgeAvatar extends StatelessWidget {
  final int? age;
  final String? gender;
  final DateTime? dateOfBirth;
  final double size;

  const PatientAgeAvatar({
    super.key,
    this.age,
    this.gender,
    this.dateOfBirth,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = WisteriaColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = getPatientAvatarCategory(
      dateOfBirth: dateOfBirth,
      age: age,
      gender: gender,
    );
    final icon = getPatientGenderIcon(gender);

    final bg = isDark ? const Color(0xFF22262B) : const Color(0xFFE8EEF3);
    final fg = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF1E293B).withValues(alpha: 0.85);

    return Tooltip(
      message: getAvatarCategoryLabel(category),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          color: bg,
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.62,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Modern oversized silhouette patient background for patient cards.
class PatientProfileBackground extends StatelessWidget {
  final int? age;
  final String? gender;
  final DateTime? dateOfBirth;

  const PatientProfileBackground({
    super.key,
    this.age,
    this.gender,
    this.dateOfBirth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = getPatientAvatarCategory(
      dateOfBirth: dateOfBirth,
      age: age,
      gender: gender,
    );
    final icon = getPatientGenderIcon(gender);

    // Theme-aware illustration background:
    // Light mode: soft pale blue-grey muted surface
    // Dark mode: charcoal / dark slate muted surface
    final containerColor = isDark
        ? const Color(0xFF22262B)
        : const Color(0xFFE8EEF3);

    // Theme-aware silhouette color:
    // Light mode: dark slate silhouette for strong contrast
    // Dark mode: light silhouette for sufficient contrast
    final silhouetteColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : const Color(0xFF1E293B).withValues(alpha: 0.22);

    return Tooltip(
      message: getAvatarCategoryLabel(category),
      child: ClipRect(
        child: Container(
          color: containerColor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : 180.0;
              // Scale the icon to occupy most of the available illustration area
              final iconSize = cardHeight * 1.12;

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    right: -iconSize * 0.10,
                    top: -iconSize * 0.05,
                    bottom: -iconSize * 0.05,
                    child: Center(
                      child: Transform.rotate(
                        angle: -14 * math.pi / 180,
                        child: Icon(
                          icon,
                          size: iconSize,
                          color: silhouetteColor,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
