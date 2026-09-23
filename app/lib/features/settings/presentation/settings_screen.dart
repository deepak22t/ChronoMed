import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';
import '../../../main.dart' show defaultRoutine, defaultMedications;
import '../../dashboard/presentation/missed_dose_protocol_sheet.dart';
import 'physician_summary_sheet.dart';

/// Settings screen — routine anchors, clinical care, and danger zone.
///
/// Absorbs the Routine screen (wake/sleep/meal times) as the first section.
/// Removes: engine telemetry, system specs, zero-hallucination mandate card,
/// AOT ENGINE ONLINE badge, simulation lab as a top-level section.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Routine state (mirrors RoutineScreen logic, preserved exactly)
  late int _wakeMinutes;
  late int _sleepMinutes;
  late int _breakfastMinutes;
  late int _lunchMinutes;
  late int _dinnerMinutes;
  bool _isDirty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDirty) _syncFromState();
  }

  void _syncFromState() {
    final routine = AppStateProvider.of(context).routine;
    final meals = routine.meals;
    setState(() {
      _wakeMinutes     = routine.wakeTimeMinutes;
      _sleepMinutes    = routine.sleepTimeMinutes;
      _breakfastMinutes = meals.firstWhere(
        (m) => m.type == MealType.breakfast,
        orElse: () => const MealAnchor(id: '_', type: MealType.breakfast, startTimeMinutes: 510),
      ).startTimeMinutes;
      _lunchMinutes = meals.firstWhere(
        (m) => m.type == MealType.lunch,
        orElse: () => const MealAnchor(id: '_', type: MealType.lunch, startTimeMinutes: 780),
      ).startTimeMinutes;
      _dinnerMinutes = meals.firstWhere(
        (m) => m.type == MealType.dinner,
        orElse: () => const MealAnchor(id: '_', type: MealType.dinner, startTimeMinutes: 1170),
      ).startTimeMinutes;
      _isDirty = false;
    });
  }

  void _saveRoutine(AppState state) {
    if (_wakeMinutes >= _sleepMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Wake time must precede sleep time.'),
          backgroundColor: ChronoTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: ChronoTheme.rose),
          ),
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
        MealAnchor(id: 'm1', type: MealType.breakfast, startTimeMinutes: _breakfastMinutes),
        MealAnchor(id: 'm2', type: MealType.lunch,     startTimeMinutes: _lunchMinutes),
        MealAnchor(id: 'm3', type: MealType.dinner,    startTimeMinutes: _dinnerMinutes, durationMinutes: 45),
      ],
    );
    state.updateRoutine(newRoutine);
    setState(() => _isDirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Routine saved — schedule re-optimized.'),
        backgroundColor: ChronoTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: ChronoTheme.border),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final wakingMins   = (_sleepMinutes - _wakeMinutes).clamp(0, 1440);
    final sleepMins    = (1440 - _sleepMinutes + _wakeMinutes) % 1440;
    final fastMins     = (1440 - _dinnerMinutes + _breakfastMinutes) % 1440;

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(
              isDirty: _isDirty,
              onSave: () => _saveRoutine(state),
              onDiscard: _syncFromState,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 48),
                children: [

                  // ── Section 1: Daily Routine ─────────────────────────────
                  const _SectionLabel('Daily Routine'),
                  const SizedBox(height: 10),

                  // 24h visual bar — kept, genuinely useful
                  _CircadianBar(
                    wakeMinutes:      _wakeMinutes,
                    sleepMinutes:     _sleepMinutes,
                    breakfastMinutes: _breakfastMinutes,
                    lunchMinutes:     _lunchMinutes,
                    dinnerMinutes:    _dinnerMinutes,
                    wakingMinutes:    wakingMins,
                    sleepMinutes2:    sleepMins,
                    fastingMinutes:   fastMins,
                  ),
                  const SizedBox(height: 12),

                  // Sleep
                  _TimeTile(
                    label: 'Wake up',
                    minutes: _wakeMinutes,
                    onChanged: (v) => setState(() { _wakeMinutes = v; _isDirty = true; }),
                  ),
                  const Divider(color: ChronoTheme.border, height: 1),
                  _TimeTile(
                    label: 'Bedtime',
                    minutes: _sleepMinutes,
                    onChanged: (v) => setState(() { _sleepMinutes = v; _isDirty = true; }),
                  ),

                  const SizedBox(height: 16),

                  // Meals
                  _TimeTile(
                    label: 'Breakfast',
                    minutes: _breakfastMinutes,
                    onChanged: (v) => setState(() { _breakfastMinutes = v; _isDirty = true; }),
                  ),
                  const Divider(color: ChronoTheme.border, height: 1),
                  _TimeTile(
                    label: 'Lunch',
                    minutes: _lunchMinutes,
                    onChanged: (v) => setState(() { _lunchMinutes = v; _isDirty = true; }),
                  ),
                  const Divider(color: ChronoTheme.border, height: 1),
                  _TimeTile(
                    label: 'Dinner',
                    minutes: _dinnerMinutes,
                    onChanged: (v) => setState(() { _dinnerMinutes = v; _isDirty = true; }),
                  ),

                  const SizedBox(height: 28),

                  // ── Section 2: Clinical Care ──────────────────────────────
                  const _SectionLabel('Clinical Care'),
                  const SizedBox(height: 10),

                  _ActionTile(
                    icon: Icons.description_outlined,
                    label: 'Physician summary',
                    subtitle: 'EHR-ready markdown report for your doctor',
                    onTap: () => PhysicianSummarySheet.show(context, state),
                  ),
                  const Divider(color: ChronoTheme.border, height: 1),
                  _ActionTile(
                    icon: Icons.history_toggle_off_rounded,
                    label: 'Missed-dose protocol',
                    subtitle: 'FDA-grounded guidance for delayed doses',
                    onTap: () {
                      if (state.doses.isNotEmpty) {
                        MissedDoseProtocolSheet.show(context, state.doses.first, state);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No active scheduled doses.')),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── Section 3: Danger Zone ────────────────────────────────
                  const _SectionLabel('Danger zone'),
                  const SizedBox(height: 10),

                  _DangerTile(
                    icon: Icons.restore_rounded,
                    label: 'Restore default regimen',
                    subtitle: 'Removes all custom medications and resets routine',
                    onTap: () => _confirmReset(context, state),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChronoTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ChronoTheme.border),
        ),
        title: const Text(
          'Restore default regimen?',
          style: TextStyle(
            color: ChronoTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'This removes all custom medications and restores the reference 6-drug clinical polypharmacy regimen, resetting routine anchors.',
          style: TextStyle(
            color: ChronoTheme.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: ChronoTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              state.reset(
                defaultRoutine: defaultRoutine,
                defaultMedications: defaultMedications,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Regimen restored.'),
                  backgroundColor: ChronoTheme.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: ChronoTheme.border),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChronoTheme.rose,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}

// ── Settings Header ───────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  final bool isDirty;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _SettingsHeader({
    required this.isDirty,
    required this.onSave,
    required this.onDiscard,
  });

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
          const Expanded(
            child: Text(
              'Settings',
              style: TextStyle(
                color: ChronoTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (isDirty) ...[
            GestureDetector(
              onTap: onDiscard,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Discard',
                  style: TextStyle(
                    color: ChronoTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: ChronoTheme.primary,
                foregroundColor: ChronoTheme.obsidian,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: Size.zero,
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: ChronoTheme.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── 24h Circadian Bar ─────────────────────────────────────────────────────────

class _CircadianBar extends StatelessWidget {
  final int wakeMinutes;
  final int sleepMinutes;
  final int breakfastMinutes;
  final int lunchMinutes;
  final int dinnerMinutes;
  final int wakingMinutes;
  final int sleepMinutes2;
  final int fastingMinutes;

  const _CircadianBar({
    required this.wakeMinutes,
    required this.sleepMinutes,
    required this.breakfastMinutes,
    required this.lunchMinutes,
    required this.dinnerMinutes,
    required this.wakingMinutes,
    required this.sleepMinutes2,
    required this.fastingMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final wakeH  = wakingMinutes ~/ 60;
    final wakeR  = wakingMinutes % 60;
    final sleepH = sleepMinutes2 ~/ 60;
    final sleepR = sleepMinutes2 % 60;
    final fastH  = fastingMinutes ~/ 60;
    final fastR  = fastingMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
        border: Border.all(color: ChronoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proportional 24h bar
          LayoutBuilder(builder: (ctx, constraints) {
            const totalMins = 1440.0;
            final w = constraints.maxWidth;
            final sleepPreWidth = wakeMinutes / totalMins * w;
            final wakeWidth = (sleepMinutes - wakeMinutes) / totalMins * w;
            final sleepPostWidth = (totalMins - sleepMinutes) / totalMins * w;

            final bkfstOffset = breakfastMinutes / totalMins * w;
            final lunchOffset = lunchMinutes / totalMins * w;
            final dinnerOffset = dinnerMinutes / totalMins * w;

            return SizedBox(
              height: 28,
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        width: sleepPreWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFF64748B).withOpacity(0.15),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                        ),
                      ),
                      Container(
                        width: wakeWidth,
                        color: ChronoTheme.primary.withOpacity(0.12),
                      ),
                      Container(
                        width: sleepPostWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFF64748B).withOpacity(0.15),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Meal pins
                  for (final offset in [bkfstOffset, lunchOffset, dinnerOffset])
                    Positioned(
                      left: offset - 1,
                      top: 4,
                      bottom: 4,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: ChronoTheme.secondary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // Telemetry row
          Row(
            children: [
              _BarStat(
                label: 'Awake',
                value: '${wakeH}h ${wakeR}m',
                color: ChronoTheme.primary,
              ),
              const SizedBox(width: 16),
              _BarStat(
                label: 'Sleep',
                value: '${sleepH}h ${sleepR}m',
                color: ChronoTheme.textSecondary,
              ),
              const SizedBox(width: 16),
              _BarStat(
                label: 'Fast',
                value: '${fastH}h ${fastR}m',
                color: ChronoTheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BarStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ChronoTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: ChronoTheme.monoFont,
          ),
        ),
      ],
    );
  }
}

// ── Time Tile (Routine anchor editor) ─────────────────────────────────────────

class _TimeTile extends StatelessWidget {
  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  const _TimeTile({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  String _formatTime(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickTime(BuildContext context) async {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
      builder: (ctx, child) => Theme(
        data: ChronoTheme.darkTheme.copyWith(
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: ChronoTheme.surfaceCard,
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
    return InkWell(
      onTap: () => _pickTime(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: ChronoTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              _formatTime(minutes),
              style: const TextStyle(
                color: ChronoTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: ChronoTheme.monoFont,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: ChronoTheme.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Tile (Clinical Care section) ───────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ChronoTheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: ChronoTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ChronoTheme.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: ChronoTheme.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Danger Tile ───────────────────────────────────────────────────────────────

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceCard,
          borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
          border: Border.all(color: ChronoTheme.rose.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ChronoTheme.rose),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: ChronoTheme.rose,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ChronoTheme.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: ChronoTheme.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
