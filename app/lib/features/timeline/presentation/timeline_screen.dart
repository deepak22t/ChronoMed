import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';
import '../../dashboard/presentation/missed_dose_protocol_sheet.dart';
import 'timeline_painter.dart';

/// Clinical Timeline Screen (Phase 3 Masterwork).
///
/// Features:
/// 1. Dual-Mode Switcher (Schedule Feed vs. 24h Circadian Map).
/// 2. Event Filters (All Events / Medications Only / Meals & Rest).
/// 3. Connected Hairline Vertical Spine with Zero Cartoon Emojis.
/// 4. Tactile Checkmark Button with Instant State Updates.
/// 5. Collision-Resistant 24h Visualizer Canvas.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  // 0 = Schedule Feed, 1 = 24h Map
  int _viewMode = 0;
  // 0 = All, 1 = Meds Only, 2 = Meals/Sleep Only
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            _TimelineHeader(
              state: state,
              viewMode: _viewMode,
              onViewModeChanged: (mode) => setState(() => _viewMode = mode),
            ),
            if (state.isRecalibrated) _TimelineRecalibrationBanner(state: state),
            Expanded(
              child: state.hasConflict
                  ? _ConflictPlaceholder(state: state)
                  : _viewMode == 0
                      ? _ChronoFeedView(
                          state: state,
                          filterIndex: _filterIndex,
                          onFilterChanged: (idx) => setState(() => _filterIndex = idx),
                        )
                      : _CircadianMapView(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timeline Recalibration Banner ─────────────────────────────────────────────

class _TimelineRecalibrationBanner extends StatelessWidget {
  final AppState state;
  const _TimelineRecalibrationBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final reason = state.recalibratedSchedule?.shiftReason ?? 'Timeline dynamically shifted';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: ChronoTheme.cyanSurface,
        border: Border(bottom: BorderSide(color: ChronoTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_rounded, size: 14, color: ChronoTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                color: ChronoTheme.primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => state.resetRecalibration(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ChronoTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ChronoTheme.primary.withOpacity(0.3)),
              ),
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: ChronoTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 1. Top Header & Segmented Capsule ─────────────────────────────────────────

class _TimelineHeader extends StatelessWidget {
  final AppState state;
  final int viewMode;
  final ValueChanged<int> onViewModeChanged;

  const _TimelineHeader({
    required this.state,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  String _getPhase(int minute) {
    if (minute < 360) return 'Night Rest';
    if (minute < 720) return 'Morning Surge';
    if (minute < 1020) return 'Midday Phase';
    if (minute < 1320) return 'Evening Buffer';
    return 'Bedtime Rest';
  }

  @override
  Widget build(BuildContext context) {
    final phaseStr = _getPhase(state.currentMinuteOfDay);
    final timeStr = IntervalMath.formatMinuteOfDay(state.currentMinuteOfDay);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: ChronoTheme.surface,
        border: Border(bottom: BorderSide(color: ChronoTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Timeline & Schedule',
                      style: TextStyle(
                        color: ChronoTheme.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          phaseStr,
                          style: const TextStyle(
                            color: ChronoTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(width: 3, height: 3, decoration: const BoxDecoration(color: ChronoTheme.textDim, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: ChronoTheme.textDim,
                            fontSize: 11,
                            fontFamily: ChronoTheme.monoFont,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (state.isOversleptMode)
                OutlinedButton.icon(
                  onPressed: () => state.resetOverslept(),
                  icon: const Icon(Icons.refresh_rounded, size: 12),
                  label: const Text('Reset', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ChronoTheme.rose,
                    side: const BorderSide(color: ChronoTheme.rose),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => state.simulateOverslept(),
                  icon: const Icon(Icons.alarm_add_rounded, size: 12),
                  label: const Text('+2h Shift', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ChronoTheme.textSecondary,
                    side: const BorderSide(color: ChronoTheme.border),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Segmented Capsule
          Container(
            height: 34,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: ChronoTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ChronoTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentTab(
                    icon: Icons.view_agenda_outlined,
                    label: 'Schedule Feed',
                    badgeCount: state.doses.length,
                    isSelected: viewMode == 0,
                    onTap: () => onViewModeChanged(0),
                  ),
                ),
                Expanded(
                  child: _SegmentTab(
                    icon: Icons.timelapse_rounded,
                    label: '24h Circadian Map',
                    isSelected: viewMode == 1,
                    onTap: () => onViewModeChanged(1),
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

class _SegmentTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.icon,
    required this.label,
    this.badgeCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? ChronoTheme.cyanSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: ChronoTheme.primary.withOpacity(0.35)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? ChronoTheme.primary : ChronoTheme.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? ChronoTheme.textPrimary : ChronoTheme.textMuted,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? ChronoTheme.primary : ChronoTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: isSelected ? ChronoTheme.obsidian : ChronoTheme.textDim,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 2. Primary Chrono Feed View (With Event Filter Pills) ─────────────────────

class _ChronoFeedView extends StatelessWidget {
  final AppState state;
  final int filterIndex;
  final ValueChanged<int> onFilterChanged;

  const _ChronoFeedView({
    required this.state,
    required this.filterIndex,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final nextDose = state.nextDose;
    final allEvents = _buildTimelineEvents(state);

    final filteredEvents = switch (filterIndex) {
      1 => allEvents.where((e) => e.type == _EventType.dose || e.type == _EventType.nowMarker).toList(),
      2 => allEvents.where((e) => e.type != _EventType.dose).toList(),
      _ => allEvents,
    };

    final medCount = state.doses.length;
    final routineCount = state.routine.meals.length + 2;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        if (nextDose != null && filterIndex != 2)
          _NextDoseHeroCard(dose: nextDose, state: state)
        else if (state.doses.isNotEmpty && state.adherenceRatio >= 1.0)
          const _AllCompletedCard(),

        const SizedBox(height: 14),

        // Event Category Filter Pills
        Row(
          children: [
            _TimelineFilterPill(
              label: 'All (${allEvents.length - 1})',
              isSelected: filterIndex == 0,
              onTap: () => onFilterChanged(0),
            ),
            const SizedBox(width: 8),
            _TimelineFilterPill(
              label: 'Meds ($medCount)',
              isSelected: filterIndex == 1,
              onTap: () => onFilterChanged(1),
            ),
            const SizedBox(width: 8),
            _TimelineFilterPill(
              label: 'Routine ($routineCount)',
              isSelected: filterIndex == 2,
              onTap: () => onFilterChanged(2),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CHRONOLOGICAL ORDER',
              style: TextStyle(
                color: ChronoTheme.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${state.takenCount} of ${state.totalDoses} taken',
              style: const TextStyle(
                color: ChronoTheme.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...filteredEvents.map((e) => _TimelineItemWidget(event: e, state: state)),
      ],
    );
  }

  List<_TimelineEvent> _buildTimelineEvents(AppState state) {
    final events = <_TimelineEvent>[];

    // Wake Up
    events.add(
      _TimelineEvent(
        minute: state.routine.wakeTimeMinutes,
        type: _EventType.wake,
        title: 'Wake Up Window',
        subtitle: 'Circadian cortisol activation',
      ),
    );

    // Meals
    for (final meal in state.routine.meals) {
      events.add(
        _TimelineEvent(
          minute: meal.startTimeMinutes,
          type: _EventType.meal,
          meal: meal,
          title: '${meal.displayName} Window',
          subtitle: '${IntervalMath.formatMinuteOfDay(meal.startTimeMinutes)} - ${IntervalMath.formatMinuteOfDay(meal.endTimeMinutes)}',
        ),
      );
    }

    // Doses
    for (final dose in state.doses) {
      events.add(
        _TimelineEvent(
          minute: dose.scheduledMinute,
          type: _EventType.dose,
          dose: dose,
          title: dose.medicationName,
          subtitle: dose.dosage,
        ),
      );
    }

    // Sleep
    events.add(
      _TimelineEvent(
        minute: state.routine.sleepTimeMinutes,
        type: _EventType.sleep,
        title: 'Bedtime Window',
        subtitle: 'Melatonin circadian onset',
      ),
    );

    events.sort((a, b) => a.minute.compareTo(b.minute));

    // Insert live "NOW" divider
    final nowMinute = state.currentMinuteOfDay;
    var nowInserted = false;
    final finalEvents = <_TimelineEvent>[];

    for (var i = 0; i < events.length; i++) {
      if (!nowInserted && nowMinute < events[i].minute) {
        finalEvents.add(
          _TimelineEvent(
            minute: nowMinute,
            type: _EventType.nowMarker,
            title: 'Current Time (NOW)',
            subtitle: IntervalMath.formatMinuteOfDay(nowMinute),
          ),
        );
        nowInserted = true;
      }
      finalEvents.add(events[i]);
    }

    if (!nowInserted) {
      finalEvents.add(
        _TimelineEvent(
          minute: nowMinute,
          type: _EventType.nowMarker,
          title: 'Current Time (NOW)',
          subtitle: IntervalMath.formatMinuteOfDay(nowMinute),
        ),
      );
    }

    return finalEvents;
  }
}

class _TimelineFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimelineFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? ChronoTheme.cyanSurface : ChronoTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ChronoTheme.primary.withOpacity(0.4) : ChronoTheme.border,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? ChronoTheme.primary : ChronoTheme.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── 3. Next Dose Hero Banner ──────────────────────────────────────────────────

class _NextDoseHeroCard extends StatelessWidget {
  final ScheduledDose dose;
  final AppState state;

  const _NextDoseHeroCard({required this.dose, required this.state});

  @override
  Widget build(BuildContext context) {
    final diff = dose.scheduledMinute - state.currentMinuteOfDay;
    final countdown = diff <= 0
        ? 'Due Now'
        : diff < 60
            ? 'in $diff min'
            : 'in ${diff ~/ 60}h ${diff % 60}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
        border: Border.all(color: ChronoTheme.primary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: ChronoTheme.primary, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text(
                'NEXT DOSE',
                style: TextStyle(
                  color: ChronoTheme.primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                countdown,
                style: const TextStyle(color: ChronoTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: ChronoTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dose.formattedTime,
                  style: const TextStyle(
                    color: ChronoTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: ChronoTheme.monoFont,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dose.medicationName} (${dose.dosage})',
                      style: const TextStyle(color: ChronoTheme.textPrimary, fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dose.safeFoodWindowNote,
                      style: const TextStyle(color: ChronoTheme.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => state.markDoseTaken(dose.medicationId),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
              label: const Text('Mark as Taken', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChronoTheme.secondary,
                foregroundColor: ChronoTheme.obsidian,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllCompletedCard extends StatelessWidget {
  const _AllCompletedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChronoTheme.emeraldSurface,
        borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
        border: Border.all(color: ChronoTheme.secondary.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: ChronoTheme.secondary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Doses Completed',
                  style: TextStyle(color: ChronoTheme.secondary, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  '100% daily circadian adherence achieved.',
                  style: TextStyle(color: ChronoTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. Unified Timeline Item Widget ───────────────────────────────────────────

class _TimelineItemWidget extends StatelessWidget {
  final _TimelineEvent event;
  final AppState state;

  const _TimelineItemWidget({required this.event, required this.state});

  @override
  Widget build(BuildContext context) {
    if (event.type == _EventType.nowMarker) {
      return _buildNowDivider();
    }
    if (event.type == _EventType.dose) {
      return _buildDoseItem(context, event.dose!);
    }
    if (event.type == _EventType.meal) {
      return _buildMealItem(event.meal!);
    }
    return _buildRoutineMilestone(event);
  }

  Widget _buildNowDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: ChronoTheme.cyanSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ChronoTheme.primary.withOpacity(0.3)),
            ),
            child: const Text(
              'NOW',
              style: TextStyle(
                color: ChronoTheme.primary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1.0,
              color: ChronoTheme.primary.withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            IntervalMath.formatMinuteOfDay(event.minute),
            style: const TextStyle(
              color: ChronoTheme.primary,
              fontSize: 10.5,
              fontFamily: ChronoTheme.monoFont,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseItem(BuildContext context, ScheduledDose dose) {
    final isTaken = dose.status == DoseStatus.taken;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isTaken ? ChronoTheme.surface : ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
        border: Border.all(
          color: isTaken ? ChronoTheme.borderSubtle : ChronoTheme.border,
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _openDoseDetailSheet(context, dose, state),
        borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
        child: Row(
          children: [
            // Time Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isTaken ? ChronoTheme.surfaceElevated : ChronoTheme.cyanSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                dose.formattedTime,
                style: TextStyle(
                  color: isTaken ? ChronoTheme.textDim : ChronoTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: ChronoTheme.monoFont,
                  decoration: isTaken ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dose.medicationName} (${dose.dosage})',
                    style: TextStyle(
                      color: isTaken ? ChronoTheme.textMuted : ChronoTheme.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_outlined,
                        size: 11,
                        color: isTaken ? ChronoTheme.textDim : ChronoTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dose.safeFoodWindowNote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isTaken ? ChronoTheme.textDim : ChronoTheme.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Checkmark Circle Action
            GestureDetector(
              onTap: isTaken ? null : () => state.markDoseTaken(dose.medicationId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isTaken ? ChronoTheme.emeraldSurface : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isTaken ? ChronoTheme.secondary : ChronoTheme.border,
                    width: 1.5,
                  ),
                ),
                child: isTaken
                    ? const Icon(Icons.check_rounded, color: ChronoTheme.secondary, size: 16)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(MealAnchor meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ChronoTheme.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant_outlined, size: 14, color: ChronoTheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${meal.displayName} Window',
              style: const TextStyle(
                color: ChronoTheme.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${IntervalMath.formatMinuteOfDay(meal.startTimeMinutes)} – ${IntervalMath.formatMinuteOfDay(meal.endTimeMinutes)}',
            style: const TextStyle(
              color: ChronoTheme.textSecondary,
              fontSize: 11,
              fontFamily: ChronoTheme.monoFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineMilestone(_TimelineEvent ev) {
    final isWake = ev.type == _EventType.wake;
    final icon = isWake ? Icons.wb_sunny_outlined : Icons.bedtime_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: ChronoTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ChronoTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: ChronoTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${ev.title} • ${IntervalMath.formatMinuteOfDay(ev.minute)}',
              style: const TextStyle(
                color: ChronoTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            ev.subtitle,
            style: const TextStyle(
              color: ChronoTheme.textDim,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  void _openDoseDetailSheet(BuildContext context, ScheduledDose dose, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ChronoTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DoseDetailSheet(dose: dose, state: state),
    );
  }
}

// ── 5. Secondary 24h Circadian Map View ───────────────────────────────────────

class _CircadianMapView extends StatefulWidget {
  final AppState state;
  const _CircadianMapView({required this.state});

  @override
  State<_CircadianMapView> createState() => _CircadianMapViewState();
}

class _CircadianMapViewState extends State<_CircadianMapView> {
  final ScrollController _scrollController = ScrollController();
  ScheduledDose? _selectedDose;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  void _scrollToNow() {
    if (!_scrollController.hasClients) return;
    final targetOffset = (widget.state.currentMinuteOfDay / 1440.0) * 1680.0 - 150.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _onCanvasTap(TapUpDetails details, Size canvasSize) {
    const heightPerMinute = 1680.0 / 1440.0;
    const gutterWidth = 52.0;
    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy + _scrollController.offset;

    if (tapX < gutterWidth) return;

    for (final dose in widget.state.doses) {
      final doseY = dose.scheduledMinute * heightPerMinute;
      if ((tapY - doseY).abs() < 28) {
        setState(() => _selectedDose = dose);
        _showDoseBottomSheet(dose);
        return;
      }
    }
  }

  void _showDoseBottomSheet(ScheduledDose dose) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ChronoTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DoseDetailSheet(dose: dose, state: widget.state),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Subtle Legend
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: ChronoTheme.surface,
          child: const Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _LegendDot(color: ChronoTheme.secondary, label: 'Meal Window'),
              _LegendDot(color: ChronoTheme.rose, label: 'Fasting Buffer'),
              _LegendDot(color: ChronoTheme.primary, label: 'Scheduled Dose'),
              _LegendDot(color: ChronoTheme.textMuted, label: 'Sleep Zone'),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTapUp: (details) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox == null) return;
              _onCanvasTap(details, renderBox.size);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: 1680.0,
                child: LayoutBuilder(
                  builder: (ctx, constraints) => CustomPaint(
                    size: Size(constraints.maxWidth, 1680.0),
                    painter: TimelinePainter(
                      routine: widget.state.routine,
                      doses: widget.state.doses,
                      currentMinuteOfDay: widget.state.currentMinuteOfDay,
                      selectedDoseId: _selectedDose?.id,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: ChronoTheme.textDim, fontSize: 10)),
      ],
    );
  }
}

// ── 6. Dose Detail Modal Bottom Sheet ─────────────────────────────────────────

class _DoseDetailSheet extends StatelessWidget {
  final ScheduledDose dose;
  final AppState state;

  const _DoseDetailSheet({required this.dose, required this.state});

  @override
  Widget build(BuildContext context) {
    final isTaken = dose.status == DoseStatus.taken;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: ChronoTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                dose.formattedTime,
                style: const TextStyle(
                  color: ChronoTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: ChronoTheme.monoFont,
                ),
              ),
              const SizedBox(width: 10),
              ChronoTheme.badge(
                isTaken ? 'TAKEN' : 'SCHEDULED',
                isTaken ? ChronoTheme.secondary : ChronoTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${dose.medicationName} (${dose.dosage})',
            style: const TextStyle(
              color: ChronoTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.info_outline_rounded,
            color: ChronoTheme.primary,
            title: 'Clinical Instruction',
            text: dose.clinicalInstruction,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.restaurant_outlined,
            color: ChronoTheme.secondary,
            title: 'Food & Nutrition Buffer',
            text: dose.safeFoodWindowNote,
          ),
          const SizedBox(height: 16),
          // Missed-Dose Protocol action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                MissedDoseProtocolSheet.show(context, dose, state);
              },
              icon: const Icon(Icons.history_toggle_off_rounded, size: 16),
              label: const Text(
                'Missed or Delayed? View Protocol',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ChronoTheme.primary,
                side: BorderSide(color: ChronoTheme.primary.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (!isTaken) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  state.markDoseTaken(dose.medicationId);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Mark as Taken Now', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChronoTheme.secondary,
                  foregroundColor: ChronoTheme.obsidian,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _DetailRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(color: ChronoTheme.textSecondary, fontSize: 13, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConflictPlaceholder extends StatelessWidget {
  final AppState state;
  const _ConflictPlaceholder({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ChronoTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ChronoTheme.rose.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ChronoTheme.roseSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: ChronoTheme.rose.withOpacity(0.3)),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: ChronoTheme.rose, size: 22),
              ),
              const SizedBox(height: 12),
              const Text(
                'Circadian Schedule Infeasible',
                style: TextStyle(
                    color: ChronoTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                state.conflict?.clinicalExplanation ??
                    'Pharmacokinetic separation constraints cannot be satisfied.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: ChronoTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ChronoTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Switch to the Today tab to review 1-tap clinical resolutions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: ChronoTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _EventType {
  wake,
  meal,
  dose,
  sleep,
  nowMarker,
}

class _TimelineEvent {
  final int minute;
  final _EventType type;
  final String title;
  final String subtitle;
  final ScheduledDose? dose;
  final MealAnchor? meal;

  _TimelineEvent({
    required this.minute,
    required this.type,
    required this.title,
    required this.subtitle,
    this.dose,
    this.meal,
  });
}
