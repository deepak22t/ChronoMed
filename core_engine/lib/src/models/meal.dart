import 'package:meta/meta.dart';

/// Clinical meal classification.
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snack',
      };
}

/// A specific scheduled meal event within the 24-hour day.
@immutable
class MealAnchor {
  final String id;
  final MealType type;

  /// Minute of the day from midnight (0 to 1439). Example: 510 = 08:30 AM.
  final int startTimeMinutes;

  /// Duration of the meal in minutes (default: 30).
  final int durationMinutes;

  const MealAnchor({
    required this.id,
    required this.type,
    required this.startTimeMinutes,
    this.durationMinutes = 30,
  })  : assert(startTimeMinutes >= 0 && startTimeMinutes < 1440,
            'startTimeMinutes must be between 0 and 1439'),
        assert(durationMinutes > 0, 'durationMinutes must be positive');

  /// The minute the meal ends.
  int get endTimeMinutes => startTimeMinutes + durationMinutes;

  @override
  String toString() =>
      'MealAnchor($displayName at $startTimeMinutes-${endTimeMinutes}m)';

  String get displayName => type.displayName;
}
