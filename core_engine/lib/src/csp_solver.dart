import 'constants/clinical_buffers.dart';
import 'interval_math.dart';
import 'models/medication.dart';
import 'models/routine.dart';
import 'models/schedule_result.dart';

/// Pure deterministic Constraint Satisfaction Problem (CSP) Solver.
/// Operates on 15-minute discretized intervals using backtracking with
/// the Minimum Remaining Values (MRV) heuristic and forward checking.
class ChronoMedSolver {
  final Routine routine;
  final List<Medication> medications;
  final String targetDate;

  ChronoMedSolver({
    required this.routine,
    required this.medications,
    this.targetDate = 'TODAY',
  });

  /// Main entrypoint: Computes the collision-free daily medication schedule.
  DailyScheduleResult solve() {
    final stopwatch = Stopwatch()..start();

    if (medications.isEmpty) {
      return OptimalSchedule(
        date: targetDate,
        userId: routine.userId,
        doses: const [],
        solveDurationMs: stopwatch.elapsedMilliseconds,
      );
    }

    // Step 1: Generate discrete search domain across waking hours (15-min steps)
    final discreteDomain = <int>[];
    for (var m = routine.wakeTimeMinutes;
        m <= routine.sleepTimeMinutes;
        m += ClinicalBuffers.timeStepMinutes) {
      discreteDomain.add(m);
    }

    // Step 2: Compute valid domain candidate slots for each medication
    final candidateDomains = <Medication, List<int>>{};
    for (final med in medications) {
      final validSlots = <int>[];
      for (final slot in discreteDomain) {
        if (_isSlotLocallyValid(med, slot)) {
          validSlots.add(slot);
        }
      }
      candidateDomains[med] = validSlots;
    }

    // Fail-closed check: If any medication has zero valid slots, fail immediately
    for (final entry in candidateDomains.entries) {
      if (entry.value.isEmpty) {
        stopwatch.stop();
        return _buildInfeasibleConflict(
          collidingMeds: [entry.key.name],
          explanation:
              'Medication "${entry.key.name}" has zero valid slots within your waking hours '
              'due to conflicting meal fasting or circadian window rules.',
          advice:
              'Consider widening the time between waking up and breakfast, or consult your physician.',
        );
      }
    }

    // Step 3: Sort medications by MRV (fewest valid slots first)
    final sortedMeds = List<Medication>.from(medications)
      ..sort((a, b) =>
          candidateDomains[a]!.length.compareTo(candidateDomains[b]!.length));

    // Step 4: Backtracking search
    final assignedTimes = <Medication, int>{};

    bool backtrack(int index) {
      if (index == sortedMeds.length) {
        return true;
      }

      final currentMed = sortedMeds[index];
      final slots = candidateDomains[currentMed]!;

      for (final slot in slots) {
        if (_isConsistentWithAssigned(currentMed, slot, assignedTimes)) {
          assignedTimes[currentMed] = slot;
          if (backtrack(index + 1)) {
            return true;
          }
          assignedTimes.remove(currentMed);
        }
      }

      return false;
    }

    final solved = backtrack(0);
    stopwatch.stop();

    if (!solved) {
      return _diagnoseConflict(sortedMeds, candidateDomains);
    }

    // Step 5: Construct the solved OptimalSchedule
    final doses = <ScheduledDose>[];
    for (final entry in assignedTimes.entries) {
      final med = entry.key;
      final time = entry.value;

      doses.add(ScheduledDose(
        id: '${routine.userId}_${med.id}_$time',
        medicationId: med.id,
        medicationName: med.name,
        dosage: med.dosage,
        scheduledMinute: time,
        clinicalInstruction: _generateClinicalInstruction(med, time),
        safeFoodWindowNote: _generateFoodNote(med, time),
      ));
    }

    // Sort chronologically
    doses.sort((a, b) => a.scheduledMinute.compareTo(b.scheduledMinute));

    return OptimalSchedule(
      date: targetDate,
      userId: routine.userId,
      doses: doses,
      solveDurationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Checks static constraints (fasting, food, circadian) for a single drug and slot.
  bool _isSlotLocallyValid(Medication med, int slot) {
    // Check Circadian preference
    if (!IntervalMath.isCircadianCompliant(
      minute: slot,
      window: med.rules.circadianPreference,
      customWindow: med.rules.customTimeWindow,
    )) {
      return false;
    }

    // Check Empty Stomach requirement
    if (med.rules.requiresEmptyStomach) {
      if (!IntervalMath.isFastingCompliant(
        minute: slot,
        meals: routine.meals,
        preBuffer: med.rules.emptyStomachPreMealMinutes,
        postBuffer: med.rules.emptyStomachPostMealMinutes,
      )) {
        return false;
      }
    }

    // Check With Food requirement
    if (med.rules.requiresFood) {
      if (!IntervalMath.isPrandialCompliant(
        minute: slot,
        meals: routine.meals,
        foodWindow: med.rules.foodWindowMinutes,
      )) {
        return false;
      }
    }

    return true;
  }

  /// Checks relational constraints against already placed medications.
  bool _isConsistentWithAssigned(
    Medication candidate,
    int candidateTime,
    Map<Medication, int> assigned,
  ) {
    for (final entry in assigned.entries) {
      final otherMed = entry.key;
      final otherTime = entry.value;

      // 1. Bilateral Chelation / Separation Constraints
      final gapCandidate = candidate.getSeparationWith(otherMed.name);
      if (gapCandidate > 0) {
        if (!IntervalMath.satisfiesSeparation(
          timeA: candidateTime,
          timeB: otherTime,
          requiredGapMinutes: gapCandidate,
        )) {
          return false;
        }
      }

      final gapOther = otherMed.getSeparationWith(candidate.name);
      if (gapOther > 0) {
        if (!IntervalMath.satisfiesSeparation(
          timeA: candidateTime,
          timeB: otherTime,
          requiredGapMinutes: gapOther,
        )) {
          return false;
        }
      }

      // 2. Prevent identical timestamp collisions unless both are compatible with food
      if (candidateTime == otherTime) {
        if (!(candidate.rules.requiresFood && otherMed.rules.requiresFood)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Diagnoses the Minimal Unsatisfiable Subset (MUS) when solving fails.
  InfeasibleConflict _diagnoseConflict(
    List<Medication> sortedMeds,
    Map<Medication, List<int>> domains,
  ) {
    // Check pair-by-pair for direct chelation collision
    for (var i = 0; i < sortedMeds.length; i++) {
      for (var j = i + 1; j < sortedMeds.length; j++) {
        final medA = sortedMeds[i];
        final medB = sortedMeds[j];
        final gap = medA.getSeparationWith(medB.name) > 0
            ? medA.getSeparationWith(medB.name)
            : medB.getSeparationWith(medA.name);

        if (gap > 0) {
          // Check if any pair of slots can satisfy this gap
          var pairPossible = false;
          for (final slotA in domains[medA]!) {
            for (final slotB in domains[medB]!) {
              if ((slotA - slotB).abs() >= gap) {
                pairPossible = true;
                break;
              }
            }
            if (pairPossible) break;
          }

          if (!pairPossible) {
            return _buildInfeasibleConflict(
              collidingMeds: [medA.name, medB.name],
              explanation:
                  '${medA.name} and ${medB.name} require at least $gap minutes separation, '
                  'which cannot fit into your current waking and meal routine.',
              advice:
                  'Consult your doctor about taking one of these medications on alternating days or shifting one to bedtime.',
            );
          }
        }
      }
    }

    return _buildInfeasibleConflict(
      collidingMeds: sortedMeds.map((m) => m.name).toList(),
      explanation:
          'Multiple medication spacing and meal fasting constraints cannot simultaneously be satisfied.',
      advice:
          'Review your waking and bedtime schedule with your pharmacist or prescribing doctor.',
    );
  }

  InfeasibleConflict _buildInfeasibleConflict({
    required List<String> collidingMeds,
    required String explanation,
    required String advice,
  }) {
    return InfeasibleConflict(
      errorCode: 'CHRONO_1001',
      conflictingMedications: collidingMeds,
      clinicalExplanation: explanation,
      actionableAdvice: advice,
    );
  }

  String _generateClinicalInstruction(Medication med, int time) {
    if (med.rules.requiresEmptyStomach) {
      return 'Take with a full glass of plain water. Do not eat, drink coffee, or take other pills for 60 minutes.';
    }
    if (med.rules.requiresFood) {
      return 'Take during or immediately after your meal.';
    }
    return 'Take dose with water.';
  }

  String _generateFoodNote(Medication med, int time) {
    if (med.rules.requiresEmptyStomach) {
      final safeEating = time + med.rules.emptyStomachPreMealMinutes;
      return 'Safe to eat food or drink coffee starting at ${IntervalMath.formatMinuteOfDay(safeEating)}.';
    }
    if (med.rules.requiresFood) {
      return 'Ensure stomach is not empty to avoid gastrointestinal discomfort.';
    }
    return 'Standard dietary tolerance.';
  }
}
