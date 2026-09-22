import 'dart:convert';
import 'package:core_engine/core_engine.dart';

/// Offline authoritative drug registry providing <1ms pharmacokinetic lookups.
class DrugRegistry {
  final Map<String, Medication> _byGenericName = {};
  final Map<String, Medication> _byBrandName = {};
  final Map<String, Medication> _byRxCui = {};

  DrugRegistry();

  /// Loads and parses the raw JSON string into indexed domain entities.
  void loadFromJsonString(String jsonContent) {
    final list = jsonDecode(jsonContent) as List<dynamic>;

    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final rxcui = map['rxcui'] as String?;
      final name = map['name'] as String;
      final brands = (map['brandNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [];

      final requiresEmpty = map['requiresEmptyStomach'] as bool? ?? false;
      final requiresFood = map['requiresFood'] as bool? ?? false;
      final preMeal = map['emptyStomachPreMealMinutes'] as int? ?? 60;
      final postMeal = map['emptyStomachPostMealMinutes'] as int? ?? 120;

      final circStr = map['circadianPreference'] as String? ?? 'ANY';
      final circadian = switch (circStr) {
        'MORNING' => CircadianWindow.morning,
        'AFTERNOON' => CircadianWindow.afternoon,
        'EVENING' => CircadianWindow.evening,
        'BEDTIME' => CircadianWindow.bedtime,
        _ => CircadianWindow.anyTime,
      };

      final conflictsList = (map['chelationConflicts'] as List<dynamic>?) ?? [];
      final separationConstraints = <DrugSeparationConstraint>[];

      for (final c in conflictsList) {
        final cmap = c as Map<String, dynamic>;
        separationConstraints.add(DrugSeparationConstraint(
          targetIdentifier: cmap['target'] as String,
          minimumSeparationMinutes: cmap['gapMinutes'] as int? ?? 240,
          clinicalRationale: cmap['rationale'] as String? ?? 'Clinical conflict',
        ));
      }

      final med = Medication(
        id: rxcui ?? name.toLowerCase().replaceAll(' ', '_'),
        name: name,
        rxcui: rxcui,
        dosage: 'Standard Dosage',
        rules: PharmacokineticRule(
          requiresEmptyStomach: requiresEmpty,
          emptyStomachPreMealMinutes: preMeal,
          emptyStomachPostMealMinutes: postMeal,
          requiresFood: requiresFood,
          circadianPreference: circadian,
          separationConstraints: separationConstraints,
        ),
      );

      _byGenericName[name.toLowerCase()] = med;
      if (rxcui != null) {
        _byRxCui[rxcui] = med;
      }
      for (final brand in brands) {
        _byBrandName[brand.toLowerCase()] = med;
      }
    }
  }

  /// Looks up a medication by generic name, brand name, or RxCUI.
  Medication? findByQuery(String query) {
    final q = query.trim().toLowerCase();
    if (_byRxCui.containsKey(q)) return _byRxCui[q];
    if (_byGenericName.containsKey(q)) return _byGenericName[q];
    if (_byBrandName.containsKey(q)) return _byBrandName[q];

    // Substring search
    for (final entry in _byGenericName.entries) {
      if (entry.key.contains(q) || q.contains(entry.key)) {
        return entry.value;
      }
    }
    for (final entry in _byBrandName.entries) {
      if (entry.key.contains(q) || q.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Returns all indexed medications as a list.
  List<Medication> get allMedications => _byGenericName.values.toList();

  /// Searches and returns up to [limit] matching medications.
  List<Medication> search(String query, {int limit = 6}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _byGenericName.values.take(limit).toList();

    final results = <Medication>{};
    for (final entry in _byGenericName.entries) {
      if (entry.key.contains(q)) {
        results.add(entry.value);
        if (results.length >= limit) return results.toList();
      }
    }
    for (final entry in _byBrandName.entries) {
      if (entry.key.contains(q)) {
        results.add(entry.value);
        if (results.length >= limit) return results.toList();
      }
    }
    return results.toList();
  }

  int get totalIndexed => _byGenericName.length;
}
