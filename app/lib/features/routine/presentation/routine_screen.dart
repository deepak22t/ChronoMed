import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';

/// Phase 5: Symmetrical & Elevated Circadian Routine Screen
///
/// Implements Calm Health design principles:
/// - 24-Hour Circadian Architecture Bar (Sleep, Diurnal Waking, Meal Pins).
/// - 3-Point Clinical Telemetry: Waking Window, Sleep Target, Overnight Fast.
/// - Symmetrical Anchor Cards for Sleep Architecture & Metabolic Meals.
/// - Pharmacokinetic Auto-Synchronization Notice.
/// - Zero cartoon emojis; pure vector outline icons.
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
          .firstWhere(
            (m) => m.type == MealType.breakfast,
            orElse: () => const MealAnchor(
              id: '_',
              type: MealType.breakfast,
              startTimeMinutes: 510,
            ),
          )
          .startTimeMinutes;
      _lunchMinutes = meals
          .firstWhere(
            (m) => m.type == MealType.lunch,
            orElse: () => const MealAnchor(
              id: '_',
              type: MealType.lunch,
              startTimeMinutes: 780,
            ),
          )
          .startTimeMinutes;
      _dinnerMinutes = meals
          .firstWhere(
            (m) => m.type == MealType.dinner,
            orElse: () => const MealAnchor(
              id: '_',
              type: MealType.dinner,
              startTimeMinutes: 1170,
            ),
          )
          .startTimeMinutes;
      _isDirty = false;
    });
  }

  void _saveRoutine() {
    if (_wakeMinutes >= _sleepMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Wake time must precede sleep time in diurnal cycle.'),
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
        MealAnchor(
          id: 'm1',
          type: MealType.breakfast,
          startTimeMinutes: _breakfastMinutes,
        ),
        MealAnchor(
          id: 'm2',
          type: MealType.lunch,
          startTimeMinutes: _lunchMinutes,
        ),
        MealAnchor(
          id: 'm3',
          type: MealType.dinner,
          startTimeMinutes: _dinnerMinutes,
          durationMinutes: 45,
        ),
      ],
    );

    AppStateProvider.of(context).updateRoutine(newRoutine);
    setState(() => _isDirty = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: ChronoTheme.secondary, size: 18),
            SizedBox(width: 8),
            Text('Routine synchronized — schedule re-optimized.'),
          ],
        ),
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
    final wakingMins = (_sleepMinutes - _wakeMinutes).clamp(0, 1440);
    final sleepMins = (1440 - _sleepMinutes + _wakeMinutes) % 1440;
    final fastMins = (1440 - _dinnerMinutes + _breakfastMinutes) % 1440;

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            // Symmetrical Header
            _RoutineHeader(
              isDirty: _isDirty,
              onSave: _saveRoutine,
              onReset: _syncFromState,
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                children: [
                  // Circadian Visual Card
                  _CircadianArchitectureCard(
                    wakeMinutes: _wakeMinutes,
                    sleepMinutes: _sleepMinutes,
                    breakfastMinutes: _breakfastMinutes,
                    lunchMinutes: _lunchMinutes,
                    dinnerMinutes: _dinnerMinutes,
                    wakingMinutes: wakingMins,
                    sleepDurationMinutes: sleepMins,
                    fastingMinutes: fastMins,
                  ),

                  const SizedBox(height: 20),

                  // Section 1: Sleep Architecture
                  const _SectionHeader(
                    title: 'SLEEP ARCHITECTURE',
                    subtitle: 'Diurnal cycle & circadian synchronization',
                    icon: Icons.bedtime_outlined,
                  ),
                  const SizedBox(height: 10),
                  _AnchorTile(
                    label: 'Wake-Up Time',
                    subtitle: 'Circadian cortisol awakening response',
                    icon: Icons.wb_sunny_outlined,
                    minutes: _wakeMinutes,
                    color: ChronoTheme.primary,
                    onChanged: (v) => setState(() {
                      _wakeMinutes = v;
                      _isDirty = true;
                    }),
                  ),
                  const SizedBox(height: 8),
                  _AnchorTile(
                    label: 'Bedtime',
                    subtitle: 'Nocturnal melatonin & cellular recovery',
                    icon: Icons.nightlight_outlined,
                    minutes: _sleepMinutes,
                    color: ChronoTheme.textSecondary,
                    onChanged: (v) => setState(() {
                      _sleepMinutes = v;
                      _isDirty = true;
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Metabolic Meal Anchors
                  const _SectionHeader(
                    title: 'METABOLIC MEAL ANCHORS',
                    subtitle: 'Prandial buffers & pharmacokinetic windows',
                    icon: Icons.restaurant_outlined,
                  ),
                  const SizedBox(height: 10),
                  _AnchorTile(
                    label: 'Breakfast',
                    subtitle: 'Fast-breaking meal (ends nocturnal fast)',
                    icon: Icons.free_breakfast_outlined,
                    minutes: _breakfastMinutes,
                    color: ChronoTheme.secondary,
                    onChanged: (v) => setState(() {
                      _breakfastMinutes = v;
                      _isDirty = true;
                    }),
                  ),
                  const SizedBox(height: 8),
                  _AnchorTile(
                    label: 'Lunch',
                    subtitle: 'Midday postprandial glycemic window',
                    icon: Icons.lunch_dining_outlined,
                    minutes: _lunchMinutes,
                    color: ChronoTheme.primary,
                    onChanged: (v) => setState(() {
                      _lunchMinutes = v;
                      _isDirty = true;
                    }),
                  ),
                  const SizedBox(height: 8),
                  _AnchorTile(
                    label: 'Dinner',
                    subtitle: 'Evening meal (initiates overnight fast)',
                    icon: Icons.dinner_dining_outlined,
                    minutes: _dinnerMinutes,
                    color: ChronoTheme.secondary,
                    onChanged: (v) => setState(() {
                      _dinnerMinutes = v;
                      _isDirty = true;
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Clinical Auto-Synchronization Reassurance
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ChronoTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ChronoTheme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ChronoTheme.cyanSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.sync_rounded,
                            color: ChronoTheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Continuous Constraint Preservation',
                                style: TextStyle(
                                  color: ChronoTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Whenever your anchors change, ChronoMed instantly recalculates '
                                'fasting intervals, meal buffers (60m pre / 120m post), and 4-hour cation '
                                'chelation gaps without manual intervention.',
                                style: TextStyle(
                                  color: ChronoTheme.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
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
            ),
          ],
        ),
      ),
      // Floating Save Pill (appears when modified)
      floatingActionButton: _isDirty
          ? FloatingActionButton.extended(
              onPressed: _saveRoutine,
              backgroundColor: ChronoTheme.secondary,
              foregroundColor: ChronoTheme.obsidian,
              elevation: 4,
              icon: const Icon(Icons.check_rounded),
              label: const Text(
                'Save & Re-optimize Schedule',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
              ),
            )
          : null,
    );
  }
}

// ── Symmetrical Header ────────────────────────────────────────────────────────

class _RoutineHeader extends StatelessWidget {
  final bool isDirty;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const _RoutineHeader({
    required this.isDirty,
    required this.onSave,
    required this.onReset,
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Circadian Routine',
                style: TextStyle(
                  color: ChronoTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Synchronize biological sleep & meal anchors',
                style: TextStyle(
                  color: ChronoTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isDirty)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.undo_rounded, size: 20),
                  color: ChronoTheme.textSecondary,
                  tooltip: 'Discard Changes',
                  onPressed: onReset,
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ChronoTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ChronoTheme.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    color: ChronoTheme.secondary,
                    size: 13,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'SYNCHRONIZED',
                    style: TextStyle(
                      color: ChronoTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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

// ── Circadian Architecture Hero Card ──────────────────────────────────────────

class _CircadianArchitectureCard extends StatelessWidget {
  final int wakeMinutes;
  final int sleepMinutes;
  final int breakfastMinutes;
  final int lunchMinutes;
  final int dinnerMinutes;
  final int wakingMinutes;
  final int sleepDurationMinutes;
  final int fastingMinutes;

  const _CircadianArchitectureCard({
    required this.wakeMinutes,
    required this.sleepMinutes,
    required this.breakfastMinutes,
    required this.lunchMinutes,
    required this.dinnerMinutes,
    required this.wakingMinutes,
    required this.sleepDurationMinutes,
    required this.fastingMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final wakeHours = wakingMinutes ~/ 60;
    final wakeRem = wakingMinutes % 60;
    final sleepHours = sleepDurationMinutes ~/ 60;
    final sleepRem = sleepDurationMinutes % 60;
    final fastHours = fastingMinutes ~/ 60;
    final fastRem = fastingMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: ChronoTheme.primary, size: 16),
              SizedBox(width: 8),
              Text(
                '24-HOUR CIRCADIAN TOPOLOGY',
                style: TextStyle(
                  color: ChronoTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Proportional 24-hour visual bar
          _CircadianBar(
            wakeMinutes: wakeMinutes,
            sleepMinutes: sleepMinutes,
            breakfastMinutes: breakfastMinutes,
            lunchMinutes: lunchMinutes,
            dinnerMinutes: dinnerMinutes,
          ),

          const SizedBox(height: 18),

          // 3-Point Clinical Telemetry Row
          Row(
            children: [
              Expanded(
                child: _TelemetryPill(
                  label: 'WAKING WINDOW',
                  value: '${wakeHours}h ${wakeRem}m',
                  color: ChronoTheme.primary,
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TelemetryPill(
                  label: 'SLEEP TARGET',
                  value: '${sleepHours}h ${sleepRem}m',
                  color: ChronoTheme.textSecondary,
                  icon: Icons.bedtime_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TelemetryPill(
                  label: 'OVERNIGHT FAST',
                  value: '${fastHours}h ${fastRem}m',
                  color: ChronoTheme.secondary,
                  icon: Icons.night_shelter_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Proportional 24h Bar Custom Visual ────────────────────────────────────────

class _CircadianBar extends StatelessWidget {
  final int wakeMinutes;
  final int sleepMinutes;
  final int breakfastMinutes;
  final int lunchMinutes;
  final int dinnerMinutes;

  const _CircadianBar({
    required this.wakeMinutes,
    required this.sleepMinutes,
    required this.breakfastMinutes,
    required this.lunchMinutes,
    required this.dinnerMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // Total minutes in a day = 1440
        final wakeX = (wakeMinutes / 1440.0) * totalWidth;
        final sleepX = (sleepMinutes / 1440.0) * totalWidth;
        final bFastX = (breakfastMinutes / 1440.0) * totalWidth;
        final lunchX = (lunchMinutes / 1440.0) * totalWidth;
        final dinnerX = (dinnerMinutes / 1440.0) * totalWidth;

        return Column(
          children: [
            // Bar Track
            SizedBox(
              height: 24,
              child: Stack(
                children: [
                  // Base Nocturnal Sleep Track (Entire 24h background)
                  Container(
                    width: totalWidth,
                    height: 12,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: ChronoTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ChronoTheme.border),
                    ),
                  ),

                  // Diurnal Waking Window Segment
                  Positioned(
                    left: wakeX,
                    width: (sleepX - wakeX).clamp(0, totalWidth),
                    top: 6,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: ChronoTheme.primary.withOpacity(0.35),
                        border: Border.all(color: ChronoTheme.primary, width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),

                  // Meal Pins
                  _buildMealMarker(bFastX, 'B'),
                  _buildMealMarker(lunchX, 'L'),
                  _buildMealMarker(dinnerX, 'D'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Time Labels Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('00:00', style: TextStyle(color: ChronoTheme.textMuted, fontSize: 10)),
                Text(
                  IntervalMath.formatMinuteOfDay(wakeMinutes),
                  style: const TextStyle(color: ChronoTheme.primary, fontSize: 10, fontWeight: FontWeight.w600),
                ),
                Text(
                  IntervalMath.formatMinuteOfDay(sleepMinutes),
                  style: const TextStyle(color: ChronoTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const Text('24:00', style: TextStyle(color: ChronoTheme.textMuted, fontSize: 10)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMealMarker(double x, String label) {
    return Positioned(
      left: (x - 7).clamp(0, 500),
      top: 3,
      child: Container(
        width: 16,
        height: 18,
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(color: ChronoTheme.secondary, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: ChronoTheme.secondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Telemetry Pill ────────────────────────────────────────────────────────────

class _TelemetryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _TelemetryPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ChronoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ChronoTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: ChronoTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: ChronoTheme.monoFont,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: ChronoTheme.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: ChronoTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: ChronoTheme.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Symmetrical Anchor Tile ───────────────────────────────────────────────────

class _AnchorTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final int minutes;
  final Color color;
  final ValueChanged<int> onChanged;

  const _AnchorTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.minutes,
    required this.color,
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
            primary: ChronoTheme.primary,
            surface: ChronoTheme.surfaceCard,
            onSurface: ChronoTheme.textPrimary,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: ChronoTheme.surfaceCard,
            dialBackgroundColor: ChronoTheme.surfaceElevated,
            dialHandColor: ChronoTheme.primary,
            hourMinuteColor: ChronoTheme.surfaceElevated,
            hourMinuteTextColor: ChronoTheme.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: ChronoTheme.border),
            ),
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

    return InkWell(
      onTap: () => _pickTime(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ChronoTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ChronoTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ChronoTheme.border),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: ChronoTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ChronoTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: ChronoTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ChronoTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatted,
                    style: const TextStyle(
                      color: ChronoTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: ChronoTheme.monoFont,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: ChronoTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
