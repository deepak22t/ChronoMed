import 'constants/clinical_buffers.dart';
import 'models/meal.dart';
import 'models/pharmacokinetic_rule.dart';

/// Pure mathematical interval algebra utilities operating in discrete
/// minute-of-day space [0, 1439].
abstract final class IntervalMath {
  /// Converts minutes from midnight to a 12-hour AM/PM string.
  static String formatMinuteOfDay(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    final suffix = h < 12 ? 'AM' : 'PM';
    final displayH = h % 12 == 0 ? 12 : h % 12;
    return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $suffix';
  }

  /// Evaluates whether a candidate time [minute] respects the fasting requirements
  /// across all scheduled [meals].
  ///
  /// Rule: Dose must be >= [preBuffer] before meal start OR >= [postBuffer] after meal end.
  /// Violation occurs if: (meal.start - preBuffer) < minute < (meal.end + postBuffer)
  static bool isFastingCompliant({
    required int minute,
    required List<MealAnchor> meals,
    int preBuffer = ClinicalBuffers.emptyStomachPreMealBufferMinutes,
    int postBuffer = ClinicalBuffers.emptyStomachPostMealBufferMinutes,
  }) {
    for (final meal in meals) {
      final invalidStart = meal.startTimeMinutes - preBuffer;
      final invalidEnd = meal.endTimeMinutes + postBuffer;
      if (minute > invalidStart && minute < invalidEnd) {
        return false;
      }
    }
    return true;
  }

  /// Evaluates whether a candidate time [minute] falls within the safe co-administration
  /// food window of any scheduled meal.
  ///
  /// Rule: Dose must be within [0, foodWindow] minutes of the meal start.
  static bool isPrandialCompliant({
    required int minute,
    required List<MealAnchor> meals,
    int foodWindow = ClinicalBuffers.prandialFoodBufferMinutes,
  }) {
    for (final meal in meals) {
      final delta = minute - meal.startTimeMinutes;
      if (delta >= 0 && delta <= foodWindow) {
        return true;
      }
    }
    return false;
  }

  /// Evaluates whether candidate time [minute] respects the target circadian window.
  static bool isCircadianCompliant({
    required int minute,
    required CircadianWindow window,
    ({int startMinutes, int endMinutes})? customWindow,
  }) {
    if (customWindow != null) {
      return minute >= customWindow.startMinutes &&
          minute <= customWindow.endMinutes;
    }

    return switch (window) {
      CircadianWindow.anyTime => true,
      CircadianWindow.morning =>
        minute >= ClinicalBuffers.morningWindowStart &&
            minute <= ClinicalBuffers.morningWindowEnd,
      CircadianWindow.afternoon =>
        minute > ClinicalBuffers.morningWindowEnd &&
            minute < ClinicalBuffers.eveningWindowStart,
      CircadianWindow.evening =>
        minute >= ClinicalBuffers.eveningWindowStart &&
            minute <= ClinicalBuffers.eveningWindowEnd,
      CircadianWindow.bedtime =>
        minute >= ClinicalBuffers.bedtimeWindowStart &&
            minute <= ClinicalBuffers.bedtimeWindowEnd,
    };
  }

  /// Checks bilateral separation between two assigned times.
  static bool satisfiesSeparation({
    required int timeA,
    required int timeB,
    required int requiredGapMinutes,
  }) {
    return (timeA - timeB).abs() >= requiredGapMinutes;
  }
}
