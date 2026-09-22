import 'csp_solver.dart';
import 'interval_math.dart';
import 'models/meal.dart';
import 'models/medication.dart';
import 'models/routine.dart';
import 'models/schedule_result.dart';

/// Dynamic forward-shift and late-dose recalibration engine.
abstract final class DynamicRecalibrator {
  /// Recalibrates an active schedule when an event occurs later than scheduled.
  ///
  /// [existingDoses]: The previously calculated schedule.
  /// [delayedMedicationId]: The ID of the medication that was taken late.
  /// [actualTakenMinute]: The actual minute the dose was consumed.
  /// [medications]: The complete medication registry.
  /// [currentRoutine]: The active routine.
  static DailyScheduleResult recalibrateForLateDose({
    required List<ScheduledDose> existingDoses,
    required String delayedMedicationId,
    required int actualTakenMinute,
    required List<Medication> medications,
    required Routine currentRoutine,
  }) {
    final delayedDose = existingDoses.firstWhere(
      (d) => d.medicationId == delayedMedicationId,
      orElse: () => throw ArgumentError('Medication ID not found in schedule'),
    );

    final delayDeltaMinutes =
        actualTakenMinute - delayedDose.scheduledMinute;

    // If delay is negligible (< 15 minutes), keep schedule unchanged
    if (delayDeltaMinutes.abs() < 15) {
      return RecalibratedSchedule(
        date: 'TODAY',
        userId: currentRoutine.userId,
        doses: existingDoses.map((d) {
          if (d.medicationId == delayedMedicationId) {
            return d.copyWith(
              actualTakenMinute: actualTakenMinute,
              status: DoseStatus.taken,
            );
          }
          return d;
        }).toList(),
        shiftReason: 'Minor variance (<15m). Schedule preserved.',
        shiftsSummary: const [],
      );
    }

    final delayedMed = medications.firstWhere((m) => m.id == delayedMedicationId);

    // Identify which future doses must be shifted to maintain chelation spacing
    final shifts = <String>[];
    final updatedDoses = <ScheduledDose>[];

    for (final dose in existingDoses) {
      if (dose.medicationId == delayedMedicationId) {
        // Mark as taken at actual time
        updatedDoses.add(dose.copyWith(
          scheduledMinute: actualTakenMinute,
          actualTakenMinute: actualTakenMinute,
          status: DoseStatus.taken,
        ));
        continue;
      }

      // If dose was already taken in the past, it remains fixed
      if (dose.status == DoseStatus.taken) {
        updatedDoses.add(dose);
        continue;
      }

      // Check if this future dose conflicts with the delayed dose
      final otherMed = medications.firstWhere((m) => m.id == dose.medicationId);
      final gap = delayedMed.getSeparationWith(otherMed.name) > 0
          ? delayedMed.getSeparationWith(otherMed.name)
          : otherMed.getSeparationWith(delayedMed.name);

      if (gap > 0) {
        // Must maintain gap after actualTakenMinute
        final earliestSafeTime = actualTakenMinute + gap;
        if (dose.scheduledMinute < earliestSafeTime) {
          final newTime = earliestSafeTime;
          shifts.add(
            '${dose.medicationName} moved from ${dose.formattedTime} to '
            '${IntervalMath.formatMinuteOfDay(newTime)} to preserve mandatory ${gap}m chelation gap.',
          );
          updatedDoses.add(dose.copyWith(scheduledMinute: newTime));
          continue;
        }
      }

      // If no conflict, keep original time
      updatedDoses.add(dose);
    }

    // Re-sort chronologically
    updatedDoses.sort((a, b) => a.scheduledMinute.compareTo(b.scheduledMinute));

    return RecalibratedSchedule(
      date: 'TODAY',
      userId: currentRoutine.userId,
      doses: updatedDoses,
      shiftReason:
          '${delayedDose.medicationName} taken ${delayDeltaMinutes > 0 ? "$delayDeltaMinutes mins late" : "${delayDeltaMinutes.abs()} mins early"} at ${IntervalMath.formatMinuteOfDay(actualTakenMinute)}.',
      shiftsSummary: shifts,
    );
  }

  /// Recalibrates the schedule when the patient wakes up late.
  static DailyScheduleResult recalibrateForDelayedWakeUp({
    required Routine baselineRoutine,
    required int actualWakeTimeMinutes,
    required List<Medication> medications,
    required String targetDate,
  }) {
    final shiftDelta = actualWakeTimeMinutes - baselineRoutine.wakeTimeMinutes;

    // Shift all meals forward proportionally by shiftDelta
    final shiftedMeals = baselineRoutine.meals.map((m) {
      final newStart = (m.startTimeMinutes + shiftDelta).clamp(0, 1439);
      return MealAnchor(
        id: m.id,
        type: m.type,
        startTimeMinutes: newStart,
        durationMinutes: m.durationMinutes,
      );
    }).toList();

    final shiftedRoutine = Routine(
      id: '${baselineRoutine.id}_delayed',
      userId: baselineRoutine.userId,
      wakeTimeMinutes: actualWakeTimeMinutes,
      sleepTimeMinutes: baselineRoutine.sleepTimeMinutes,
      meals: shiftedMeals,
      beveragePreferences: baselineRoutine.beveragePreferences,
    );

    // Re-solve with shifted routine
    final solver = ChronoMedSolver(
      routine: shiftedRoutine,
      medications: medications,
      targetDate: targetDate,
    );

    final result = solver.solve();

    if (result is OptimalSchedule) {
      return RecalibratedSchedule(
        date: targetDate,
        userId: baselineRoutine.userId,
        doses: result.doses,
        shiftReason:
            'Woke up ${shiftDelta}m later than usual (${IntervalMath.formatMinuteOfDay(actualWakeTimeMinutes)}).',
        shiftsSummary: [
          'All meal windows shifted forward by ${shiftDelta}m.',
          'Morning empty-stomach medications recalculated to match revised breakfast.',
        ],
      );
    }

    return result;
  }
}
