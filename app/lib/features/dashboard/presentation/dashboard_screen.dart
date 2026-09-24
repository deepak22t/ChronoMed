import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';
import '../../../main.dart' show defaultRoutine, defaultMedications;
import '../../timeline/presentation/timeline_painter.dart';
import '../../ai_assistant/presentation/ai_consultation_sheet.dart';
import 'missed_dose_protocol_sheet.dart';

/// Today Screen — primary user destination.
///
/// Shows what to take today, the next upcoming dose, and the full daily
/// schedule. Includes a list/map toggle: list view for dose tracking,
/// 24h circadian map for visual context.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 0 = List view, 1 = 24h Map view
  int _viewMode = 0;
  // 0 = All, 1 = Pending, 2 = Taken
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            _TodayHeader(
              state: state,
              viewMode: _viewMode,
              onViewModeChanged: (m) => setState(() => _viewMode = m),
            ),
            if (state.isRecalibrated)
              _RecalibrationBanner(state: state),
            Expanded(
              child: state.hasConflict
                  ? _ConflictView(state: state)
                  : _viewMode == 0
                      ? _DoseListView(
                          state: state,
                          filterIndex: _filterIndex,
                          onFilterChanged: (i) => setState(() => _filterIndex = i),
                        )
                      : _CircadianMapView(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _TodayHeader extends StatelessWidget {
  final AppState state;
  final int viewMode;
  final ValueChanged<int> onViewModeChanged;

  const _TodayHeader({
    required this.state,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                      'Today',
                      style: TextStyle(
                        color: ChronoTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      IntervalMath.formatMinuteOfDay(state.currentMinuteOfDay),
                      style: const TextStyle(
                        color: ChronoTheme.textMuted,
                        fontSize: 11,
                        fontFamily: ChronoTheme.monoFont,
                      ),
                    ),
                  ],
                ),
              ),
              // AI Clinical Explainer Button
              GestureDetector(
                onTap: () => AiConsultationSheet.show(context, state),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: ChronoTheme.cyanSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ChronoTheme.primary.withOpacity(0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 12, color: ChronoTheme.primary),
                      SizedBox(width: 4),
                      Text(
                        'Ask AI',
                        style: TextStyle(
                          color: ChronoTheme.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Adherence fraction — compact, non-decorative
              _AdherencePill(taken: state.takenCount, total: state.totalDoses),
            ],
          ),
          const SizedBox(height: 12),
          // View toggle: List / Map
          _ViewToggle(
            viewMode: viewMode,
            onChanged: onViewModeChanged,
          ),
        ],
      ),
    );
  }
}

class _AdherencePill extends StatelessWidget {
  final int taken;
  final int total;

  const _AdherencePill({required this.taken, required this.total});

  @override
  Widget build(BuildContext context) {
    final allDone = total > 0 && taken >= total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: allDone ? ChronoTheme.emeraldSurface : ChronoTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allDone
              ? ChronoTheme.secondary.withOpacity(0.4)
              : ChronoTheme.border,
        ),
      ),
      child: Text(
        '$taken / $total',
        style: TextStyle(
          color: allDone ? ChronoTheme.secondary : ChronoTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: ChronoTheme.monoFont,
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final int viewMode;
  final ValueChanged<int> onChanged;

  const _ViewToggle({required this.viewMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ChronoTheme.border),
      ),
      child: Row(
        children: [
          _ToggleSegment(
            label: 'List',
            icon: Icons.format_list_bulleted_rounded,
            isSelected: viewMode == 0,
            onTap: () => onChanged(0),
          ),
          _ToggleSegment(
            label: '24h Map',
            icon: Icons.timelapse_rounded,
            isSelected: viewMode == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleSegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? ChronoTheme.cyanSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(color: ChronoTheme.primary.withOpacity(0.35))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 12,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recalibration Banner ──────────────────────────────────────────────────────

class _RecalibrationBanner extends StatelessWidget {
  final AppState state;
  const _RecalibrationBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final reason = state.recalibratedSchedule?.shiftReason ?? 'Schedule dynamically shifted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: ChronoTheme.cyanSurface,
        border: Border(bottom: BorderSide(color: ChronoTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_rounded, size: 13, color: ChronoTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                color: ChronoTheme.primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => state.resetRecalibration(),
            child: const Text(
              'Reset',
              style: TextStyle(
                color: ChronoTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dose List View ────────────────────────────────────────────────────────────

class _DoseListView extends StatelessWidget {
  final AppState state;
  final int filterIndex;
  final ValueChanged<int> onFilterChanged;

  const _DoseListView({
    required this.state,
    required this.filterIndex,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allDoses = state.doses;
    final filteredDoses = switch (filterIndex) {
      1 => allDoses.where((d) => d.status != DoseStatus.taken).toList(),
      2 => allDoses.where((d) => d.status == DoseStatus.taken).toList(),
      _ => allDoses,
    };
    final nextDose = state.nextDose;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // Next dose hero — only when there is an upcoming dose and list filter is All or Pending
        if (nextDose != null && filterIndex != 2)
          _NextDoseHero(dose: nextDose, state: state)
        else if (allDoses.isNotEmpty && state.adherenceRatio >= 1.0)
          _AllDoneCard(),

        const SizedBox(height: 16),

        // Filter pills
        _FilterRow(
          selected: filterIndex,
          onChanged: onFilterChanged,
        ),

        const SizedBox(height: 12),

        // Dose cards
        if (filteredDoses.isEmpty)
          _EmptyFilter()
        else
          ...filteredDoses.map(
            (dose) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DoseCard(dose: dose, state: state),
            ),
          ),
      ],
    );
  }
}

// ── Next Dose Hero ────────────────────────────────────────────────────────────

class _NextDoseHero extends StatelessWidget {
  final ScheduledDose dose;
  final AppState state;

  const _NextDoseHero({required this.dose, required this.state});

  @override
  Widget build(BuildContext context) {
    final diff = dose.scheduledMinute - state.currentMinuteOfDay;
    final countdown = diff <= 0
        ? 'Due now'
        : diff < 60
            ? 'in $diff min'
            : 'in ${diff ~/ 60}h ${diff % 60}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(ChronoTheme.radiusLarge),
        border: Border.all(color: ChronoTheme.primary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dose.formattedTime,
                style: const TextStyle(
                  color: ChronoTheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: ChronoTheme.monoFont,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dose.medicationName,
                  style: const TextStyle(
                    color: ChronoTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                countdown,
                style: const TextStyle(
                  color: ChronoTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${dose.dosage}  ·  ${dose.safeFoodWindowNote}',
            style: const TextStyle(
              color: ChronoTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => state.markDoseTaken(dose.medicationId),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChronoTheme.secondary,
                foregroundColor: ChronoTheme.obsidian,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mark as Taken',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── All Done Card ─────────────────────────────────────────────────────────────

class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ChronoTheme.emeraldSurface,
        borderRadius: BorderRadius.circular(ChronoTheme.radiusLarge),
        border: Border.all(color: ChronoTheme.secondary.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: ChronoTheme.secondary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All doses taken',
                  style: TextStyle(
                    color: ChronoTheme.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Full daily regimen completed.',
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

// ── Filter Row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['All', 'Pending', 'Taken'];
    return Row(
      children: List.generate(labels.length, (i) {
        final isSelected = selected == i;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? ChronoTheme.cyanSurface : ChronoTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? ChronoTheme.primary.withOpacity(0.4)
                      : ChronoTheme.border,
                ),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: isSelected ? ChronoTheme.primary : ChronoTheme.textMuted,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Empty Filter ──────────────────────────────────────────────────────────────

class _EmptyFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No doses match this filter.',
          style: TextStyle(color: ChronoTheme.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}

// ── Dose Card ─────────────────────────────────────────────────────────────────

class _DoseCard extends StatelessWidget {
  final ScheduledDose dose;
  final AppState state;

  const _DoseCard({required this.dose, required this.state});

  @override
  Widget build(BuildContext context) {
    final isTaken = dose.status == DoseStatus.taken;

    return InkWell(
      onTap: () => _openDetailSheet(context),
      borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isTaken ? ChronoTheme.surface : ChronoTheme.surfaceCard,
          borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
          border: Border.all(
            color: isTaken ? ChronoTheme.borderSubtle : ChronoTheme.border,
          ),
        ),
        child: Row(
          children: [
            // Time — plain mono text, no inner container
            SizedBox(
              width: 48,
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
                    '${dose.medicationName}  ${dose.dosage}',
                    style: TextStyle(
                      color: isTaken ? ChronoTheme.textMuted : ChronoTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dose.safeFoodWindowNote,
                    style: TextStyle(
                      color: isTaken ? ChronoTheme.textDim : ChronoTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Tactile check circle
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

  void _openDetailSheet(BuildContext context) {
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

// ── Dose Detail Bottom Sheet ──────────────────────────────────────────────────

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
          // Drag handle
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

          // Time + name
          Text(
            dose.formattedTime,
            style: const TextStyle(
              color: ChronoTheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: ChronoTheme.monoFont,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${dose.medicationName}  (${dose.dosage})',
            style: const TextStyle(
              color: ChronoTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Clinical detail rows
          _SheetDetailRow(
            label: 'Instruction',
            text: dose.clinicalInstruction,
          ),
          const SizedBox(height: 8),
          _SheetDetailRow(
            label: 'Food',
            text: dose.safeFoodWindowNote,
          ),
          const SizedBox(height: 20),

          // Ask AI about dose
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                AiConsultationSheet.show(
                  context,
                  state,
                  focusMedication: dose.medicationName,
                  initialQuestion: 'Why is ${dose.medicationName} (${dose.dosage}) scheduled at ${dose.formattedTime}?',
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 14),
              label: Text('Ask AI about ${dose.medicationName}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ChronoTheme.primary,
                side: BorderSide(color: ChronoTheme.primary.withOpacity(0.35)),
                backgroundColor: ChronoTheme.primary.withOpacity(0.06),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Missed/delayed protocol
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                MissedDoseProtocolSheet.show(context, dose, state);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ChronoTheme.textSecondary,
                side: const BorderSide(color: ChronoTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
                ),
              ),
              child: const Text(
                'Missed or delayed? View protocol',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),

          if (!isTaken) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  state.markDoseTaken(dose.medicationId);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChronoTheme.secondary,
                  foregroundColor: ChronoTheme.obsidian,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Mark as Taken',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetDetailRow extends StatelessWidget {
  final String label;
  final String text;

  const _SheetDetailRow({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: ChronoTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: ChronoTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 24h Circadian Map View (migrated from timeline_screen.dart) ───────────────

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
    final targetOffset =
        (widget.state.currentMinuteOfDay / 1440.0) * 1680.0 - 150.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _onCanvasTap(TapUpDetails details) {
    const heightPerMinute = 1680.0 / 1440.0;
    const gutterWidth = 52.0;
    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy + _scrollController.offset;

    if (tapX < gutterWidth) return;

    for (final dose in widget.state.doses) {
      final doseY = dose.scheduledMinute * heightPerMinute;
      if ((tapY - doseY).abs() < 28) {
        setState(() => _selectedDose = dose);
        _showDoseSheet(dose);
        return;
      }
    }
  }

  void _showDoseSheet(ScheduledDose dose) {
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
        // Legend
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: ChronoTheme.surface,
          child: const Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _LegendDot(color: ChronoTheme.secondary,     label: 'Meal window'),
              _LegendDot(color: ChronoTheme.rose,          label: 'Fasting buffer'),
              _LegendDot(color: ChronoTheme.primary,       label: 'Scheduled dose'),
              _LegendDot(color: ChronoTheme.textMuted,     label: 'Sleep zone'),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTapUp: _onCanvasTap,
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

// ── Conflict View ─────────────────────────────────────────────────────────────

class _ConflictView extends StatelessWidget {
  final AppState state;
  const _ConflictView({required this.state});

  @override
  Widget build(BuildContext context) {
    final conflict = state.conflict!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceCard,
          borderRadius: BorderRadius.circular(ChronoTheme.radiusLarge),
          border: Border.all(color: ChronoTheme.rose.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: ChronoTheme.rose, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule Conflict',
                        style: TextStyle(
                          color: ChronoTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        conflict.errorCode,
                        style: const TextStyle(
                          color: ChronoTheme.rose,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (conflict.conflictingMedications.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: conflict.conflictingMedications
                    .map((med) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: ChronoTheme.roseSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ChronoTheme.rose.withOpacity(0.25)),
                          ),
                          child: Text(
                            med,
                            style: const TextStyle(
                              color: ChronoTheme.rose,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 12),
            Text(
              conflict.clinicalExplanation,
              style: const TextStyle(
                color: ChronoTheme.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChronoTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ChronoTheme.border),
              ),
              child: Text(
                conflict.actionableAdvice,
                style: const TextStyle(
                  color: ChronoTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 18),
            const Divider(color: ChronoTheme.border, height: 1),
            const SizedBox(height: 14),

            const Text(
              'Quick resolutions',
              style: TextStyle(
                color: ChronoTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            _ResolutionTile(
              icon: Icons.more_time_rounded,
              label: 'Extend bedtime by 60 minutes',
              onTap: () {
                final r = state.routine;
                final newSleep = (r.sleepTimeMinutes + 60).clamp(0, 1439);
                state.updateRoutine(Routine(
                  id: r.id,
                  userId: r.userId,
                  wakeTimeMinutes: r.wakeTimeMinutes,
                  sleepTimeMinutes: newSleep,
                  meals: r.meals,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bedtime extended by 60 min. Recomputing schedule...'),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _ResolutionTile(
              icon: Icons.restore_rounded,
              label: 'Restore reference regimen',
              onTap: () {
                state.reset(
                  defaultRoutine: defaultRoutine,
                  defaultMedications: defaultMedications,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restored reference 6-drug regimen.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolutionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ResolutionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ChronoTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: ChronoTheme.primary, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: ChronoTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: ChronoTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
