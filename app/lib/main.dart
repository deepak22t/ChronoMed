import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_engine/core_engine.dart';
import 'core/state/app_state.dart';
import 'core/state/app_state_provider.dart';
import 'core/theme/chrono_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

// ── Default Regimen — public so SettingsScreen can import for reset ──────────

const defaultRoutine = Routine(
  id: 'routine_sarah',
  userId: 'user_1',
  wakeTimeMinutes: 420,   // 07:00 AM
  sleepTimeMinutes: 1380, // 11:00 PM
  meals: [
    MealAnchor(id: 'm1', type: MealType.breakfast, startTimeMinutes: 510,  durationMinutes: 30),
    MealAnchor(id: 'm2', type: MealType.lunch,     startTimeMinutes: 780,  durationMinutes: 45),
    MealAnchor(id: 'm3', type: MealType.dinner,    startTimeMinutes: 1170, durationMinutes: 45),
  ],
);

final defaultMedications = <Medication>[
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
          clinicalRationale: 'Chelation blocks thyroid hormone absorption by ~80%',
        ),
        DrugSeparationConstraint(
          targetIdentifier: 'Ferrous Sulfate',
          minimumSeparationMinutes: 240,
          clinicalRationale: 'Insoluble iron-thyroxine chelation complex',
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
    rules: PharmacokineticRule(requiresFood: true),
  ),
  const Medication(
    id: 'med_calcium',
    name: 'Calcium Carbonate',
    dosage: '500 mg',
    rules: PharmacokineticRule(
      requiresFood: true,
      separationConstraints: [
        DrugSeparationConstraint(
          targetIdentifier: 'Levothyroxine',
          minimumSeparationMinutes: 240,
          clinicalRationale: 'Calcium chelates levothyroxine — reduces absorption',
        ),
        DrugSeparationConstraint(
          targetIdentifier: 'Ferrous Sulfate',
          minimumSeparationMinutes: 240,
          clinicalRationale: 'Mineral transporter competition reduces both absorptions',
        ),
      ],
    ),
  ),
  const Medication(
    id: 'med_iron',
    name: 'Ferrous Sulfate',
    dosage: '65 mg',
    rules: PharmacokineticRule(
      requiresEmptyStomach: true,
      circadianPreference: CircadianWindow.afternoon,
      separationConstraints: [
        DrugSeparationConstraint(
          targetIdentifier: 'Levothyroxine',
          minimumSeparationMinutes: 240,
          clinicalRationale: 'Iron chelates thyroxine — absorption blocked',
        ),
        DrugSeparationConstraint(
          targetIdentifier: 'Calcium Carbonate',
          minimumSeparationMinutes: 240,
          clinicalRationale: 'Calcium completely blocks iron transporter',
        ),
      ],
    ),
  ),
  const Medication(
    id: 'med_atorvastatin',
    name: 'Atorvastatin',
    dosage: '20 mg',
    rules: PharmacokineticRule(
      circadianPreference: CircadianWindow.bedtime,
    ),
  ),
];

// ── Entry Point ──────────────────────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(
    AppStateProvider(
      state: AppState(
        initialRoutine: defaultRoutine,
        initialMedications: defaultMedications,
      ),
      child: const ChronoMedApp(),
    ),
  );
}

class ChronoMedApp extends StatelessWidget {
  const ChronoMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChronoMed',
      debugShowCheckedModeBanner: false,
      theme: ChronoTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
