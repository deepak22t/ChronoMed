import 'package:meta/meta.dart';
import 'pharmacokinetic_rule.dart';

enum MedicationForm {
  tablet,
  capsule,
  liquid,
  injection,
  inhaler;

  String get displayName => switch (this) {
        MedicationForm.tablet => 'Tablet',
        MedicationForm.capsule => 'Capsule',
        MedicationForm.liquid => 'Liquid Solution',
        MedicationForm.injection => 'Injection',
        MedicationForm.inhaler => 'Inhaler',
      };
}

/// Domain representation of a prescribed medication.
@immutable
class Medication {
  final String id;
  final String name;
  final String? brandName;

  /// Standardized NIH RxNorm Concept Unique Identifier (if available).
  final String? rxcui;

  /// Dosage string (e.g., "50 mcg", "500 mg").
  final String dosage;

  final MedicationForm form;
  final PharmacokineticRule rules;

  const Medication({
    required this.id,
    required this.name,
    this.brandName,
    this.rxcui,
    required this.dosage,
    this.form = MedicationForm.tablet,
    required this.rules,
  });

  /// True if this medication conflicts with another drug or cation identifier.
  bool hasConflictWith(String identifier) {
    final lower = identifier.toLowerCase();
    return rules.separationConstraints.any((c) =>
        c.targetIdentifier.toLowerCase() == lower ||
        name.toLowerCase().contains(lower) ||
        (brandName?.toLowerCase().contains(lower) ?? false));
  }

  /// Retrieves the minimum separation minutes required with another target.
  int getSeparationWith(String identifier) {
    final lower = identifier.toLowerCase();
    for (final c in rules.separationConstraints) {
      if (c.targetIdentifier.toLowerCase() == lower ||
          lower.contains(c.targetIdentifier.toLowerCase())) {
        return c.minimumSeparationMinutes;
      }
    }
    return 0;
  }

  @override
  String toString() => 'Medication($name $dosage)';
}
