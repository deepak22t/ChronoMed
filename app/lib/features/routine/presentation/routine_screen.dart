import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';

/// Routine configuration screen.
/// Lets the user adjust wake time, sleep time, and meal anchor times
/// using interactive time pickers. Changes immediately recompute the schedule.
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late int _wakeMinutes;
  late int _sleepMinutes;
  late int _breakfastMinutes;
  late int _lunchMinutes;
  late int _dinnerMinutes;
  bool _isDirty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromState();
  }

  void _syncFromState() {
    final routine = AppStateProvider.of(context).routine;
    setState(() {
      _wakeMinutes = routine.wakeTimeMinutes;
      _sleepMinutes = routine.sleepTimeMinutes;

      final meals = routine.meals;
      _breakfastMinutes = meals
          .firstWhere((m) => m.type == MealType.breakfast,
              orElse: () => const MealAnchor(
                  id: '_', type: MealType.breakfast, startTimeMinutes: 510))
          .startTimeMinutes;
      _lunchMinutes = meals
          .firstWhere((m) => m.type == MealType.lunch,
              orElse: () => const MealAnchor(
                  id: '_', type: MealType.lunch, startTimeMinutes: 780))
          .startTimeMinutes;
      _dinnerMinutes = meals
          .firstWhere((m) => m.type == MealType.dinner,
              orElse: () => const MealAnchor(
                  id: '_', type: MealType.dinner, startTimeMinutes: 1170))
          .startTimeMinutes;
      _isDirty = false;
    });
  }

  void _saveRoutine() {
    if (_wakeMinutes >= _sleepMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wake time must be before sleep time.'),
          backgroundColor: ChronoTheme.rose,
        ),
      );
      return;
    }

    final newRoutine = Routine(
      id: 'routine_custom',
      userId: 'user_1',
      wakeTimeMinutes: _wakeMinutes,
      sleepTimeMinutes: _sleepMinutes,
      meals: [
        MealAnchor(
            id: 'm1',
            type: MealType.breakfast,
            startTimeMinutes: _breakfastMinutes),
        MealAnchor(
            id: 'm2', type: MealType.lunch, startTimeMinutes: _lunchMinutes),
        MealAnchor(
            id: 'm3',
            type: MealType.dinner,
            startTimeMinutes: _dinnerMinutes,
            durationMinutes: 45),
      ],
    );

    AppStateProvider.of(context).updateRoutine(newRoutine);
    setState(() => _isDirty = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Routine updated — schedule recomputed.'),
        backgroundColor: ChronoTheme.emerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: Column(
        children: [
          _RoutineHeader(isDirty: _isDirty, onSave: _saveRoutine),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                // Waking Window
                _SectionTitle('Waking Window'),
                const SizedBox(height: 12),
                _TimePickerRow(
                  label: 'Wake Up',
                  icon: Icons.wb_sunny_outlined,
                  iconColor: ChronoTheme.amber,
                  minutes: _wakeMinutes,
                  onChanged: (v) => setState(() {
                    _wakeMinutes = v;
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 10),
                _TimePickerRow(
                  label: 'Sleep',
                  icon: Icons.bedtime_outlined,
                  iconColor: ChronoTheme.violet,
                  minutes: _sleepMinutes,
                  onChanged: (v) => setState(() {
                    _sleepMinutes = v;
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 4),
                _WakingDurationBar(
                    wakeMinutes: _wakeMinutes, sleepMinutes: _sleepMinutes),
                const SizedBox(height: 24),

                // Meal Anchors
                _SectionTitle('Meal Anchors'),
                const SizedBox(height: 12),
                _TimePickerRow(
                  label: 'Breakfast',
                  icon: Icons.free_breakfast_outlined,
                  iconColor: ChronoTheme.emerald,
                  minutes: _breakfastMinutes,
                  onChanged: (v) => setState(() {
                    _breakfastMinutes = v;
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 10),
                _TimePickerRow(
                  label: 'Lunch',
                  icon: Icons.lunch_dining_outlined,
                  iconColor: ChronoTheme.cyan,
                  minutes: _lunchMinutes,
                  onChanged: (v) => setState(() {
                    _lunchMinutes = v;
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 10),
                _TimePickerRow(
                  label: 'Dinner',
                  icon: Icons.dinner_dining_outlined,
                  iconColor: ChronoTheme.violet,
                  minutes: _dinnerMinutes,
                  onChanged: (v) => setState(() {
                    _dinnerMinutes = v;
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 28),

                // Clinical Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ChronoTheme.cyan.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: ChronoTheme.cyan.withOpacity(0.25)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: ChronoTheme.cyan, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Changing your routine will immediately recompute all medication '
                          'timings to maintain safe separation windows. Fasting and chelation '
                          'constraints are automatically preserved.',
                          style: TextStyle(
                              color: ChronoTheme.textSecondary,
                              fontSize: 12,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _RoutineHeader extends StatelessWidget {
  final bool isDirty;
  final VoidCallback onSave;

  const _RoutineHeader({required this.isDirty, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: ChronoTheme.surface,
        border: Border(bottom: BorderSide(color: ChronoTheme.border)),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Routine',
                style: TextStyle(
                  color: ChronoTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Configure wake, meal, and sleep anchor times',
                style: TextStyle(color: ChronoTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          if (isDirty)
            ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Save & Recompute'),
            ),
        ],
      ),
    );
  }
}

// ── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: ChronoTheme.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Time Picker Row ──────────────────────────────────────────────────────────

class _TimePickerRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final int minutes;
  final ValueChanged<int> onChanged;

  const _TimePickerRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.minutes,
    required this.onChanged,
  });

  Future<void> _pickTime(BuildContext context) async {
    final tod = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    final picked = await showTimePicker(
      context: context,
      initialTime: tod,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: ChronoTheme.cyan,
            surface: ChronoTheme.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onChanged(picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = IntervalMath.formatMinuteOfDay(minutes);

    return GestureDetector(
      onTap: () => _pickTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ChronoTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    color: ChronoTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ChronoTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ChronoTheme.border),
              ),
              child: Row(
                children: [
                  Text(
                    formatted,
                    style: const TextStyle(
                      color: ChronoTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: ChronoTheme.monoFont,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: ChronoTheme.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Waking Duration Bar ──────────────────────────────────────────────────────

class _WakingDurationBar extends StatelessWidget {
  final int wakeMinutes;
  final int sleepMinutes;

  const _WakingDurationBar(
      {required this.wakeMinutes, required this.sleepMinutes});

  @override
  Widget build(BuildContext context) {
    final duration =
        (sleepMinutes - wakeMinutes).clamp(0, 1440);
    final hours = duration ~/ 60;
    final mins = duration % 60;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              size: 14, color: ChronoTheme.textMuted),
          const SizedBox(width: 6),
          Text(
            'Waking window: ${hours}h ${mins}m',
            style: const TextStyle(
                color: ChronoTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
