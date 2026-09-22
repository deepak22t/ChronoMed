import 'package:core_engine/core_engine.dart';
import 'package:test/test.dart';

void main() {
  group('ChronoMed Clinical Rules & CSP Solver Tests', () {
    late Routine sarahRoutine;
    late List<Medication> sarahMedications;

    setUp(() {
      // Sarah's baseline routine: Wake 07:00 AM, Breakfast 08:30 AM, Lunch 01:00 PM, Dinner 07:30 PM, Sleep 11:00 PM
      sarahRoutine = const Routine(
        id: 'routine_sarah',
        userId: 'user_sarah',
        wakeTimeMinutes: 420,  // 07:00 AM
        sleepTimeMinutes: 1380, // 11:00 PM
        meals: [
          MealAnchor(id: 'm1', type: MealType.breakfast, startTimeMinutes: 510, durationMinutes: 30), // 08:30 AM
          MealAnchor(id: 'm2', type: MealType.lunch, startTimeMinutes: 780, durationMinutes: 45),     // 01:00 PM
          MealAnchor(id: 'm3', type: MealType.dinner, startTimeMinutes: 1170, durationMinutes: 45),   // 07:30 PM
        ],
      );

      sarahMedications = [
        const Medication(
          id: 'med_levo',
          name: 'Levothyroxine',
          dosage: '50 mcg',
          rules: PharmacokineticRule(
            requiresEmptyStomach: true,
            circadianPreference: CircadianWindow.morning,
            separationConstraints: [
              DrugSeparationConstraint(
                targetIdentifier: 'Calcium Carbonate',
                minimumSeparationMinutes: 240,
                clinicalRationale: 'Prevents insoluble chelation complex',
              ),
              DrugSeparationConstraint(
                targetIdentifier: 'Iron Supplement',
                minimumSeparationMinutes: 240,
                clinicalRationale: 'Prevents absorption inhibition',
              ),
            ],
          ),
        ),
        const Medication(
          id: 'med_omeprazole',
          name: 'Omeprazole',
          dosage: '20 mg',
          rules: PharmacokineticRule(
            requiresEmptyStomach: true,
            circadianPreference: CircadianWindow.morning,
          ),
        ),
        const Medication(
          id: 'med_metformin',
          name: 'Metformin',
          dosage: '500 mg',
          rules: PharmacokineticRule(
            requiresFood: true,
          ),
        ),
        const Medication(
          id: 'med_calcium',
          name: 'Calcium Carbonate',
          dosage: '500 mg',
          rules: PharmacokineticRule(
            separationConstraints: [
              DrugSeparationConstraint(
                targetIdentifier: 'Levothyroxine',
                minimumSeparationMinutes: 240,
                clinicalRationale: 'Chelation block',
              ),
              DrugSeparationConstraint(
                targetIdentifier: 'Iron Supplement',
                minimumSeparationMinutes: 240,
                clinicalRationale: 'Mineral competition',
              ),
            ],
          ),
        ),
        const Medication(
          id: 'med_iron',
          name: 'Iron Supplement',
          dosage: '65 mg',
          rules: PharmacokineticRule(
            requiresEmptyStomach: true,
            separationConstraints: [
              DrugSeparationConstraint(
                targetIdentifier: 'Levothyroxine',
                minimumSeparationMinutes: 240,
                clinicalRationale: 'Avoid simultaneous cation binding',
              ),
              DrugSeparationConstraint(
                targetIdentifier: 'Calcium Carbonate',
                minimumSeparationMinutes: 240,
                clinicalRationale: 'Calcium completely blocks iron transport',
              ),
            ],
          ),
        ),
        const Medication(
          id: 'med_statin',
          name: 'Atorvastatin',
          dosage: '20 mg',
          rules: PharmacokineticRule(
            circadianPreference: CircadianWindow.bedtime,
          ),
        ),
      ];
    });

    test('Sarah Polypharmacy solves successfully with zero clinical violations', () {
      final solver = ChronoMedSolver(
        routine: sarahRoutine,
        medications: sarahMedications,
      );

      final result = solver.solve();

      expect(result, isA<OptimalSchedule>());
      final optimal = result as OptimalSchedule;
      expect(optimal.doses.length, equals(6));

      // 1. Verify Levothyroxine is taken on empty stomach (>= 60m before breakfast)
      final levoDose = optimal.doses.firstWhere((d) => d.medicationName == 'Levothyroxine');
      expect(levoDose.scheduledMinute, lessThanOrEqualTo(510 - 60),
          reason: 'Levothyroxine must be at least 60 min before breakfast (08:30 AM)');

      // 2. Verify Chelation Distance between Levothyroxine and Calcium is >= 240 minutes (4 hours)
      final calciumDose = optimal.doses.firstWhere((d) => d.medicationName == 'Calcium Carbonate');
      final levoCalciumGap = (calciumDose.scheduledMinute - levoDose.scheduledMinute).abs();
      expect(levoCalciumGap, greaterThanOrEqualTo(240),
          reason: 'Calcium and Levothyroxine must have at least 240 minutes gap');

      // 3. Verify Chelation Distance between Calcium and Iron is >= 240 minutes
      final ironDose = optimal.doses.firstWhere((d) => d.medicationName == 'Iron Supplement');
      final ironCalciumGap = (calciumDose.scheduledMinute - ironDose.scheduledMinute).abs();
      expect(ironCalciumGap, greaterThanOrEqualTo(240),
          reason: 'Calcium and Iron must have at least 240 minutes gap');

      // 4. Verify Metformin is co-administered with a meal (within 0-30 min of meal start)
      final metforminDose = optimal.doses.firstWhere((d) => d.medicationName == 'Metformin');
      final withMeal = sarahRoutine.meals.any((m) {
        final delta = metforminDose.scheduledMinute - m.startTimeMinutes;
        return delta >= 0 && delta <= 30;
      });
      expect(withMeal, isTrue, reason: 'Metformin must be taken with a meal');

      // 5. Verify Atorvastatin is taken during bedtime window
      final statinDose = optimal.doses.firstWhere((d) => d.medicationName == 'Atorvastatin');
      expect(statinDose.scheduledMinute, greaterThanOrEqualTo(ClinicalBuffers.bedtimeWindowStart));
    });

    test('Solver latency benchmark executes in under 15 milliseconds', () {
      final solver = ChronoMedSolver(
        routine: sarahRoutine,
        medications: sarahMedications,
      );

      final result = solver.solve();
      expect(result, isA<OptimalSchedule>());
      final optimal = result as OptimalSchedule;
      expect(optimal.solveDurationMs, lessThanOrEqualTo(15),
          reason: 'Pure Dart CSP solver must converge in <15ms on mobile CPUs');
    });

    test('Fail-Closed Safety: Infeasible impossible schedule triggers clinical conflict alert', () {
      // Create an impossible scenario: 2 drugs needing 4 hours separation, but waking day is only 3 hours
      const shortRoutine = Routine(
        id: 'short',
        userId: 'u1',
        wakeTimeMinutes: 480,  // 08:00 AM
        sleepTimeMinutes: 660,  // 11:00 AM (only 3 hours awake)
        meals: [
          MealAnchor(id: 'm1', type: MealType.breakfast, startTimeMinutes: 540),
        ],
      );

      final conflictingMeds = [
        const Medication(
          id: '1',
          name: 'Drug A',
          dosage: '10mg',
          rules: PharmacokineticRule(
            separationConstraints: [
              DrugSeparationConstraint(
                targetIdentifier: 'Drug B',
                minimumSeparationMinutes: 240, // 4 hours needed, but only 3 hours available!
                clinicalRationale: 'Impossible in 3h',
              )
            ],
          ),
        ),
        const Medication(
          id: '2',
          name: 'Drug B',
          dosage: '10mg',
          rules: PharmacokineticRule(
            separationConstraints: [
              DrugSeparationConstraint(
                targetIdentifier: 'Drug A',
                minimumSeparationMinutes: 240,
                clinicalRationale: 'Impossible in 3h',
              )
            ],
          ),
        ),
      ];

      final solver = ChronoMedSolver(routine: shortRoutine, medications: conflictingMeds);
      final result = solver.solve();

      expect(result, isA<InfeasibleConflict>());
      final conflict = result as InfeasibleConflict;
      expect(conflict.errorCode, equals('CHRONO_1001'));
      expect(conflict.conflictingMedications, contains('Drug A'));
      expect(conflict.conflictingMedications, contains('Drug B'));
    });

    test('Dynamic Recalibrator: Waking up 2 hours late shifts dependent meals and doses', () {
      final recalibrated = DynamicRecalibrator.recalibrateForDelayedWakeUp(
        baselineRoutine: sarahRoutine,
        actualWakeTimeMinutes: 540, // Woke up at 09:00 AM (2 hours late)
        medications: sarahMedications,
        targetDate: 'TODAY',
      );

      expect(recalibrated, isA<RecalibratedSchedule>());
      final shift = recalibrated as RecalibratedSchedule;
      expect(shift.doses.length, equals(6));

      // Levothyroxine must still be before shifted breakfast
      final levo = shift.doses.firstWhere((d) => d.medicationName == 'Levothyroxine');
      expect(levo.scheduledMinute, equals(540), reason: 'Should be taken immediately upon waking at 09:00 AM');
    });
  });
}
