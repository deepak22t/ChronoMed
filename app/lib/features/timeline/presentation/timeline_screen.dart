import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';
import 'timeline_painter.dart';

/// Clinical Timeline Screen (Mobile-First Masterpiece).
///
/// Provides a dual-mode experience:
/// 1. [ChronoFeedView] (Default): A clear, readable, touch-friendly vertical
///    schedule integrating medications, meals, fasting buffers, and sleep into
///    a unified chronological stream with one-tap logging.
/// 2. [CircadianMapView]: A high-definition 24-hour visual chronobiology canvas.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  // 0 = Chrono Feed (Cards), 1 = 24h Circadian Map
  int _viewMode = 0;

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
            Expanded(
              child: state.hasConflict
                  ? _ConflictPlaceholder(state: state)
                  : _viewMode == 0
                      ? _ChronoFeedView(state: state)
                      : _CircadianMapView(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 1. Top Header & Mode Switcher ───────────────────────────────────────────

class _TimelineHeader extends StatelessWidget {
  final AppState state;
  final int viewMode;
  final ValueChanged<int> onViewModeChanged;

  const _TimelineHeader({
    required this.state,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  String _getPhaseTitle(int minuteOfDay) {
    if (minuteOfDay < 360) return '🌙 Night Rest Window';
    if (minuteOfDay < 720) return '🌅 Morning Circadian Surge';
    if (minuteOfDay < 1020) return '☀️ Afternoon Metabolic Phase';
    if (minuteOfDay < 1320) return '🌆 Evening Nutritional Buffer';
    return '🌙 Bedtime Rest Preparation';
  }

  @override
  Widget build(BuildContext context) {
    final phaseTitle = _getPhaseTitle(state.currentMinuteOfDay);
    final currentTimeStr = IntervalMath.formatMinuteOfDay(state.currentMinuteOfDay);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: ChronoTheme.surface,
        border: Border(bottom: BorderSide(color: ChronoTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Shift Button
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
                          phaseTitle,
                          style: const TextStyle(
                            color: ChronoTheme.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: ChronoTheme.textDim,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentTimeStr,
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
              // Simulate +2h or Reset button
              if (state.isOversleptMode)
                OutlinedButton.icon(
                  onPressed: () => state.resetOverslept(),
                  icon: const Icon(Icons.refresh_rounded, size: 13),
                  label: const Text('Reset Time', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ChronoTheme.rose,
                    side: const BorderSide(color: ChronoTheme.rose),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => state.simulateOverslept(),
                  icon: const Icon(Icons.alarm_add_rounded, size: 13),
                  label: const Text('+2h Overslept', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ChronoTheme.amber,
                    side: const BorderSide(color: ChronoTheme.amber),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Segmented Switcher: [ 📋 Schedule Feed ] [ 📊 24h Circadian Map ]
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: ChronoTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ChronoTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentTab(
                    icon: Icons.view_agenda_rounded,
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? ChronoTheme.cyan.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: isSelected ? Border.all(color: ChronoTheme.cyan.withOpacity(0.4)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? ChronoTheme.cyan : ChronoTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? ChronoTheme.textPrimary : ChronoTheme.textMuted,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? ChronoTheme.cyan : ChronoTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: isSelected ? ChronoTheme.obsidian : ChronoTheme.textDim,
                    fontSize: 10,
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

// ── 2. Primary Chrono Feed View (The Core Solution) ───────────────────────────

class _ChronoFeedView extends StatelessWidget {
  final AppState state;
  const _ChronoFeedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final nextDose = state.nextDose;
    final timelineEvents = _buildTimelineEvents(state);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // 1. Hero Next-Dose Banner
        if (nextDose != null)
          _NextDoseHeroCard(dose: nextDose, state: state)
        else if (state.doses.isNotEmpty && state.adherenceRatio >= 1.0)
          const _AllCompletedCard(),

        const SizedBox(height: 16),

        // 2. Timeline Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TODAY\'S CHRONOLOGICAL ORDER',
              style: TextStyle(
                color: ChronoTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${state.takenCount}/${state.totalDoses} Taken',
              style: const TextStyle(
                color: ChronoTheme.emerald,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3. Chronological Flow Stream
        ...timelineEvents.map((event) => _TimelineItemWidget(event: event, state: state)),
      ],
    );
  }

  List<_TimelineEvent> _buildTimelineEvents(AppState state) {
    final events = <_TimelineEvent>[];

    // Wake Up Event
    events.add(
      _TimelineEvent(
        minute: state.routine.wakeTimeMinutes,
        type: _EventType.wake,
        title: 'Circadian Wake Up',
        subtitle: 'Cortisol surge window activates',
      ),
    );

    // Meal Events
    for (final meal in state.routine.meals) {
      events.add(
        _TimelineEvent(
          minute: meal.startTimeMinutes,
          type: _EventType.meal,
          meal: meal,
          title: '${meal.displayName} Window',
          subtitle:
              '${IntervalMath.formatMinuteOfDay(meal.startTimeMinutes)} - ${IntervalMath.formatMinuteOfDay(meal.endTimeMinutes)}',
        ),
      );
    }

    // Medication Dose Events
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

    // Sleep Event
    events.add(
      _TimelineEvent(
        minute: state.routine.sleepTimeMinutes,
        type: _EventType.sleep,
        title: 'Bedtime & Melatonin Window',
        subtitle: 'Optimal circadian sleep onset',
      ),
    );

    // Sort strictly chronologically by minute
    events.sort((a, b) => a.minute.compareTo(b.minute));

    // Insert live "NOW" event marker in the correct chronological position
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

// ── 3. Next Dose Hero Banner ──────────────────────────────────────────────────

class _NextDoseHeroCard extends StatelessWidget {
  final ScheduledDose dose;
  final AppState state;

  const _NextDoseHeroCard({required this.dose, required this.state});

  @override
  Widget build(BuildContext context) {
    final minutesDiff = dose.scheduledMinute - state.currentMinuteOfDay;
    final countdownStr = minutesDiff <= 0
        ? 'Due Now!'
        : minutesDiff < 60
            ? 'in $minutesDiff min'
            : 'in ${minutesDiff ~/ 60}h ${minutesDiff % 60}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronoTheme.cyan.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ChronoTheme.cyan.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ChronoTheme.cyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'UPCOMING NEXT DOSE',
                style: TextStyle(
                  color: ChronoTheme.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ChronoTheme.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ChronoTheme.cyan.withOpacity(0.3)),
                ),
                child: Text(
                  countdownStr,
                  style: const TextStyle(
                    color: ChronoTheme.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Scheduled Time Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ChronoTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ChronoTheme.border),
                ),
                child: Text(
                  dose.formattedTime,
                  style: const TextStyle(
                    color: ChronoTheme.textPrimary,
                    fontSize: 14,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dose.clinicalInstruction,
                      style: const TextStyle(
                        color: ChronoTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => state.markDoseTaken(dose.medicationId),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Mark as Taken Now', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChronoTheme.emerald,
                foregroundColor: ChronoTheme.obsidian,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChronoTheme.emerald.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronoTheme.emerald.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_rounded, color: ChronoTheme.emerald, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Doses Completed!',
                  style: TextStyle(
                    color: ChronoTheme.emerald,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '100% adherence maintained today with circadian synchronization.',
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

// ── 4. Unified Timeline Item Widget (Card + Connector) ────────────────────────

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

    // Wake or Sleep milestone
    return _buildRoutineMilestone(event);
  }

  Widget _buildNowDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ChronoTheme.cyan,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radio_button_checked, size: 10, color: ChronoTheme.obsidian),
                SizedBox(width: 4),
                Text(
                  'CURRENT TIME',
                  style: TextStyle(
                    color: ChronoTheme.obsidian,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ChronoTheme.cyan,
                    ChronoTheme.cyan.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Text(
            IntervalMath.formatMinuteOfDay(event.minute),
            style: const TextStyle(
              color: ChronoTheme.cyan,
              fontSize: 11,
              fontFamily: ChronoTheme.monoFont,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseItem(BuildContext context, ScheduledDose dose) {
    final isTaken = dose.status == DoseStatus.taken;
    final isDue = dose.status == DoseStatus.due;

    final statusColor = isTaken
        ? ChronoTheme.emerald
        : isDue
            ? ChronoTheme.cyan
            : ChronoTheme.amber;

    return InkWell(
      onTap: () => _openDoseDetailSheet(context, dose, state),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isTaken ? ChronoTheme.surface : ChronoTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isTaken
                ? ChronoTheme.border
                : isDue
                    ? ChronoTheme.cyan.withOpacity(0.6)
                    : ChronoTheme.border,
            width: isDue ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Time, Status Chip, and Mark Taken Action
            Row(
              children: [
                // Time Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ChronoTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    dose.formattedTime,
                    style: TextStyle(
                      color: isTaken ? ChronoTheme.textDim : statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: ChronoTheme.monoFont,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge
                ChronoTheme.badge(
                  dose.status.displayName.toUpperCase(),
                  statusColor,
                ),

                const Spacer(),

                // One-touch Checkmark Button
                IconButton(
                  onPressed: isTaken ? null : () => state.markDoseTaken(dose.medicationId),
                  icon: Icon(
                    isTaken ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isTaken ? ChronoTheme.emerald : ChronoTheme.textMuted,
                    size: 24,
                  ),
                  tooltip: isTaken ? 'Taken' : 'Mark as Taken',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Medication Name & Dosage
            Text(
              '${dose.medicationName} (${dose.dosage})',
              style: TextStyle(
                color: isTaken ? ChronoTheme.textMuted : ChronoTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                decoration: isTaken ? TextDecoration.lineThrough : null,
              ),
            ),

            const SizedBox(height: 6),

            // Food & Safety Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ChronoTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant_rounded,
                    size: 12,
                    color: isTaken ? ChronoTheme.textDim : ChronoTheme.cyan,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      dose.safeFoodWindowNote,
                      style: TextStyle(
                        color: isTaken ? ChronoTheme.textDim : ChronoTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Clinical Instruction
            Text(
              dose.clinicalInstruction,
              style: const TextStyle(
                color: ChronoTheme.textDim,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(MealAnchor meal) {
    final icon = meal.type == MealType.breakfast
        ? '🍳'
        : meal.type == MealType.lunch
            ? '🥗'
            : '🍲';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ChronoTheme.emerald.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChronoTheme.emerald.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${meal.displayName} Window',
                  style: const TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${IntervalMath.formatMinuteOfDay(meal.startTimeMinutes)} – ${IntervalMath.formatMinuteOfDay(meal.endTimeMinutes)} (${meal.durationMinutes} min meal buffer)',
                  style: TextStyle(
                    color: const Color(0xFF6EE7B7).withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: ChronoTheme.monoFont,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ChronoTheme.emerald.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'MEAL',
              style: TextStyle(
                color: Color(0xFF6EE7B7),
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineMilestone(_TimelineEvent ev) {
    final isWake = ev.type == _EventType.wake;
    final color = isWake ? ChronoTheme.amber : const Color(0xFF818CF8);
    final icon = isWake ? Icons.wb_sunny_rounded : Icons.bedtime_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${ev.title} • ${IntervalMath.formatMinuteOfDay(ev.minute)}',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            ev.subtitle,
            style: TextStyle(
              color: color.withOpacity(0.7),
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
      backgroundColor: ChronoTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DoseDetailSheet(dose: dose, state: state),
    );
  }
}

// ── 5. Secondary 24h Circadian Canvas View ────────────────────────────────────

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
    const gutterWidth = 54.0;
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
      backgroundColor: ChronoTheme.surfaceCard,
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
        // Legend Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: ChronoTheme.surface,
          child: const Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _LegendDot(color: ChronoTheme.emerald, label: 'Meal Window'),
              _LegendDot(color: Color(0xFFF43F5E), label: 'Fasting Buffer'),
              _LegendDot(color: ChronoTheme.amber, label: 'Scheduled Dose'),
              _LegendDot(color: Color(0xFF818CF8), label: 'Sleep Zone'),
              _LegendDot(color: ChronoTheme.cyan, label: 'Current Now'),
            ],
          ),
        ),
        // Canvas
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
          width: 8,
          height: 8,
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
              width: 36,
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
                  color: ChronoTheme.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: ChronoTheme.monoFont,
                ),
              ),
              const SizedBox(width: 10),
              ChronoTheme.badge(
                isTaken ? 'TAKEN' : 'SCHEDULED',
                isTaken ? ChronoTheme.emerald : ChronoTheme.amber,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${dose.medicationName} (${dose.dosage})',
            style: const TextStyle(
              color: ChronoTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.info_outline_rounded,
            color: ChronoTheme.cyan,
            title: 'Clinical Instruction',
            text: dose.clinicalInstruction,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.restaurant_menu_rounded,
            color: ChronoTheme.emerald,
            title: 'Food & Nutrition Buffer',
            text: dose.safeFoodWindowNote,
          ),
          const SizedBox(height: 20),
          if (!isTaken)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  state.markDoseTaken(dose.medicationId);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Mark as Taken Now', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChronoTheme.emerald,
                  foregroundColor: ChronoTheme.obsidian,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
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
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: ChronoTheme.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: ChronoTheme.rose, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Schedule Conflict Detected',
              style: TextStyle(
                color: ChronoTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.conflict?.clinicalExplanation ?? 'Check the Today tab for conflict details.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ChronoTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 7. Timeline Event Data Models ─────────────────────────────────────────────

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
