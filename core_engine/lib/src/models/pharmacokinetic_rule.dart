import 'package:meta/meta.dart';
import '../constants/clinical_buffers.dart';

enum CircadianWindow {
  morning,
  afternoon,
  evening,
  bedtime,
  anyTime;

  String get displayName => switch (this) {
        CircadianWindow.morning => 'Morning',
        CircadianWindow.afternoon => 'Afternoon',
        CircadianWindow.evening => 'Evening',
        CircadianWindow.bedtime => 'Bedtime',
        CircadianWindow.anyTime => 'Any Time',
      };
}

/// Bilateral clinical separation constraint between drug pairs.
@immutable
class DrugSeparationConstraint {
  /// Target substance, cation category (e.g., "CALCIUM", "IRON"), or drug name.
  final String targetIdentifier;

  /// Minimum separation required in minutes (e.g. 240m for Cation-Thyroid).
  final int minimumSeparationMinutes;

  /// Clinical justification for the separation.
  final String clinicalRationale;

  const DrugSeparationConstraint({
    required this.targetIdentifier,
    this.minimumSeparationMinutes =
        ClinicalBuffers.minCationChelationSeparationMinutes,
    required this.clinicalRationale,
  }) : assert(minimumSeparationMinutes > 0);

  @override
  String toString() =>
      'DrugSeparationConstraint(target: $targetIdentifier, gap: ${minimumSeparationMinutes}m)';
}

/// Clinical pharmacokinetic rules governing a specific medication.
@immutable
class PharmacokineticRule {
  /// True if the medication requires a completely empty stomach.
  final bool requiresEmptyStomach;

  /// Pre-meal buffer (default: 60 minutes).
  final int emptyStomachPreMealMinutes;

  /// Post-meal buffer (default: 120 minutes).
  final int emptyStomachPostMealMinutes;

  /// True if the medication must be ingested with or immediately following food.
  final bool requiresFood;

  /// Maximum window post meal start for food-dependent drugs (default: 30 min).
  final int foodWindowMinutes;

  /// Circadian preference (Morning, Evening, Bedtime, or Any).
  final CircadianWindow circadianPreference;

  /// Optional custom minute-of-day window boundaries.
  final ({int startMinutes, int endMinutes})? customTimeWindow;

  /// Specific drug-to-drug or drug-to-mineral chelation rules.
  final List<DrugSeparationConstraint> separationConstraints;

  const PharmacokineticRule({
    this.requiresEmptyStomach = false,
    this.emptyStomachPreMealMinutes =
        ClinicalBuffers.emptyStomachPreMealBufferMinutes,
    this.emptyStomachPostMealMinutes =
        ClinicalBuffers.emptyStomachPostMealBufferMinutes,
    this.requiresFood = false,
    this.foodWindowMinutes = ClinicalBuffers.prandialFoodBufferMinutes,
    this.circadianPreference = CircadianWindow.anyTime,
    this.customTimeWindow,
    this.separationConstraints = const [],
  }) : assert(!(requiresEmptyStomach && requiresFood),
            'A medication cannot simultaneously require an empty stomach and require food');
}
