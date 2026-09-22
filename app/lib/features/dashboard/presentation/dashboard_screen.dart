import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';

/// Dashboard — Primary "Today" screen (Mobile-First Design).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: Column(
        children: [
          _DashboardHeader(state: state),
          Expanded(
            child: state.hasConflict
                ? _ConflictBanner(conflict: state.conflict!)
                : _DoseListBody(state: state),
          ),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final AppState state;
  const _DashboardHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                    Row(
                      children: [
                        const Text(
                          "Today's Schedule",
                          style: TextStyle(
                            color: ChronoTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (state.isOversleptMode) ...[
                          const SizedBox(width: 8),
                          ChronoTheme.badge('SHIFTED', ChronoTheme.amber),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: ChronoTheme.cyan),
                        const SizedBox(width: 4),
                        Text(
                          IntervalMath.formatMinuteOfDay(state.currentMinuteOfDay),
                          style: const TextStyle(
                            color: ChronoTheme.cyan,
                            fontSize: 13,
                            fontFamily: ChronoTheme.monoFont,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${state.lastSolveDurationMs}ms solver',
                          style: const TextStyle(
                            color: ChronoTheme.textDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _AdherenceRing(
                ratio: state.adherenceRatio,
                taken: state.takenCount,
                total: state.totalDoses,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Compact Metrics Row (Never overflows)
          Row(
            children: [
              Expanded(
                child: _MobileMetricItem(
                  label: 'TAKEN',
                  value: '${state.takenCount} / ${state.totalDoses}',
                  color: ChronoTheme.emerald,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MobileMetricItem(
                  label: 'REMAINING',
                  value: '${state.totalDoses - state.takenCount}',
                  color: ChronoTheme.cyan,
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MobileMetricItem(
                  label: 'ADHERENCE',
                  value: '${(state.adherenceRatio * 100).round()}%',
                  color: state.adherenceRatio >= 0.8
                      ? ChronoTheme.emerald
                      : state.adherenceRatio >= 0.5
                          ? ChronoTheme.amber
                          : ChronoTheme.rose,
                  icon: Icons.donut_large_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MobileMetricItem({
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
        color: ChronoTheme.surfaceCard,
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
              Text(
                label,
                style: const TextStyle(
                  color: ChronoTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: ChronoTheme.monoFont,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Adherence Ring ───────────────────────────────────────────────────────────

class _AdherenceRing extends StatelessWidget {
  final double ratio;
  final int taken;
  final int total;

  const _AdherenceRing({
    required this.ratio,
    required this.taken,
    required this.total,
  });

  Color get _color => ratio >= 0.8
      ? ChronoTheme.emerald
      : ratio >= 0.5
          ? ChronoTheme.amber
          : ChronoTheme.rose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: ratio,
            strokeWidth: 4.5,
            backgroundColor: ChronoTheme.border,
            valueColor: AlwaysStoppedAnimation(_color),
          ),
          Text(
            '$taken/$total',
            style: TextStyle(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: ChronoTheme.monoFont,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Conflict Banner ──────────────────────────────────────────────────────────

class _ConflictBanner extends StatelessWidget {
  final InfeasibleConflict conflict;
  const _ConflictBanner({required this.conflict});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ChronoTheme.rose.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ChronoTheme.rose.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: ChronoTheme.rose, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Clinical Conflict Detected',
              style: TextStyle(color: ChronoTheme.rose, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            ChronoTheme.badge(conflict.errorCode, ChronoTheme.rose),
            const SizedBox(height: 12),
            Text(
              conflict.clinicalExplanation,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ChronoTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChronoTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: ChronoTheme.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      conflict.actionableAdvice,
                      style: const TextStyle(color: ChronoTheme.textSecondary, fontSize: 12, height: 1.3),
                    ),
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

// ── Dose List Body ──────────────────────────────────────────────────────────

class _DoseListBody extends StatelessWidget {
  final AppState state;
  const _DoseListBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final doses = state.doses;
    final nextDose = state.nextDose;

    if (doses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_liquid_outlined, size: 56, color: ChronoTheme.textMuted),
            SizedBox(height: 14),
            Text('No medications scheduled.', style: TextStyle(color: ChronoTheme.textMuted, fontSize: 15)),
            SizedBox(height: 6),
            Text('Add medications on the Meds tab.', style: TextStyle(color: ChronoTheme.textDim, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        if (nextDose != null) ...[
          _HeroDoseCard(dose: nextDose, state: state),
          const SizedBox(height: 20),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TODAY\'S DOSES',
              style: TextStyle(
                color: ChronoTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${doses.length} scheduled',
              style: const TextStyle(color: ChronoTheme.textDim, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...doses.map((d) => _MobileDoseCard(dose: d, state: state)),
      ],
    );
  }
}

// ── Hero Next Dose Card (Mobile-First) ────────────────────────────────────────

class _HeroDoseCard extends StatelessWidget {
  final ScheduledDose dose;
  final AppState state;

  const _HeroDoseCard({required this.dose, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ChronoTheme.cyan.withOpacity(0.12),
            ChronoTheme.emerald.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ChronoTheme.cyan.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChronoTheme.badge('UP NEXT', ChronoTheme.cyan),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ChronoTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ChronoTheme.cyan.withOpacity(0.3)),
                ),
                child: Text(
                  dose.formattedTime,
                  style: const TextStyle(
                    color: ChronoTheme.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: ChronoTheme.monoFont,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dose.medicationName,
            style: const TextStyle(
              color: ChronoTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            dose.dosage,
            style: const TextStyle(color: ChronoTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          // Clinical note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: ChronoTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: ChronoTheme.cyan),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dose.clinicalInstruction,
                    style: const TextStyle(color: ChronoTheme.textSecondary, fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded, size: 13, color: ChronoTheme.emerald),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  dose.safeFoodWindowNote,
                  style: const TextStyle(color: ChronoTheme.emerald, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Mobile Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => state.markDoseTaken(dose.medicationId),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Took It Now', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChronoTheme.emerald,
                    foregroundColor: ChronoTheme.obsidian,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => state.advanceClock(15),
                  icon: const Icon(Icons.snooze_rounded, size: 14),
                  label: const Text('+15m', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ChronoTheme.amber,
                    side: const BorderSide(color: ChronoTheme.amber),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mobile Dose Card ─────────────────────────────────────────────────────────

class _MobileDoseCard extends StatelessWidget {
  final ScheduledDose dose;
  final AppState state;

  const _MobileDoseCard({required this.dose, required this.state});

  Color get _statusColor => switch (dose.status) {
        DoseStatus.taken => ChronoTheme.emerald,
        DoseStatus.missed => ChronoTheme.rose,
        DoseStatus.escalated => ChronoTheme.rose,
        DoseStatus.due => ChronoTheme.cyan,
        DoseStatus.snoozed => ChronoTheme.amber,
        _ => ChronoTheme.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final isTaken = dose.status == DoseStatus.taken;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTaken ? ChronoTheme.surface : ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTaken ? ChronoTheme.border : _statusColor.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () => state.markDoseTaken(dose.medicationId),
        child: Row(
          children: [
            // Left Status Color Strip & Time
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.formattedTime,
                  style: TextStyle(
                    color: isTaken ? ChronoTheme.textDim : ChronoTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: ChronoTheme.monoFont,
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTaken ? 'TAKEN' : dose.status.displayName.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Med Name & Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.medicationName,
                    style: TextStyle(
                      color: isTaken ? ChronoTheme.textMuted : ChronoTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dose.dosage} • ${dose.safeFoodWindowNote}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ChronoTheme.textDim, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Checkbox Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isTaken ? ChronoTheme.emerald.withOpacity(0.15) : ChronoTheme.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTaken ? ChronoTheme.emerald : ChronoTheme.border,
                  width: 1.5,
                ),
              ),
              child: isTaken
                  ? const Icon(Icons.check_rounded, color: ChronoTheme.emerald, size: 18)
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
