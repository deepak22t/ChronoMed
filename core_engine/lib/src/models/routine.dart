import 'package:meta/meta.dart';
import 'meal.dart';

enum BeverageType {
  coffee,
  tea,
  dairy,
  alcohol;

  String get displayName => switch (this) {
        BeverageType.coffee => 'Coffee',
        BeverageType.tea => 'Tea',
        BeverageType.dairy => 'Milk / Dairy',
        BeverageType.alcohol => 'Alcohol',
      };
}

@immutable
class BeverageHabit {
  final BeverageType type;
  final int timeMinutes;

  const BeverageHabit({
    required this.type,
    required this.timeMinutes,
  }) : assert(timeMinutes >= 0 && timeMinutes < 1440);
}

/// A patient's daily routine configuration.
@immutable
class Routine {
  final String id;
  final String userId;

  /// Wake up time in minutes from midnight (e.g. 420 = 07:00 AM).
  final int wakeTimeMinutes;

  /// Sleep time in minutes from midnight (e.g. 1380 = 11:00 PM).
  final int sleepTimeMinutes;

  final List<MealAnchor> meals;
  final List<BeverageHabit> beveragePreferences;

  const Routine({
    required this.id,
    required this.userId,
    required this.wakeTimeMinutes,
    required this.sleepTimeMinutes,
    required this.meals,
    this.beveragePreferences = const [],
  })  : assert(wakeTimeMinutes >= 0 && wakeTimeMinutes < 1440),
        assert(sleepTimeMinutes >= 0 && sleepTimeMinutes < 1440),
        assert(wakeTimeMinutes < sleepTimeMinutes,
            'wakeTimeMinutes must precede sleepTimeMinutes in a single diurnal cycle');

  /// Total waking duration in minutes.
  int get wakingDurationMinutes => sleepTimeMinutes - wakeTimeMinutes;

  @override
  String toString() =>
      'Routine(Wake: $wakeTimeMinutes, Sleep: $sleepTimeMinutes, Meals: ${meals.length})';
}
