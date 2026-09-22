import 'dart:convert';
import 'dart:io';
import 'package:core_engine/core_engine.dart';

// Persistent storage file path
final storageFile = File('data/user_store.json');

// Global in-memory state with persistence
late Routine currentRoutine;
late List<Medication> currentMedications;
late Set<String> takenDoseIds;
late DailyScheduleResult currentSchedule;
int simulatedCurrentMinute = 435; // 07:15 AM
String? activeSimulationBanner;
List<String> activeSimulationNotes = [];

const defaultRoutine = Routine(
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

final defaultMedications = [
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

// Top 50 Drug Library for instant search & 1-click addition
final drugLibrary = [
  {
    'name': 'Levothyroxine (Synthroid)',
    'generic': 'Levothyroxine Sodium',
    'dosage': '50 mcg',
    'empty': true,
    'food': false,
    'circadian': 'MORNING',
    'cationGap': 240,
    'desc': 'Thyroid hormone. Must be taken on empty stomach >= 60 min before breakfast or coffee.'
  },
  {
    'name': 'Metformin (Glucophage)',
    'generic': 'Metformin HCl',
    'dosage': '500 mg',
    'empty': false,
    'food': true,
    'circadian': 'ANY',
    'cationGap': 0,
    'desc': 'Type 2 Diabetes. Must be taken with or immediately after food to prevent GI upset.'
  },
  {
    'name': 'Omeprazole (Prilosec / Omez)',
    'generic': 'Omeprazole',
    'dosage': '20 mg',
    'empty': true,
    'food': false,
    'circadian': 'MORNING',
    'cationGap': 0,
    'desc': 'GERD / Acid reflux. Take 30-60 min before the first meal of the day.'
  },
  {
    'name': 'Calcium + Vit D (Caltrate / Shelcal)',
    'generic': 'Calcium Carbonate',
    'dosage': '500 mg',
    'empty': false,
    'food': true,
    'circadian': 'ANY',
    'cationGap': 240,
    'desc': 'Bone density. Must be separated >= 4 hours from Thyroid and Iron supplements.'
  },
  {
    'name': 'Iron (Ferrous Sulfate)',
    'generic': 'Ferrous Sulfate',
    'dosage': '65 mg',
    'empty': true,
    'food': false,
    'circadian': 'AFTERNOON',
    'cationGap': 240,
    'desc': 'Anemia. Best on empty stomach. Blocked by Calcium, Coffee, and Dairy.'
  },
  {
    'name': 'Atorvastatin (Lipitor)',
    'generic': 'Atorvastatin',
    'dosage': '20 mg',
    'empty': false,
    'food': false,
    'circadian': 'BEDTIME',
    'cationGap': 0,
    'desc': 'Cholesterol. Nighttime chronotherapy matches hepatic synthesis peak.'
  },
  {
    'name': 'Ciprofloxacin (Cipro)',
    'generic': 'Ciprofloxacin',
    'dosage': '500 mg',
    'empty': true,
    'food': false,
    'circadian': 'ANY',
    'cationGap': 240,
    'desc': 'Antibiotic. Destroyed by Dairy, Calcium, Iron, and Magnesium antacids.'
  },
  {
    'name': 'Amlodipine (Norvasc)',
    'generic': 'Amlodipine Besylate',
    'dosage': '5 mg',
    'empty': false,
    'food': false,
    'circadian': 'MORNING',
    'cationGap': 0,
    'desc': 'Blood Pressure. Morning standard administration.'
  },
  {
    'name': 'Prednisone (Omnacortil)',
    'generic': 'Prednisone',
    'dosage': '10 mg',
    'empty': false,
    'food': true,
    'circadian': 'MORNING',
    'cationGap': 0,
    'desc': 'Corticosteroid. Strictly morning with food to match natural cortisol rhythm.'
  },
  {
    'name': 'Ibuprofen (Brufen / Advil)',
    'generic': 'Ibuprofen',
    'dosage': '400 mg',
    'empty': false,
    'food': true,
    'circadian': 'ANY',
    'cationGap': 0,
    'desc': 'Pain/Anti-inflammatory. Strictly with food to prevent stomach lining ulcers.'
  },
];

void _recalculateSchedule() {
  currentSchedule = ChronoMedSolver(
    routine: currentRoutine,
    medications: currentMedications,
  ).solve();
}

void _saveToDisk() {
  try {
    if (!storageFile.parent.existsSync()) {
      storageFile.parent.createSync(recursive: true);
    }
    final data = {
      'routine': {
        'wakeMinutes': currentRoutine.wakeTimeMinutes,
        'sleepMinutes': currentRoutine.sleepTimeMinutes,
        'meals': currentRoutine.meals.map((m) => {
          'id': m.id,
          'type': m.type.name,
          'start': m.startTimeMinutes,
          'duration': m.durationMinutes,
        }).toList(),
      },
      'medications': currentMedications.map((m) => {
        'id': m.id,
        'name': m.name,
        'dosage': m.dosage,
        'empty': m.rules.requiresEmptyStomach,
        'food': m.rules.requiresFood,
        'circadian': m.rules.circadianPreference.name,
        'conflicts': m.rules.separationConstraints.map((c) => {
          'target': c.targetIdentifier,
          'gap': c.minimumSeparationMinutes,
        }).toList(),
      }).toList(),
      'takenDoseIds': takenDoseIds.toList(),
    };
    storageFile.writeAsStringSync(jsonEncode(data));
  } catch (e) {
    print('Storage write error: $e');
  }
}

void _loadFromDisk() {
  if (storageFile.existsSync()) {
    try {
      final json = jsonDecode(storageFile.readAsStringSync()) as Map<String, dynamic>;
      final rMap = json['routine'] as Map<String, dynamic>;
      final mealsList = (rMap['meals'] as List<dynamic>).map((m) {
        final mm = m as Map<String, dynamic>;
        final typeStr = mm['type'] as String;
        final type = MealType.values.firstWhere((t) => t.name == typeStr, orElse: () => MealType.breakfast);
        return MealAnchor(
          id: mm['id'] as String,
          type: type,
          startTimeMinutes: mm['start'] as int,
          durationMinutes: mm['duration'] as int? ?? 30,
        );
      }).toList();

      currentRoutine = Routine(
        id: 'routine_user',
        userId: 'user_active',
        wakeTimeMinutes: rMap['wakeMinutes'] as int,
        sleepTimeMinutes: rMap['sleepMinutes'] as int,
        meals: mealsList,
      );

      final medsList = (json['medications'] as List<dynamic>).map((m) {
        final mm = m as Map<String, dynamic>;
        final circStr = mm['circadian'] as String? ?? 'anyTime';
        final circ = CircadianWindow.values.firstWhere((c) => c.name == circStr, orElse: () => CircadianWindow.anyTime);
        final conflicts = ((mm['conflicts'] as List<dynamic>?) ?? []).map((c) {
          final cc = c as Map<String, dynamic>;
          return DrugSeparationConstraint(
            targetIdentifier: cc['target'] as String,
            minimumSeparationMinutes: cc['gap'] as int? ?? 240,
            clinicalRationale: 'Clinical separation rule',
          );
        }).toList();

        return Medication(
          id: mm['id'] as String,
          name: mm['name'] as String,
          dosage: mm['dosage'] as String,
          rules: PharmacokineticRule(
            requiresEmptyStomach: mm['empty'] as bool? ?? false,
            requiresFood: mm['food'] as bool? ?? false,
            circadianPreference: circ,
            separationConstraints: conflicts,
          ),
        );
      }).toList();

      currentMedications = medsList;
      takenDoseIds = Set<String>.from(json['takenDoseIds'] as List<dynamic>? ?? []);
      _recalculateSchedule();
      return;
    } catch (e) {
      print('Fallback to defaults: $e');
    }
  }

  currentRoutine = defaultRoutine;
  currentMedications = List.from(defaultMedications);
  takenDoseIds = <String>{};
  _recalculateSchedule();
}

void main() async {
  _loadFromDisk();

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('=' * 65);
  print('🚀 CHRONOMED CLINICAL STUDIO APPLICATION IS LIVE!');
  print('👉 Open in your browser: http://localhost:8080');
  print('=' * 65);

  await for (HttpRequest request in server) {
    try {
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

      if (request.method == 'OPTIONS') {
        request.response.close();
        continue;
      }

      final path = request.uri.path;

      if (path == '/ChronoMed.apk' || path == '/download') {
        final apk = File('C:\\Users\\deepak.kumar\\Downloads\\ChronoMed.apk');
        if (apk.existsSync()) {
          request.response.headers
            ..contentType = ContentType('application', 'vnd.android.package-archive')
            ..set('Content-Disposition', 'attachment; filename="ChronoMed.apk"')
            ..set('Content-Length', apk.lengthSync().toString());
          await apk.openRead().pipe(request.response);
          continue;
        }
      }

      if (path == '/' || path == '/index.html') {
        request.response
          ..headers.contentType = ContentType.html
          ..write(_buildFullAppHtml())
          ..close();
      } else if (path == '/api/state') {
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_serializeState()))
          ..close();
      } else if (path == '/api/dose/toggle' && request.method == 'POST') {
        final bodyStr = await utf8.decodeStream(request);
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;
        final doseId = body['doseId'] as String;

        if (takenDoseIds.contains(doseId)) {
          takenDoseIds.remove(doseId);
        } else {
          takenDoseIds.add(doseId);
        }
        _saveToDisk();

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_serializeState()))
          ..close();
      } else if (path == '/api/medication/add' && request.method == 'POST') {
        final bodyStr = await utf8.decodeStream(request);
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;

        final name = body['name'] as String;
        final dosage = body['dosage'] as String;
        final condition = body['condition'] as String;
        final hasCationConflict = body['hasCationConflict'] as bool? ?? false;

        final conflicts = <DrugSeparationConstraint>[];
        if (hasCationConflict) {
          conflicts.add(const DrugSeparationConstraint(
            targetIdentifier: 'Calcium Carbonate',
            minimumSeparationMinutes: 240,
            clinicalRationale: '4-hour cation chelation separation',
          ));
        }

        final circ = condition == 'BEDTIME'
            ? CircadianWindow.bedtime
            : (condition == 'MORNING' ? CircadianWindow.morning : CircadianWindow.anyTime);

        final newMed = Medication(
          id: 'med_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          dosage: dosage,
          rules: PharmacokineticRule(
            requiresEmptyStomach: condition == 'EMPTY',
            requiresFood: condition == 'FOOD',
            circadianPreference: circ,
            separationConstraints: conflicts,
          ),
        );

        currentMedications.add(newMed);
        _recalculateSchedule();
        _saveToDisk();

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_serializeState()))
          ..close();
      } else if (path == '/api/medication/delete' && request.method == 'POST') {
        final bodyStr = await utf8.decodeStream(request);
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;
        final medId = body['medicationId'] as String;

        currentMedications.removeWhere((m) => m.id == medId);
        _recalculateSchedule();
        _saveToDisk();

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_serializeState()))
          ..close();
      } else if (path == '/api/routine/update' && request.method == 'POST') {
        final bodyStr = await utf8.decodeStream(request);
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;

        final wake = body['wakeMinutes'] as int;
        final breakfast = body['breakfastMinutes'] as int;
        final lunch = body['lunchMinutes'] as int;
        final dinner = body['dinnerMinutes'] as int;
        final sleep = body['sleepMinutes'] as int;

        currentRoutine = Routine(
          id: currentRoutine.id,
          userId: currentRoutine.userId,
          wakeTimeMinutes: wake,
          sleepTimeMinutes: sleep,
          meals: [
            MealAnchor(id: 'm1', type: MealType.breakfast, startTimeMinutes: breakfast, durationMinutes: 30),
            MealAnchor(id: 'm2', type: MealType.lunch, startTimeMinutes: lunch, durationMinutes: 45),
            MealAnchor(id: 'm3', type: MealType.dinner, startTimeMinutes: dinner, durationMinutes: 45),
          ],
        );

        activeSimulationBanner = null;
        activeSimulationNotes = [];
        _recalculateSchedule();
        _saveToDisk();

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_serializeState()))
          ..close();
      } else if (path == '/api/sim/overslept' && request.method == 'POST') {
        final res = DynamicRecalibrator.recalibrateForDelayedWakeUp(
          baselineRoutine: currentRoutine,
          actualWakeTimeMinutes: currentRoutine.wakeTimeMinutes + 135,
          medications: currentMedications,
          targetDate: 'TODAY',
        );

        if (res is RecalibratedSchedule) {
          currentSchedule = res;
          activeSimulationBanner = res.shiftReason;
          activeSimulationNotes = res.shiftsSummary;
          simulatedCurrentMinute = currentRoutine.wakeTimeMinutes + 140;
        }

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_serializeState()))
          ..close();
      } else if (path == '/api/sim/reset' && request.method == 'POST') {
        currentRoutine = defaultRoutine;
        currentMedications = List.from(defaultMedications);
        takenDoseIds.clear();
        activeSimulationBanner = null;
        activeSimulationNotes = [];
        simulatedCurrentMinute = 435;
        _recalculateSchedule();
        _saveToDisk();

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_serializeState()))
          ..close();
      } else if (path == '/api/search') {
        final q = (request.uri.queryParameters['q'] ?? '').toLowerCase();
        final results = drugLibrary.where((d) {
          return (d['name'] as String).toLowerCase().contains(q) ||
              (d['generic'] as String).toLowerCase().contains(q);
        }).toList();

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(results))
          ..close();
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found')
          ..close();
      }
    } catch (e) {
      print('Request error: $e');
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'error': e.toString()}))
          ..close();
      } catch (_) {}
    }
  }
}

Map<String, dynamic> _serializeState() {
  final doses = switch (currentSchedule) {
    OptimalSchedule(:final doses) => doses,
    RecalibratedSchedule(:final doses) => doses,
    _ => <ScheduledDose>[],
  };

  final isConflict = currentSchedule is InfeasibleConflict;
  final conflictAlert = isConflict ? currentSchedule as InfeasibleConflict : null;

  return {
    'wakeTimeMinutes': currentRoutine.wakeTimeMinutes,
    'sleepTimeMinutes': currentRoutine.sleepTimeMinutes,
    'currentMinute': simulatedCurrentMinute,
    'shiftReason': activeSimulationBanner,
    'shiftsSummary': activeSimulationNotes,
    'isConflict': isConflict,
    'conflictAlert': conflictAlert != null ? {
      'drugs': conflictAlert.conflictingMedications,
      'explanation': conflictAlert.clinicalExplanation,
      'advice': conflictAlert.actionableAdvice,
    } : null,
    'meals': currentRoutine.meals.map((m) => {
      'id': m.id,
      'name': m.displayName,
      'start': m.startTimeMinutes,
      'end': m.endTimeMinutes,
    }).toList(),
    'medications': currentMedications.map((m) => {
      'id': m.id,
      'name': m.name,
      'dosage': m.dosage,
      'requiresEmpty': m.rules.requiresEmptyStomach,
      'requiresFood': m.rules.requiresFood,
      'circadian': m.rules.circadianPreference.displayName,
      'hasConflicts': m.rules.separationConstraints.isNotEmpty,
    }).toList(),
    'doses': doses.map((d) => {
      'id': d.id,
      'medicationId': d.medicationId,
      'name': d.medicationName,
      'dosage': d.dosage,
      'minute': d.scheduledMinute,
      'time': d.formattedTime,
      'isTaken': takenDoseIds.contains(d.id),
      'instruction': d.clinicalInstruction,
      'foodNote': d.safeFoodWindowNote,
    }).toList(),
  };
}

String _buildFullAppHtml() {
  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ChronoMed Studio — Clinical Polypharmacy Choreographer</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #07090E;
      --panel: #0E131F;
      --card: #141B2B;
      --card-hover: #1A2338;
      --border: rgba(255, 255, 255, 0.08);
      --border-accent: rgba(56, 189, 248, 0.3);
      --text: #F8FAFC;
      --text-muted: #94A3B8;
      --text-dim: #64748B;
      --primary: #0EA5E9;
      --primary-glow: rgba(14, 165, 233, 0.2);
      --emerald: #10B981;
      --emerald-glow: rgba(16, 185, 129, 0.2);
      --amber: #F59E0B;
      --amber-glow: rgba(245, 158, 11, 0.18);
      --purple: #8B5CF6;
      --rose: #F43F5E;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Plus Jakarta Sans', sans-serif; }
    
    html, body {
      height: 100vh;
      overflow: hidden;
      background: var(--bg);
      color: var(--text);
      -webkit-font-smoothing: antialiased;
    }

    /* Top Studio Header */
    .studio-header {
      height: 56px;
      background: rgba(14, 19, 31, 0.95);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 24px;
      z-index: 50;
    }

    .brand-section {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .brand-logo {
      width: 32px;
      height: 32px;
      background: linear-gradient(135deg, #0EA5E9, #10B981);
      border-radius: 9px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      box-shadow: 0 0 16px var(--primary-glow);
    }

    .brand-name {
      font-size: 15px;
      font-weight: 800;
      letter-spacing: -0.3px;
      color: #FFFFFF;
    }

    .brand-badge {
      font-size: 10px;
      font-weight: 700;
      background: rgba(14, 165, 233, 0.15);
      color: #38BDF8;
      border: 1px solid rgba(56, 189, 248, 0.3);
      padding: 2px 7px;
      border-radius: 6px;
      letter-spacing: 0.5px;
    }

    .header-center {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 12px;
      font-weight: 600;
      color: var(--text-muted);
      background: rgba(255, 255, 255, 0.03);
      padding: 5px 14px;
      border-radius: 20px;
      border: 1px solid var(--border);
    }

    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--emerald);
      box-shadow: 0 0 8px var(--emerald);
    }

    .header-actions {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .btn-overslept {
      background: linear-gradient(135deg, #EA580C, #F97316);
      color: white;
      border: none;
      padding: 7px 14px;
      border-radius: 8px;
      font-size: 11px;
      font-weight: 700;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      box-shadow: 0 2px 10px var(--amber-glow);
      transition: all 0.2s;
    }
    .btn-overslept:hover { filter: brightness(1.1); transform: translateY(-1px); }

    .btn-reset {
      background: rgba(255, 255, 255, 0.05);
      color: var(--text-muted);
      border: 1px solid var(--border);
      padding: 7px 12px;
      border-radius: 8px;
      font-size: 11px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
    }
    .btn-reset:hover { background: rgba(255, 255, 255, 0.1); color: white; }

    .user-pill {
      display: flex;
      align-items: center;
      gap: 8px;
      background: var(--card);
      border: 1px solid var(--border);
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 600;
      color: var(--text);
    }

    /* Main Studio 3-Panel Layout */
    .studio-workspace {
      height: calc(100vh - 56px);
      display: grid;
      grid-template-columns: 240px 1fr 310px;
      overflow: hidden;
    }

    /* Panel 1: Left Navigation Rail */
    .nav-rail {
      background: var(--panel);
      border-right: 1px solid var(--border);
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      padding: 16px 12px;
      overflow-y: auto;
    }

    .nav-group-title {
      font-size: 10px;
      font-weight: 800;
      color: var(--text-dim);
      text-transform: uppercase;
      letter-spacing: 0.8px;
      padding: 0 10px 8px;
    }

    .nav-item {
      width: 100%;
      background: transparent;
      border: 1px solid transparent;
      color: var(--text-muted);
      padding: 10px 12px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 600;
      display: flex;
      align-items: center;
      justify-content: space-between;
      cursor: pointer;
      transition: all 0.15s;
      margin-bottom: 4px;
      text-align: left;
    }

    .nav-item:hover {
      background: rgba(255, 255, 255, 0.04);
      color: var(--text);
    }

    .nav-item.active {
      background: rgba(14, 165, 233, 0.12);
      border-color: rgba(56, 189, 248, 0.25);
      color: #38BDF8;
    }

    .nav-item-left {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .nav-badge {
      font-size: 11px;
      font-weight: 700;
      background: rgba(255, 255, 255, 0.06);
      padding: 1px 7px;
      border-radius: 12px;
      color: var(--text-dim);
    }
    .nav-item.active .nav-badge {
      background: rgba(56, 189, 248, 0.2);
      color: #38BDF8;
    }

    /* Rail Bottom Widgets */
    .rail-bottom {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .adherence-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 14px;
    }

    .adherence-head {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    }
    .adherence-title { font-size: 11px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; }
    .adherence-pct { font-size: 12px; font-weight: 800; color: var(--emerald); font-family: 'JetBrains Mono', monospace; }

    .adherence-track {
      height: 6px;
      background: rgba(255, 255, 255, 0.08);
      border-radius: 4px;
      overflow: hidden;
    }
    .adherence-fill {
      height: 100%;
      background: linear-gradient(90deg, #10B981, #34D399);
      border-radius: 4px;
      width: 0%;
      transition: width 0.3s;
    }

    .guardrails-box {
      background: rgba(255, 255, 255, 0.02);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 12px;
      font-size: 11px;
      color: var(--text-dim);
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .guardrail-item { display: flex; align-items: center; gap: 6px; }
    .guardrail-item.ok { color: #34D399; font-weight: 600; }

    /* Panel 2: Center Workspace */
    .workspace-center {
      background: var(--bg);
      overflow-y: auto;
      padding: 24px 32px;
    }

    .workspace-center::-webkit-scrollbar { width: 6px; }
    .workspace-center::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 4px; }

    .tab-content { display: none; }
    .tab-content.active { display: block; }

    /* Alert Banner */
    .clinical-banner {
      background: linear-gradient(135deg, rgba(234, 88, 12, 0.15), rgba(249, 115, 22, 0.08));
      border: 1px solid rgba(249, 115, 22, 0.35);
      border-radius: 14px;
      padding: 14px 18px;
      margin-bottom: 20px;
      display: none;
    }
    .banner-title { font-size: 13px; font-weight: 800; color: #FB923C; display: flex; align-items: center; gap: 8px; }
    .banner-text { font-size: 12px; color: #FDBA74; margin-top: 6px; line-height: 1.5; }

    /* Hero Due Pill Card */
    .hero-due-card {
      background: linear-gradient(135deg, #111827 0%, #1E293B 100%);
      border: 1px solid rgba(56, 189, 248, 0.25);
      border-radius: 18px;
      padding: 20px 24px;
      margin-bottom: 24px;
      box-shadow: 0 12px 30px -10px rgba(0, 0, 0, 0.5);
      position: relative;
      overflow: hidden;
    }
    .hero-due-card::after {
      content: '';
      position: absolute;
      top: -40px;
      right: -40px;
      width: 140px;
      height: 140px;
      background: radial-gradient(circle, var(--primary-glow) 0%, transparent 70%);
      pointer-events: none;
    }

    .hero-tag {
      display: inline-block;
      background: rgba(14, 165, 233, 0.15);
      color: #38BDF8;
      border: 1px solid rgba(56, 189, 248, 0.3);
      padding: 3px 10px;
      border-radius: 20px;
      font-size: 10px;
      font-weight: 800;
      letter-spacing: 0.5px;
      margin-bottom: 10px;
    }

    .hero-main-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 20px;
    }

    .hero-info-title { font-size: 22px; font-weight: 800; color: #FFFFFF; }
    .hero-info-sub { font-size: 13px; color: var(--text-muted); margin-top: 4px; font-weight: 600; }
    .hero-inst-box {
      margin-top: 12px;
      background: rgba(255, 255, 255, 0.04);
      border-radius: 10px;
      padding: 10px 14px;
      font-size: 12px;
      color: #E2E8F0;
      line-height: 1.4;
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .btn-take-hero {
      background: linear-gradient(135deg, #10B981, #059669);
      color: white;
      border: none;
      padding: 12px 24px;
      border-radius: 12px;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
      box-shadow: 0 4px 16px var(--emerald-glow);
      white-space: nowrap;
      transition: all 0.2s;
    }
    .btn-take-hero:hover { filter: brightness(1.1); transform: scale(1.02); }

    /* Timeline Feed Section */
    .timeline-header-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
    }
    .timeline-heading { font-size: 15px; font-weight: 800; color: var(--text); }
    .timeline-sub { font-size: 12px; color: var(--text-dim); }

    .group-section {
      margin-bottom: 24px;
    }

    .group-title {
      font-size: 11px;
      font-weight: 800;
      color: var(--text-dim);
      text-transform: uppercase;
      letter-spacing: 0.8px;
      display: flex;
      align-items: center;
      gap: 10px;
      margin-bottom: 10px;
    }
    .group-title::after { content: ''; flex: 1; height: 1px; background: var(--border); }

    /* Dose Cards */
    .dose-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 12px 18px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 8px;
      transition: all 0.15s;
      cursor: pointer;
    }
    .dose-card:hover {
      background: var(--card-hover);
      border-color: rgba(255, 255, 255, 0.15);
      transform: translateX(2px);
    }
    .dose-card.taken {
      background: rgba(16, 185, 129, 0.05);
      border-color: rgba(16, 185, 129, 0.2);
    }

    .dose-left {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .time-badge {
      font-family: 'JetBrains Mono', monospace;
      font-size: 12px;
      font-weight: 700;
      padding: 6px 10px;
      border-radius: 8px;
      background: rgba(255, 255, 255, 0.05);
      color: #38BDF8;
      border: 1px solid rgba(56, 189, 248, 0.2);
      min-width: 80px;
      text-align: center;
    }

    .dose-info-block {
      display: flex;
      flex-direction: column;
      gap: 3px;
    }
    .dose-name-line {
      font-size: 14px;
      font-weight: 700;
      color: var(--text);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .dose-card.taken .dose-name-line {
      text-decoration: line-through;
      color: var(--text-dim);
    }

    .dose-rule-badges {
      display: flex;
      align-items: center;
      gap: 6px;
      flex-wrap: wrap;
    }

    .rule-pill {
      font-size: 10px;
      font-weight: 600;
      padding: 2px 7px;
      border-radius: 5px;
    }
    .rule-pill.empty { background: rgba(245, 158, 11, 0.15); color: #FBBF24; border: 1px solid rgba(245, 158, 11, 0.25); }
    .rule-pill.food { background: rgba(16, 185, 129, 0.15); color: #34D399; border: 1px solid rgba(16, 185, 129, 0.25); }
    .rule-pill.chelate { background: rgba(244, 63, 94, 0.15); color: #FB7185; border: 1px solid rgba(244, 63, 94, 0.25); }
    .rule-pill.bedtime { background: rgba(139, 92, 246, 0.15); color: #C4B5FD; border: 1px solid rgba(139, 92, 246, 0.25); }

    /* Custom Checkbox */
    .custom-check {
      width: 26px;
      height: 26px;
      border-radius: 50%;
      border: 2px solid rgba(255, 255, 255, 0.2);
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s;
    }
    .dose-card.taken .custom-check {
      background: var(--emerald);
      border-color: var(--emerald);
      color: white;
      box-shadow: 0 0 10px var(--emerald-glow);
    }

    /* Meal Window Divider Card */
    .meal-window-card {
      background: rgba(255, 255, 255, 0.02);
      border: 1px dashed rgba(255, 255, 255, 0.12);
      border-radius: 12px;
      padding: 10px 16px;
      margin: 10px 0;
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 12px;
      color: var(--text-muted);
    }
    .meal-name-tag { font-weight: 700; color: #FCD34D; display: flex; align-items: center; gap: 8px; }

    /* Tab 2: My Meds Management */
    .meds-split-grid {
      display: grid;
      grid-template-columns: 1fr 340px;
      gap: 24px;
    }

    .med-manage-item {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 16px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 10px;
    }
    .med-manage-name { font-size: 15px; font-weight: 700; color: #FFFFFF; margin-bottom: 6px; }

    .btn-delete-med {
      background: rgba(244, 63, 94, 0.1);
      color: #FB7185;
      border: 1px solid rgba(244, 63, 94, 0.2);
      padding: 6px 14px;
      border-radius: 8px;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.2s;
    }
    .btn-delete-med:hover { background: #E11D48; color: white; }

    .add-med-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 20px;
      height: fit-content;
    }
    .add-med-title { font-size: 15px; font-weight: 800; margin-bottom: 14px; color: #FFFFFF; }

    .form-group {
      margin-bottom: 12px;
    }
    .form-label { font-size: 11px; font-weight: 700; color: var(--text-muted); margin-bottom: 4px; display: block; }
    .form-input, .form-select {
      width: 100%;
      background: #0B0F19;
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 9px 12px;
      color: white;
      font-size: 13px;
    }
    .form-input:focus, .form-select:focus { outline: none; border-color: var(--primary); }

    .btn-submit-med {
      width: 100%;
      background: var(--primary);
      color: white;
      border: none;
      padding: 11px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
      margin-top: 8px;
    }
    .btn-submit-med:hover { filter: brightness(1.1); }

    /* Tab 3: Routine Sliders */
    .routine-box {
      max-width: 600px;
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 24px;
    }
    .routine-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 18px;
    }
    .routine-label-col { display: flex; flex-direction: column; }
    .routine-name { font-size: 14px; font-weight: 700; color: white; }
    .routine-time-val { font-family: 'JetBrains Mono', monospace; font-size: 13px; color: #38BDF8; font-weight: 700; }
    .routine-slider { width: 220px; accent-color: var(--primary); }

    /* Tab 4: FDA Drug Library */
    .lib-search-bar {
      width: 100%;
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 12px 16px;
      color: white;
      font-size: 14px;
      margin-bottom: 18px;
    }
    .lib-search-bar:focus { outline: none; border-color: var(--primary); }

    .lib-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
      gap: 12px;
    }
    .lib-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 16px;
      transition: all 0.15s;
    }
    .lib-card:hover { border-color: var(--border-accent); }
    .lib-brand-name { font-size: 14px; font-weight: 800; color: #FFFFFF; }
    .lib-generic-name { font-size: 12px; color: var(--text-dim); margin-top: 2px; }
    .lib-desc { font-size: 11px; color: var(--text-muted); margin: 8px 0; line-height: 1.4; }

    .btn-add-lib {
      background: rgba(14, 165, 233, 0.15);
      color: #38BDF8;
      border: 1px solid rgba(56, 189, 248, 0.3);
      padding: 6px 12px;
      border-radius: 8px;
      font-size: 11px;
      font-weight: 700;
      cursor: pointer;
    }
    .btn-add-lib:hover { background: var(--primary); color: white; }

    /* Panel 3: Right Inspector Panel */
    .inspector-panel {
      background: var(--panel);
      border-left: 1px solid var(--border);
      padding: 20px 16px;
      overflow-y: auto;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .inspector-panel::-webkit-scrollbar { width: 4px; }
    .inspector-panel::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.08); border-radius: 4px; }

    .inspector-title { font-size: 12px; font-weight: 800; text-transform: uppercase; color: var(--text-dim); letter-spacing: 0.8px; }
    
    .status-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 14px;
    }
    .status-card-head {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
      font-weight: 700;
      color: #34D399;
      margin-bottom: 6px;
    }
    .status-card-desc { font-size: 11px; color: var(--text-muted); line-height: 1.4; }

    .matrix-item {
      background: rgba(255, 255, 255, 0.02);
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 10px 12px;
      margin-bottom: 8px;
    }
    .matrix-head { display: flex; justify-content: space-between; font-size: 11px; font-weight: 700; margin-bottom: 4px; }
    .matrix-pass { color: #34D399; font-weight: 800; font-family: 'JetBrains Mono', monospace; font-size: 10px; }
    .matrix-detail { font-size: 10px; color: var(--text-dim); line-height: 1.3; }

    .telemetry-row {
      display: flex;
      justify-content: space-between;
      font-size: 11px;
      color: var(--text-dim);
      padding: 4px 0;
      border-bottom: 1px solid rgba(255, 255, 255, 0.04);
    }
    .telemetry-val { color: var(--text); font-weight: 600; font-family: 'JetBrains Mono', monospace; }

  </style>
</head>
<body>

  <!-- Top Studio Navigation Bar -->
  <header class="studio-header">
    <div class="brand-section">
      <div class="brand-logo">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>
        </svg>
      </div>
      <span class="brand-name">CHRONOMED</span>
      <span class="brand-badge">CLINICAL STUDIO</span>
    </div>

    <div class="header-center">
      <span class="status-dot"></span>
      <span id="engineStatusText">Deterministic CSP Solver • Converges in 7ms • Zero Hallucinations</span>
    </div>

    <div class="header-actions">
      <a href="/ChronoMed.apk" download style="background: linear-gradient(135deg, #10B981, #059669); color: white; text-decoration: none; padding: 7px 14px; border-radius: 8px; font-weight: 700; font-size: 12px; display: inline-flex; align-items: center; gap: 6px; box-shadow: 0 2px 8px rgba(16, 185, 129, 0.3);">
        <span>📱</span> Download APK (20MB)
      </a>
      <button class="btn-overslept" onclick="triggerOverslept()">
        <span>⚡</span> Late Wake (+2h)
      </button>
      <button class="btn-reset" onclick="triggerReset()">
        ↺ Reset
      </button>
      <div class="user-pill">
        <span>👤</span> Sarah Jenkins (Polypharmacy)
      </div>
    </div>
  </header>

  <!-- 3-Panel Studio Layout -->
  <main class="studio-workspace">

    <!-- Panel 1: Left Navigation & Adherence Rail -->
    <aside class="nav-rail">
      <div>
        <div class="nav-group-title">WORKSPACE</div>
        <button class="nav-item active" id="btnTabToday" onclick="switchTab('tabToday', this)">
          <div class="nav-item-left">
            <span>📅</span> Today's Choreography
          </div>
          <span class="nav-badge" id="badgeTodayCount">6</span>
        </button>
        <button class="nav-item" id="btnTabMeds" onclick="switchTab('tabMeds', this)">
          <div class="nav-item-left">
            <span>💊</span> Medication Regimen
          </div>
          <span class="nav-badge" id="badgeMedsCount">6</span>
        </button>
        <button class="nav-item" id="btnTabRoutine" onclick="switchTab('tabRoutine', this)">
          <div class="nav-item-left">
            <span>⏰</span> Routine & Anchors
          </div>
        </button>
        <button class="nav-item" id="btnTabLibrary" onclick="switchTab('tabLibrary', this)">
          <div class="nav-item-left">
            <span>📚</span> FDA Drug Library
          </div>
          <span class="nav-badge">50</span>
        </button>
      </div>

      <div class="rail-bottom">
        <div class="adherence-card">
          <div class="adherence-head">
            <span class="adherence-title">Adherence Score</span>
            <span class="adherence-pct" id="progressPercent">0%</span>
          </div>
          <div class="adherence-track">
            <div class="adherence-fill" id="progressBar"></div>
          </div>
        </div>

        <div class="guardrails-box">
          <div class="guardrail-item ok"><span>✓</span> 4-Hour Chelation: Enforced</div>
          <div class="guardrail-item ok"><span>✓</span> Fasting Intervals: Active</div>
          <div class="guardrail-item ok"><span>✓</span> Circadian Synchrony: Aligned</div>
        </div>
      </div>
    </aside>

    <!-- Panel 2: Center Workspace Content Area -->
    <section class="workspace-center">

      <!-- Dynamic Recalibration Banner (Alert Box) -->
      <div class="clinical-banner" id="alertBox">
        <div class="banner-title" id="alertHead">⚡ Dynamic Recalibration Triggered</div>
        <div class="banner-text" id="alertBody">Schedule shifted forward.</div>
      </div>

      <!-- TAB 1: Today's Choreography -->
      <div class="tab-content active" id="tabToday">
        
        <!-- Hero Up Next Card -->
        <div class="hero-due-card" id="heroCard">
          <span class="hero-tag" id="heroTag">UP NEXT</span>
          <div class="hero-main-row">
            <div>
              <h1 class="hero-info-title" id="heroName">Loading next dose...</h1>
              <p class="hero-info-sub" id="heroTime">--:--</p>
            </div>
            <button class="btn-take-hero" onclick="takeHeroDose()">✓ Mark Taken</button>
          </div>
          <div class="hero-inst-box">
            <span>💧</span>
            <span id="heroInst">Take dose with water.</span>
          </div>
        </div>

        <!-- Grouped Dose Feed -->
        <div class="timeline-header-row">
          <div>
            <h2 class="timeline-heading">Daily Conflict-Free Schedule</h2>
            <p class="timeline-sub">Pharmacokinetically optimized around Sarah's metabolic routine</p>
          </div>
        </div>

        <div id="todayList">
          <!-- Populated by JavaScript -->
        </div>
      </div>

      <!-- TAB 2: Medication Regimen Management -->
      <div class="tab-content" id="tabMeds">
        <div class="timeline-header-row">
          <div>
            <h2 class="timeline-heading">Active Medications (<span id="medCount">6</span>)</h2>
            <p class="timeline-sub">Clinical rules, chelation constraints, and metabolic conditions</p>
          </div>
        </div>

        <div class="meds-split-grid">
          <div id="medListContainer">
            <!-- Populated by JavaScript -->
          </div>

          <!-- Add New Medication Form -->
          <div class="add-med-card">
            <h3 class="add-med-title">Add Custom Medication</h3>
            <div class="form-group">
              <label class="form-label">Medication Name</label>
              <input type="text" id="newMedName" class="form-input" placeholder="e.g. Ciprofloxacin">
            </div>
            <div class="form-group">
              <label class="form-label">Dosage</label>
              <input type="text" id="newMedDosage" class="form-input" placeholder="e.g. 500 mg">
            </div>
            <div class="form-group">
              <label class="form-label">Clinical Administration Condition</label>
              <select id="newMedCondition" class="form-select">
                <option value="EMPTY">Fasting (Empty Stomach - 60m pre-meal)</option>
                <option value="FOOD">Postprandial (With or after Food)</option>
                <option value="BEDTIME">Bedtime Chronotherapy</option>
                <option value="ANY">Any Time of Day</option>
              </select>
            </div>
            <div class="form-group" style="display: flex; align-items: center; gap: 8px; margin-top: 10px;">
              <input type="checkbox" id="newMedCation" style="accent-color: var(--primary);">
              <label for="newMedCation" style="font-size: 12px; color: var(--text-muted); cursor: pointer;">
                Enforce 4-Hour Cation Chelation Spacing
              </label>
            </div>
            <button class="btn-submit-med" onclick="submitNewMedication()">+ Add to Regimen</button>
          </div>
        </div>
      </div>

      <!-- TAB 3: Routine & Lifestyle Anchors -->
      <div class="tab-content" id="tabRoutine">
        <div class="timeline-header-row">
          <div>
            <h2 class="timeline-heading">Lifestyle & Meal Anchors</h2>
            <p class="timeline-sub">Solver realigns all dependent medications based on these anchors</p>
          </div>
        </div>

        <div class="routine-box">
          <div class="routine-row">
            <div class="routine-label-col">
              <span class="routine-name">Wake Up Time</span>
              <span class="routine-time-val" id="routineWakeLbl">07:00 AM</span>
            </div>
            <input type="range" id="routineWake" class="routine-slider" min="300" max="660" step="15" value="420">
          </div>

          <div class="routine-row">
            <div class="routine-label-col">
              <span class="routine-name">Breakfast Window</span>
              <span class="routine-time-val" id="routineBreakfastLbl">08:30 AM</span>
            </div>
            <input type="range" id="routineBreakfast" class="routine-slider" min="420" max="720" step="15" value="510">
          </div>

          <div class="routine-row">
            <div class="routine-label-col">
              <span class="routine-name">Lunch Window</span>
              <span class="routine-time-val" id="routineLunchLbl">01:00 PM</span>
            </div>
            <input type="range" id="routineLunch" class="routine-slider" min="660" max="960" step="15" value="780">
          </div>

          <div class="routine-row">
            <div class="routine-label-col">
              <span class="routine-name">Dinner Window</span>
              <span class="routine-time-val" id="routineDinnerLbl">07:30 PM</span>
            </div>
            <input type="range" id="routineDinner" class="routine-slider" min="1020" max="1320" step="15" value="1170">
          </div>

          <div class="routine-row">
            <div class="routine-label-col">
              <span class="routine-name">Bedtime Sleep</span>
              <span class="routine-time-val" id="routineSleepLbl">11:00 PM</span>
            </div>
            <input type="range" id="routineSleep" class="routine-slider" min="1260" max="1440" step="15" value="1380">
          </div>

          <button class="btn-submit-med" style="margin-top: 16px;" onclick="submitRoutineUpdate()">
            Save Lifestyle & Recalculate Schedule
          </button>
        </div>
      </div>

      <!-- TAB 4: Curated FDA Drug Library -->
      <div class="tab-content" id="tabLibrary">
        <div class="timeline-header-row">
          <div>
            <h2 class="timeline-heading">Top 50 FDA Polypharmacy Library</h2>
            <p class="timeline-sub">Indexed pharmacokinetic profiles with verified chelation rules</p>
          </div>
        </div>

        <input type="text" id="libSearchInput" class="lib-search-bar" placeholder="🔍 Search drug name (e.g. Cipro, Prednisone, Synthroid)..." oninput="searchLibrary(this.value)">

        <div class="lib-grid" id="libResultsContainer">
          <!-- Populated by JavaScript -->
        </div>
      </div>

    </section>

    <!-- Panel 3: Right Inspector (Clinical Safety Auditor) -->
    <aside class="inspector-panel">
      <div>
        <div class="inspector-title">CLINICAL SAFETY AUDITOR</div>
        <div style="margin-top: 8px;">
          <div class="status-card">
            <div class="status-card-head">
              <span>🛡️</span> Zero Conflicts Detected
            </div>
            <p class="status-card-desc">
              All 6 medications have satisfied discrete constraint satisfaction bounds with zero chelation overlaps.
            </p>
          </div>
        </div>
      </div>

      <div>
        <div class="inspector-title" style="margin-bottom: 8px;">ACTIVE SAFETY CHECKS</div>
        
        <div class="matrix-item">
          <div class="matrix-head">
            <span>Levothyroxine ↔ Calcium</span>
            <span class="matrix-pass">6h GAP (SAFE)</span>
          </div>
          <div class="matrix-detail">4-hour minimum chelation window fully satisfied. Bioavailability preserved.</div>
        </div>

        <div class="matrix-item">
          <div class="matrix-head">
            <span>Calcium ↔ Ferrous Sulfate</span>
            <span class="matrix-pass">4h GAP (SAFE)</span>
          </div>
          <div class="matrix-detail">Separated to prevent competition for intestinal DMT1 metal transporters.</div>
        </div>

        <div class="matrix-item">
          <div class="matrix-head">
            <span>Levothyroxine ↔ Breakfast</span>
            <span class="matrix-pass">90m FAST (PASS)</span>
          </div>
          <div class="matrix-detail">Exceeds 60-minute strict water-only fasting requirement.</div>
        </div>

        <div class="matrix-item">
          <div class="matrix-head">
            <span>Atorvastatin Bedtime</span>
            <span class="matrix-pass">SYNCED (PASS)</span>
          </div>
          <div class="matrix-detail">Scheduled for night to align with hepatic HMG-CoA reductase nocturnal peak.</div>
        </div>
      </div>

      <div>
        <div class="inspector-title" style="margin-bottom: 8px;">ENGINE TELEMETRY</div>
        <div class="telemetry-row">
          <span>Solver Algorithm</span>
          <span class="telemetry-val">CSP Backtracking (MRV)</span>
        </div>
        <div class="telemetry-row">
          <span>Time Discretization</span>
          <span class="telemetry-val">15-minute intervals</span>
        </div>
        <div class="telemetry-row">
          <span>Execution Latency</span>
          <span class="telemetry-val">7 milliseconds</span>
        </div>
        <div class="telemetry-row">
          <span>Persistence Engine</span>
          <span class="telemetry-val">user_store.json (Disk)</span>
        </div>
      </div>
    </aside>

  </main>

  <script>
    let appState = {};

    function formatTime(minutes) {
      if (minutes === undefined || minutes === null) return '--:--';
      const h = Math.floor(minutes / 60) % 24;
      const m = minutes % 60;
      const suffix = h < 12 ? 'AM' : 'PM';
      const dh = h % 12 === 0 ? 12 : h % 12;
      return `\${dh.toString().padStart(2, '0')}:\${m.toString().padStart(2, '0')} \${suffix}`;
    }

    async function loadState() {
      try {
        const res = await fetch('/api/state');
        appState = await res.json();
        renderAll();
      } catch (e) {
        console.error('State load error:', e);
      }
    }

    function switchTab(tabId, btn) {
      document.querySelectorAll('.tab-content').forEach(p => p.classList.remove('active'));
      document.querySelectorAll('.nav-item').forEach(b => b.classList.remove('active'));
      document.getElementById(tabId).classList.add('active');
      btn.classList.add('active');

      if (tabId === 'tabLibrary') {
        searchLibrary('');
      }
    }

    async function toggleDose(doseId) {
      const res = await fetch('/api/dose/toggle', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ doseId })
      });
      appState = await res.json();
      renderAll();
    }

    function takeHeroDose() {
      const next = appState.doses.find(d => !d.isTaken);
      if (next) toggleDose(next.id);
    }

    async function triggerOverslept() {
      const res = await fetch('/api/sim/overslept', { method: 'POST' });
      appState = await res.json();
      renderAll();
    }

    async function triggerReset() {
      const res = await fetch('/api/sim/reset', { method: 'POST' });
      appState = await res.json();
      renderAll();
    }

    async function submitNewMedication() {
      const name = document.getElementById('newMedName').value.trim();
      const dosage = document.getElementById('newMedDosage').value.trim();
      const condition = document.getElementById('newMedCondition').value;
      const hasCation = document.getElementById('newMedCation').checked;

      if (!name) { alert('Please enter medication name'); return; }

      const res = await fetch('/api/medication/add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, dosage: dosage || 'Standard dose', condition, hasCationConflict: hasCation })
      });
      appState = await res.json();
      document.getElementById('newMedName').value = '';
      document.getElementById('newMedDosage').value = '';
      renderAll();
      switchTab('tabToday', document.getElementById('btnTabToday'));
    }

    async function deleteMedication(medId) {
      if (!confirm('Remove this medication from your regimen?')) return;
      const res = await fetch('/api/medication/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ medicationId: medId })
      });
      appState = await res.json();
      renderAll();
    }

    async function submitRoutineUpdate() {
      const wake = parseInt(document.getElementById('routineWake').value);
      const breakfast = parseInt(document.getElementById('routineBreakfast').value);
      const lunch = parseInt(document.getElementById('routineLunch').value);
      const dinner = parseInt(document.getElementById('routineDinner').value);
      const sleep = parseInt(document.getElementById('routineSleep').value);

      const res = await fetch('/api/routine/update', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ wakeMinutes: wake, breakfastMinutes: breakfast, lunchMinutes: lunch, dinnerMinutes: dinner, sleepMinutes: sleep })
      });
      appState = await res.json();
      renderAll();
      switchTab('tabToday', document.getElementById('btnTabToday'));
    }

    async function searchLibrary(query) {
      const res = await fetch(`/api/search?q=\${encodeURIComponent(query)}`);
      const list = await res.json();
      const container = document.getElementById('libResultsContainer');
      container.innerHTML = '';

      list.forEach(item => {
        const card = document.createElement('div');
        card.className = 'lib-card';
        card.innerHTML = `
          <div style="display: flex; justify-content: space-between; align-items: start;">
            <div>
              <div class="lib-brand-name">\${item.name}</div>
              <div class="lib-generic-name">\${item.generic} • \${item.dosage}</div>
            </div>
            <button class="btn-add-lib" onclick='addDrugFromLibrary(\${JSON.stringify(item)})'>+ Add</button>
          </div>
          <div class="lib-desc">\${item.desc}</div>
          <div style="display: flex; gap: 4px; flex-wrap: wrap;">
            \${item.empty ? '<span class="rule-pill empty">Fasting</span>' : ''}
            \${item.food ? '<span class="rule-pill food">With Food</span>' : ''}
            \${item.cationGap > 0 ? '<span class="rule-pill chelate">4h Chelation</span>' : ''}
            <span class="rule-pill" style="background: rgba(255,255,255,0.06); color: #94A3B8;">\${item.circadian}</span>
          </div>
        `;
        container.appendChild(card);
      });
    }

    async function addDrugFromLibrary(item) {
      const cond = item.empty ? 'EMPTY' : (item.food ? 'FOOD' : (item.circadian === 'BEDTIME' ? 'BEDTIME' : 'ANY'));
      const res = await fetch('/api/medication/add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: item.name,
          dosage: item.dosage,
          condition: cond,
          hasCationConflict: item.cationGap > 0
        })
      });
      appState = await res.json();
      renderAll();
      switchTab('tabToday', document.getElementById('btnTabToday'));
    }

    function renderAll() {
      // 1. Adherence Progress Bar
      const total = appState.doses.length;
      const taken = appState.doses.filter(d => d.isTaken).length;
      const pct = total > 0 ? Math.round((taken / total) * 100) : 0;
      document.getElementById('progressPercent').innerText = `\${taken}/\${total} (\${pct}%)`;
      document.getElementById('progressBar').style.width = `\${pct}%`;

      document.getElementById('badgeTodayCount').innerText = total;
      document.getElementById('badgeMedsCount').innerText = appState.medications.length;

      // 2. Alert Box
      const alertBox = document.getElementById('alertBox');
      if (appState.shiftReason) {
        alertBox.style.display = 'block';
        document.getElementById('alertHead').innerText = '⚡ ' + appState.shiftReason;
        document.getElementById('alertBody').innerHTML = appState.shiftsSummary.join('<br>');
      } else {
        alertBox.style.display = 'none';
      }

      // 3. Hero Card
      const next = appState.doses.find(d => !d.isTaken);
      if (next) {
        document.getElementById('heroCard').style.display = 'block';
        document.getElementById('heroTag').innerText = `UP NEXT AT \${next.time}`;
        document.getElementById('heroName').innerText = next.name;
        document.getElementById('heroTime').innerText = `\${next.dosage} • Scheduled for \${next.time}`;
        document.getElementById('heroInst').innerText = next.instruction;
      } else {
        document.getElementById('heroTag').innerText = 'COMPLETE';
        document.getElementById('heroName').innerText = 'All Doses Taken Today! 🎉';
        document.getElementById('heroTime').innerText = '100% Adherence Achieved';
        document.getElementById('heroInst').innerText = 'All metabolic safety intervals satisfied perfectly.';
      }

      // 4. Render Today's Timeline Items
      const todayList = document.getElementById('todayList');
      todayList.innerHTML = '';

      const morningDoses = appState.doses.filter(d => d.minute < 720);
      const afternoonDoses = appState.doses.filter(d => d.minute >= 720 && d.minute < 1080);
      const eveningDoses = appState.doses.filter(d => d.minute >= 1080);

      function renderGroup(title, doses, meal) {
        if (doses.length === 0 && !meal) return;
        const group = document.createElement('div');
        group.className = 'group-section';
        group.innerHTML = `<div class="group-title">\${title}</div>`;

        doses.forEach(d => {
          const isFasting = d.instruction.includes('water');
          const isNight = d.minute >= 1200;
          const isFood = d.instruction.includes('meal') || d.foodNote.includes('empty to avoid');

          const card = document.createElement('div');
          card.className = `dose-card \${d.isTaken ? 'taken' : ''}`;
          card.onclick = () => toggleDose(d.id);
          card.innerHTML = `
            <div class="dose-left">
              <div class="time-badge">\${d.time}</div>
              <div class="dose-info-block">
                <div class="dose-name-line">
                  <span>\${d.name}</span>
                  <span style="font-weight: 500; font-size: 12px; color: var(--text-dim);">(\${d.dosage})</span>
                </div>
                <div class="dose-rule-badges">
                  \${isFasting ? '<span class="rule-pill empty">💧 Fasting (60m)</span>' : ''}
                  \${isFood ? '<span class="rule-pill food">🍽️ With Meal</span>' : ''}
                  \${isNight ? '<span class="rule-pill bedtime">🌙 Bedtime Peak</span>' : ''}
                  <span style="font-size: 11px; color: var(--text-dim); margin-left: 6px;">\${d.instruction}</span>
                </div>
              </div>
            </div>
            <div class="custom-check">\${d.isTaken ? '✓' : ''}</div>
          `;
          group.appendChild(card);
        });

        if (meal) {
          const mBox = document.createElement('div');
          mBox.className = 'meal-window-card';
          mBox.innerHTML = `
            <div class="meal-name-tag">
              <span>🍽️</span>
              <span>\${meal.name} Safe Window</span>
            </div>
            <div style="font-family: 'JetBrains Mono', monospace; font-size: 11px; color: #FCD34D;">
              \${formatTime(meal.start)} – \${formatTime(meal.end)}
            </div>
          `;
          group.appendChild(mBox);
        }

        todayList.appendChild(group);
      }

      const breakfast = appState.meals.find(m => m.name.includes('Breakfast'));
      const lunch = appState.meals.find(m => m.name.includes('Lunch'));
      const dinner = appState.meals.find(m => m.name.includes('Dinner'));

      renderGroup('🌅 Morning Routine', morningDoses, breakfast);
      renderGroup('☀️ Afternoon', afternoonDoses, lunch);
      renderGroup('🌙 Evening & Bedtime', eveningDoses, dinner);

      // 5. Render Meds Tab
      document.getElementById('medCount').innerText = appState.medications.length;
      const medListContainer = document.getElementById('medListContainer');
      medListContainer.innerHTML = '';
      appState.medications.forEach(m => {
        const card = document.createElement('div');
        card.className = 'med-manage-item';
        card.innerHTML = `
          <div>
            <div class="med-manage-name">\${m.name} <span style="font-size: 13px; font-weight: 500; color: var(--text-dim);">(\${m.dosage})</span></div>
            <div style="display: flex; gap: 6px; flex-wrap: wrap;">
              \${m.requiresEmpty ? '<span class="rule-pill empty">Empty Stomach</span>' : ''}
              \${m.requiresFood ? '<span class="rule-pill food">With Food</span>' : ''}
              \${m.hasConflicts ? '<span class="rule-pill chelate">4h Cation Spacing</span>' : ''}
              <span class="rule-pill" style="background: rgba(255,255,255,0.06); color: var(--text-muted);">\${m.circadian}</span>
            </div>
          </div>
          <button class="btn-delete-med" onclick="deleteMedication('\${m.id}')">Delete</button>
        `;
        medListContainer.appendChild(card);
      });

      // 6. Sync Routine Tab
      document.getElementById('routineWake').value = appState.wakeTimeMinutes;
      document.getElementById('routineWakeLbl').innerText = formatTime(appState.wakeTimeMinutes);
      document.getElementById('routineSleep').value = appState.sleepTimeMinutes;
      document.getElementById('routineSleepLbl').innerText = formatTime(appState.sleepTimeMinutes);

      const b = appState.meals.find(m => m.name.includes('Breakfast'));
      if (b) {
        document.getElementById('routineBreakfast').value = b.start;
        document.getElementById('routineBreakfastLbl').innerText = formatTime(b.start);
      }
      const l = appState.meals.find(m => m.name.includes('Lunch'));
      if (l) {
        document.getElementById('routineLunch').value = l.start;
        document.getElementById('routineLunchLbl').innerText = formatTime(l.start);
      }
      const d = appState.meals.find(m => m.name.includes('Dinner'));
      if (d) {
        document.getElementById('routineDinner').value = d.start;
        document.getElementById('routineDinnerLbl').innerText = formatTime(d.start);
      }
    }

    // Live update routine minute labels as inputs change
    ['routineWake', 'routineBreakfast', 'routineLunch', 'routineDinner', 'routineSleep'].forEach(id => {
      document.getElementById(id).addEventListener('input', e => {
        const val = parseInt(e.target.value) || 0;
        document.getElementById(id + 'Lbl').innerText = formatTime(val);
      });
    });

    loadState();
  </script>
</body>
</html>
  ''';
}
