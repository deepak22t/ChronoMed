import 'dart:io';
import 'package:clinical_data/clinical_data.dart';
import 'package:core_engine/core_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Clinical Data: DrugRegistry Tests', () {
    late DrugRegistry registry;

    setUp(() {
      registry = DrugRegistry();
      final jsonFile = File('data/top_50_drugs.json');
      final content = jsonFile.readAsStringSync();
      registry.loadFromJsonString(content);
    });

    test('Loads and indexes all entries correctly', () {
      expect(registry.totalIndexed, greaterThanOrEqualTo(10));
    });

    test('Finds Levothyroxine by brand name Synthroid', () {
      final med = registry.findByQuery('Synthroid');
      expect(med, isNotNull);
      expect(med!.name, contains('Levothyroxine'));
      expect(med.rules.requiresEmptyStomach, isTrue);
      expect(med.rules.circadianPreference, equals(CircadianWindow.morning));
      expect(med.rules.separationConstraints.length, greaterThanOrEqualTo(2));
    });

    test('Finds Metformin by generic name and verifies food requirement', () {
      final med = registry.findByQuery('Metformin');
      expect(med, isNotNull);
      expect(med!.rules.requiresFood, isTrue);
      expect(med.rules.requiresEmptyStomach, isFalse);
    });

    test('Finds Calcium Carbonate and verifies chelation conflict with Levothyroxine', () {
      final med = registry.findByQuery('Caltrate');
      expect(med, isNotNull);
      expect(med!.name, contains('Calcium Carbonate'));
      expect(med.hasConflictWith('Levothyroxine'), isTrue);
      expect(med.getSeparationWith('Levothyroxine'), equals(240));
    });
  });
}
