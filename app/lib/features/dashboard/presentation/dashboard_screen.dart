import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';

/// Dashboard — Primary "Today" Screen (Calm Health Aesthetic).
///
/// Features a gentle, zero-glare circadian hero overview,
/// high-legibility dose cards, and smooth one-touch checkmark logging.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            _DashboardHeader(state: state),
            Expanded(
              child: state.hasConflict
                  ? _ConflictBanner(conflict: state.conflict!)
                  : _DoseListBody(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 1. Quiet Header ─────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final AppState state;
  const _DashboardHeader({required this.state});

  String _getPhase(int minute) {
    if (minute < 360) return 'Night Rest';
    if (minute < 720) return 'Morning Surge';
    if (minute < 1020) return 'Midday Phase';
    if (minute < 1320) return 'Evening Buffer';
    return 'Bedtime Preparation';
  }

  @override
  Widget build(BuildContext context) {
    final phaseStr = _getPhase(state.currentMinuteOfDay);
    final timeStr = IntervalMath.formatMinuteOfDay(state.currentMinuteOfDay);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: ChronoTheme.surface,
        border: Border(bottom: BorderSide(color: ChronoTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Today',
                      style: TextStyle(
                        color: ChronoTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: ChronoTheme.cyanSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        phaseStr,
                        style: const TextStyle(
                          color: ChronoTheme.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: ChronoTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: ChronoTheme.textMuted,
                        fontSize: 12,
                        fontFamily: ChronoTheme.monoFont,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${state.lastSolveDurationMs}ms solver',
                      style: const TextStyle(color: ChronoTheme.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Symmetrical Adherence Dial
          _AdherenceDial(
            ratio: state.adherenceRatio,
            taken: state.takenCount,
            total: state.totalDoses,
          ),
        ],
      ),
    );
  }
}

class _AdherenceDial extends StatelessWidget {
  final double ratio;
  final int taken;
  final int total;

  const _AdherenceDial({
    required this.ratio,
    required this.taken,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: total > 0 ? ratio : 0.0,
            strokeWidth: 3.5,
            backgroundColor: ChronoTheme.border,
            valueColor: const AlwaysStoppedAnimation(ChronoTheme.secondary),
          ),
          Text(
            '$taken/$total',
            style: const TextStyle(
              color: ChronoTheme.textPrimary,
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

// ── 2. Dose List Body ───────────────────────────────────────────────────────

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
            Icon(Icons.medication_outlined, size: 48, color: ChronoTheme.textMuted),
            SizedBox(height: 12),
            Text(
              'No medications scheduled',
              style: TextStyle(color: ChronoTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text('Add medications in the Meds tab.', style: TextStyle(color: ChronoTheme.textDim, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // 1. Next Dose Calm Hero Banner
        if (nextDose != null) ...[
          _NextDoseHero(dose: nextDose, state: state),
          const SizedBox(height: 18),
        ],

        // 2. Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TODAY\'S DOSES',
              style: TextStyle(
                color: ChronoTheme.textMuted,
                fontSize: 11,
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

        // 3. Dose Cards
        ...doses.map((dose) => _CalmDoseCard(dose: dose, state: state)),
      ],
    );
  }
}

// ── 3. Next Dose Hero Card (Gentle, Restorative) ─────────────────────────────

class _NextDoseHero extends StatelessWidget {
  final ScheduledDose dose;
  final AppState state;

  const _NextDoseHero({required this.dose, required this.state});

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
        border: Border.all(color: ChronoTheme.primary.withOpacity(0.3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: ChronoTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'NEXT SCHEDULED DOSE',
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
                style: const TextStyle(
                  color: ChronoTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Time Capsule
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ChronoTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
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
                      style: const TextStyle(
                        color: ChronoTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dose.safeFoodWindowNote,
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
          const SizedBox(height: 14),
          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => state.markDoseTaken(dose.medicationId),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                  label: const Text('Mark as Taken', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChronoTheme.secondary,
                    foregroundColor: ChronoTheme.obsidian,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () => state.advanceClock(15),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ChronoTheme.textSecondary,
                    side: const BorderSide(color: ChronoTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('+15 min', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 4. Tactile Dose Card (Symmetrical & Clean) ───────────────────────────────

class _CalmDoseCard extends StatelessWidget {
  final ScheduledDose dose;
  final AppState state;

  const _CalmDoseCard({required this.dose, required this.state});

  @override
  Widget build(BuildContext context) {
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
        onTap: () => state.markDoseTaken(dose.medicationId),
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

            // Drug Name & Food Note
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

            // Checkmark Action Circle
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
}

// ── 5. Conflict State ───────────────────────────────────────────────────────

class _ConflictBanner extends StatelessWidget {
  final InfeasibleConflict conflict;
  const _ConflictBanner({required this.conflict});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ChronoTheme.roseSurface,
          borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
          border: Border.all(color: ChronoTheme.rose.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: ChronoTheme.rose, size: 36),
            const SizedBox(height: 10),
            const Text(
              'Clinical Conflict Detected',
              style: TextStyle(color: ChronoTheme.rose, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                conflict.actionableAdvice,
                style: const TextStyle(color: ChronoTheme.textSecondary, fontSize: 12, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
