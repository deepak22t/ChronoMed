import 'package:core_engine/core_engine.dart';

void main() {
  print('=' * 65);
  print(' CHRONOMED: CLINICAL-GRADE POLYPHARMACY CSP ENGINE');
  print(' Pure Deterministic Constraint-Satisfaction Scheduling');
  print('=' * 65);

  // Sarah's baseline routine: Wake 07:00 AM, Breakfast 08:30 AM, Lunch 01:00 PM, Dinner 07:30 PM, Sleep 11:00 PM
  const sarahRoutine = Routine(
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

  final sarahMedications = [
    const Medication(
      id: 'med_levo',
      name: 'Levothyroxine Sodium',
      dosage: '50 mcg',
      rules: PharmacokineticRule(
        requiresEmptyStomach: true,
        circadianPreference: CircadianWindow.morning,
        separationConstraints: [
          DrugSeparationConstraint(
            targetIdentifier: 'Calcium Carbonate',
            minimumSeparationMinutes: 240,
            clinicalRationale: 'Insoluble chelate reduces bioavailability by 80%',
          ),
          DrugSeparationConstraint(
            targetIdentifier: 'Ferrous Sulfate (Iron)',
            minimumSeparationMinutes: 240,
            clinicalRationale: 'Forms insoluble complex with thyroxine',
          ),
        ],
      ),
    ),
    const Medication(
      id: 'med_omeprazole',
      name: 'Omeprazole (PPI)',
      dosage: '20 mg',
      rules: PharmacokineticRule(
        requiresEmptyStomach: true,
        circadianPreference: CircadianWindow.morning,
      ),
    ),
    const Medication(
      id: 'med_metformin',
      name: 'Metformin HCl',
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
        requiresFood: true,
        separationConstraints: [
          DrugSeparationConstraint(
            targetIdentifier: 'Levothyroxine Sodium',
            minimumSeparationMinutes: 240,
            clinicalRationale: 'Chelation block',
          ),
          DrugSeparationConstraint(
            targetIdentifier: 'Ferrous Sulfate (Iron)',
            minimumSeparationMinutes: 240,
            clinicalRationale: 'Direct competition for DMT1 metal transporter',
          ),
        ],
      ),
    ),
    const Medication(
      id: 'med_iron',
      name: 'Ferrous Sulfate (Iron)',
      dosage: '65 mg',
      rules: PharmacokineticRule(
        requiresEmptyStomach: true,
        circadianPreference: CircadianWindow.afternoon,
        separationConstraints: [
          DrugSeparationConstraint(
            targetIdentifier: 'Levothyroxine Sodium',
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

  print('\n[1] SOLVING BASELINE DAILY SCHEDULE...');
  final solver = ChronoMedSolver(
    routine: sarahRoutine,
    medications: sarahMedications,
  );

  final result = solver.solve();

  if (result is OptimalSchedule) {
    print('>> Solved in ${result.solveDurationMs}ms (Deterministic AOT Performance)!');
    print('>> Generated ${result.doses.length} collision-free doses:\n');

    for (final dose in result.doses) {
      print('  • [${dose.formattedTime}] ${dose.medicationName} (${dose.dosage})');
      print('    ↳ Clinical: ${dose.clinicalInstruction}');
      print('    ↳ Food Guidance: ${dose.safeFoodWindowNote}\n');
    }
  } else if (result is InfeasibleConflict) {
    print('>> Clinical Conflict Detected: ${result.clinicalExplanation}');
  }

  print('=' * 65);
  print(' SCENARIO: SARAH WAKES UP AT 09:15 AM (Overslept by 2h 15m)');
  print('=' * 65);

  final recalibrated = DynamicRecalibrator.recalibrateForDelayedWakeUp(
    baselineRoutine: sarahRoutine,
    actualWakeTimeMinutes: 555, // 09:15 AM
    medications: sarahMedications,
    targetDate: 'TODAY',
  );

  if (recalibrated is RecalibratedSchedule) {
    print('>> Shift Reason: ${recalibrated.shiftReason}');
    print('>> Summary of Adjustments:');
    for (final s in recalibrated.shiftsSummary) {
      print('   - $s');
    }
    print('\n>> Revised Doses:');
    for (final dose in recalibrated.doses) {
      print('  • [${dose.formattedTime}] ${dose.medicationName} (${dose.dosage})');
    }
  }
  print('\n' + '=' * 65);
}
