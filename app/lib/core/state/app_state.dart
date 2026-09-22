import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:core_engine/core_engine.dart';

/// Central application state for ChronoMed.
///
/// Holds the user's routine, medication list, and the computed daily schedule.
/// Exposes mutation methods that always recompute the schedule after changes.
///
/// Uses [ChangeNotifier] — no external packages required.
class AppState extends ChangeNotifier {
  // ── State Fields ────────────────────────────────────────────────────────
  Routine _routine;
  List<Medication> _medications;
  DailyScheduleResult _scheduleResult;
  int _currentMinuteOfDay;
  bool _isOversleptMode = false;
  Timer? _clockTimer;

  // ── Constructor ─────────────────────────────────────────────────────────
  AppState({
    required Routine initialRoutine,
    required List<Medication> initialMedications,
  })  : _routine = initialRoutine,
        _medications = List.from(initialMedications),
        _currentMinuteOfDay = _nowInMinutes(),
        _scheduleResult = const OptimalSchedule(
          date: 'TODAY',
          userId: 'user_1',
          doses: [],
          solveDurationMs: 0,
        ) {
    _solve();
    _startClock();
  }

  // ── Public Getters ───────────────────────────────────────────────────────
  Routine get routine => _routine;
  List<Medication> get medications => List.unmodifiable(_medications);
  DailyScheduleResult get scheduleResult => _scheduleResult;
  int get currentMinuteOfDay => _currentMinuteOfDay;
  bool get isOversleptMode => _isOversleptMode;
  bool get isRecalibrated => _scheduleResult is RecalibratedSchedule;

  RecalibratedSchedule? get recalibratedSchedule =>
      _scheduleResult is RecalibratedSchedule ? _scheduleResult as RecalibratedSchedule : null;

  /// All doses from the current schedule result (empty if infeasible).
  List<ScheduledDose> get doses => switch (_scheduleResult) {
        OptimalSchedule(:final doses) => doses,
        RecalibratedSchedule(:final doses) => doses,
        _ => const [],
      };

  /// Next upcoming dose that has not been taken yet.
  ScheduledDose? get nextDose {
    final pending = doses
        .where((d) =>
            d.status != DoseStatus.taken &&
            d.scheduledMinute >= _currentMinuteOfDay)
        .toList();
    return pending.isNotEmpty ? pending.first : null;
  }

  /// Adherence ratio: taken / total scheduled for today.
  double get adherenceRatio {
    if (doses.isEmpty) return 1.0;
    final taken = doses.where((d) => d.status == DoseStatus.taken).length;
    return taken / doses.length;
  }

  /// Total doses scheduled today.
  int get totalDoses => doses.length;

  /// Doses taken so far today.
  int get takenCount => doses.where((d) => d.status == DoseStatus.taken).length;

  /// True if the schedule is in a conflict/infeasible state.
  bool get hasConflict => _scheduleResult is InfeasibleConflict;

  /// Conflict details if schedule is infeasible.
  InfeasibleConflict? get conflict =>
      _scheduleResult is InfeasibleConflict ? _scheduleResult as InfeasibleConflict : null;

  /// Latest solve duration in ms.
  int get lastSolveDurationMs => switch (_scheduleResult) {
        OptimalSchedule(:final solveDurationMs) => solveDurationMs,
        _ => 0,
      };

  // ── Mutation Methods ─────────────────────────────────────────────────────

  /// Mark a dose as taken at the current simulated time.
  void markDoseTaken(String medicationId) {
    markDoseTakenAt(medicationId, _currentMinuteOfDay);
  }

  /// Mark a dose as taken at an explicit minute of the day and dynamically recalibrate.
  void markDoseTakenAt(String medicationId, int minuteOfDay) {
    if (_scheduleResult is! OptimalSchedule && _scheduleResult is! RecalibratedSchedule) return;

    final currentDoses = doses;
    final recalibrated = DynamicRecalibrator.recalibrateForLateDose(
      existingDoses: currentDoses,
      delayedMedicationId: medicationId,
      actualTakenMinute: minuteOfDay,
      medications: _medications,
      currentRoutine: _routine,
    );

    _scheduleResult = recalibrated;
    notifyListeners();
  }

  /// Reset any dynamic recalibration back to the pristine optimal baseline.
  void resetRecalibration() {
    _isOversleptMode = false;
    _solve();
  }

  /// Add a new medication and recompute the schedule.
  void addMedication(Medication medication) {
    if (_medications.any((m) => m.id == medication.id)) return;
    _medications = [..._medications, medication];
    _isOversleptMode = false;
    _solve();
  }

  /// Remove a medication by ID and recompute the schedule.
  void removeMedication(String medicationId) {
    _medications = _medications.where((m) => m.id != medicationId).toList();
    _isOversleptMode = false;
    _solve();
  }

  /// Update the daily routine and recompute the schedule.
  void updateRoutine(Routine newRoutine) {
    _routine = newRoutine;
    _isOversleptMode = false;
    _solve();
  }

  /// Simulate waking up late (+2h 15m from configured wake time).
  void simulateOverslept() {
    final lateWake = (_routine.wakeTimeMinutes + 135).clamp(0, 1439);
    _currentMinuteOfDay = lateWake + 5;
    _isOversleptMode = true;

    _scheduleResult = DynamicRecalibrator.recalibrateForDelayedWakeUp(
      baselineRoutine: _routine,
      actualWakeTimeMinutes: lateWake,
      medications: _medications,
      targetDate: 'TODAY',
    );
    notifyListeners();
  }

  /// Reset overslept mode back to baseline routine.
  void resetOverslept() {
    _isOversleptMode = false;
    _currentMinuteOfDay = _nowInMinutes();
    _solve();
  }

  /// Reset everything to the initial default state.
  void reset({
    required Routine defaultRoutine,
    required List<Medication> defaultMedications,
  }) {
    _routine = defaultRoutine;
    _medications = List.from(defaultMedications);
    _isOversleptMode = false;
    _currentMinuteOfDay = _nowInMinutes();
    _solve();
  }

  /// Advance clock by [minutes] — for testing/demo purposes.
  void advanceClock(int minutes) {
    _currentMinuteOfDay = (_currentMinuteOfDay + minutes).clamp(0, 1439);
    notifyListeners();
  }

  // ── Private Helpers ──────────────────────────────────────────────────────

  void _solve() {
    _scheduleResult = ChronoMedSolver(
      routine: _routine,
      medications: _medications,
      targetDate: 'TODAY',
    ).solve();
    notifyListeners();
  }

  /// Starts a real-time clock that advances [_currentMinuteOfDay] every minute.
  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_isOversleptMode) {
        final realNow = _nowInMinutes();
        if (realNow != _currentMinuteOfDay) {
          _currentMinuteOfDay = realNow;
          notifyListeners();
        }
      }
    });
  }

  static int _nowInMinutes() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}
