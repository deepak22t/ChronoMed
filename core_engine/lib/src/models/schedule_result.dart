import 'package:meta/meta.dart';

enum DoseStatus {
  scheduled,
  due,
  taken,
  snoozed,
  missed,
  escalated;

  String get displayName => switch (this) {
        DoseStatus.scheduled => 'Scheduled',
        DoseStatus.due => 'Due Now',
        DoseStatus.taken => 'Taken',
        DoseStatus.snoozed => 'Snoozed',
        DoseStatus.missed => 'Missed',
        DoseStatus.escalated => 'Escalated to Caregiver',
      };
}

/// An individual scheduled dose event within the daily timeline.
@immutable
class ScheduledDose {
  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;

  /// Minute of the day (0 to 1439).
  final int scheduledMinute;

  /// Actual time the dose was taken, if logged.
  final int? actualTakenMinute;

  final DoseStatus status;
  final String clinicalInstruction;
  final String safeFoodWindowNote;

  const ScheduledDose({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledMinute,
    this.actualTakenMinute,
    this.status = DoseStatus.scheduled,
    required this.clinicalInstruction,
    required this.safeFoodWindowNote,
  }) : assert(scheduledMinute >= 0 && scheduledMinute < 1440);

  /// Helper to get formatted 12-hour string (e.g. "07:30 AM").
  String get formattedTime {
    final h = (scheduledMinute ~/ 60) % 24;
    final m = scheduledMinute % 60;
    final suffix = h < 12 ? 'AM' : 'PM';
    final displayH = h % 12 == 0 ? 12 : h % 12;
    return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $suffix';
  }

  ScheduledDose copyWith({
    int? scheduledMinute,
    int? actualTakenMinute,
    DoseStatus? status,
  }) {
    return ScheduledDose(
      id: id,
      medicationId: medicationId,
      medicationName: medicationName,
      dosage: dosage,
      scheduledMinute: scheduledMinute ?? this.scheduledMinute,
      actualTakenMinute: actualTakenMinute ?? this.actualTakenMinute,
      status: status ?? this.status,
      clinicalInstruction: clinicalInstruction,
      safeFoodWindowNote: safeFoodWindowNote,
    );
  }

  @override
  String toString() => '[$formattedTime] $medicationName ($dosage)';
}

/// Sealed hierarchy representing the outcome of daily schedule generation.
sealed class DailyScheduleResult {
  const DailyScheduleResult();
}

/// Successfully solved collision-free daily schedule.
final class OptimalSchedule extends DailyScheduleResult {
  final String date;
  final String userId;
  final List<ScheduledDose> doses;
  final int solveDurationMs;

  const OptimalSchedule({
    required this.date,
    required this.userId,
    required this.doses,
    required this.solveDurationMs,
  });

  @override
  String toString() =>
      'OptimalSchedule(${doses.length} doses, solved in ${solveDurationMs}ms)';
}

/// Unresolvable clinical conflict detected (Fail-Closed Medical Safety).
final class InfeasibleConflict extends DailyScheduleResult {
  final String errorCode;
  final List<String> conflictingMedications;
  final String clinicalExplanation;
  final String actionableAdvice;

  const InfeasibleConflict({
    this.errorCode = 'CHRONO_1001',
    required this.conflictingMedications,
    required this.clinicalExplanation,
    required this.actionableAdvice,
  });

  @override
  String toString() =>
      'InfeasibleConflict($errorCode: ${conflictingMedications.join(' vs ')})';
}

/// Dynamically shifted schedule following a late wake-up or delayed dose.
final class RecalibratedSchedule extends DailyScheduleResult {
  final String date;
  final String userId;
  final List<ScheduledDose> doses;
  final String shiftReason;
  final List<String> shiftsSummary;

  const RecalibratedSchedule({
    required this.date,
    required this.userId,
    required this.doses,
    required this.shiftReason,
    required this.shiftsSummary,
  });

  @override
  String toString() =>
      'RecalibratedSchedule(${doses.length} doses shifted due to: $shiftReason)';
}
