import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/chrono_theme.dart';

/// Phase 10: Clinical Missed-Dose Protocol & Dynamic Recalibration Advisor
///
/// Provides FDA-grounded missed-dose protocols, pharmacokinetic grace windows,
/// and 1-tap late administration cascade logging with zero cartoon emojis.
class MissedDoseProtocolSheet extends StatelessWidget {
  final ScheduledDose dose;
  final AppState state;

  const MissedDoseProtocolSheet({
    super.key,
    required this.dose,
    required this.state,
  });

  static void show(BuildContext context, ScheduledDose dose, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MissedDoseProtocolSheet(dose: dose, state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final med = state.medications.cast<Medication?>().firstWhere(
          (m) => m?.id == dose.medicationId,
          orElse: () => null,
        );

    final protocol = _getClinicalProtocol(dose.medicationName, med);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Symmetrical Drag Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: ChronoTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ChronoTheme.cyanSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ChronoTheme.primary.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.history_toggle_off_rounded,
                    color: ChronoTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Missed-Dose Protocol',
                        style: TextStyle(
                          color: ChronoTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Pharmacokinetic grace windows & cascading shifts',
                        style: TextStyle(
                          color: ChronoTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: ChronoTheme.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: ChronoTheme.border, height: 1),

          // Body Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Dose Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ChronoTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ChronoTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ChronoTheme.obsidian,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ChronoTheme.border),
                        ),
                        child: Text(
                          dose.formattedTime,
                          style: const TextStyle(
                            color: ChronoTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: ChronoTheme.monoFont,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${dose.medicationName} (${dose.dosage})',
                              style: const TextStyle(
                                color: ChronoTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dose.clinicalInstruction,
                              style: const TextStyle(
                                color: ChronoTheme.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Authoritative Protocol Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ChronoTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ChronoTheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, size: 16, color: ChronoTheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'AUTHORITATIVE PHARMACOKINETIC GUIDANCE',
                            style: TextStyle(
                              color: ChronoTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ChronoTheme.obsidian,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: ChronoTheme.border),
                            ),
                            child: Text(
                              protocol.graceWindow,
                              style: const TextStyle(
                                color: ChronoTheme.secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        protocol.actionRule,
                        style: const TextStyle(
                          color: ChronoTheme.textPrimary,
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        protocol.pharmacologyRationale,
                        style: const TextStyle(
                          color: ChronoTheme.textSecondary,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Interactive Late Dose Logger (Dynamic Recalibrator Trigger)
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 14, color: ChronoTheme.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      'LOG DELAYED CONSUMPTION (CASCADE RECALIBRATION)',
                      style: TextStyle(
                        color: ChronoTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Taking this dose late triggers the CSP solver to push dependent meals and subsequent interacting medications (e.g. chelation buffers) forward.',
                  style: TextStyle(color: ChronoTheme.textMuted, fontSize: 11, height: 1.35),
                ),
                const SizedBox(height: 12),

                // Quick Offset Chips
                Row(
                  children: [
                    Expanded(
                      child: _OffsetChip(
                        label: '+30m Late',
                        onTap: () => _applyLateDose(context, dose.scheduledMinute + 30),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OffsetChip(
                        label: '+60m Late',
                        onTap: () => _applyLateDose(context, dose.scheduledMinute + 60),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OffsetChip(
                        label: '+120m Late',
                        onTap: () => _applyLateDose(context, dose.scheduledMinute + 120),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Golden Rule: Never Double Dose
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ChronoTheme.obsidian,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ChronoTheme.rose.withOpacity(0.35)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: ChronoTheme.rose, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Universal Golden Rule: Never Double Dose',
                              style: TextStyle(
                                color: ChronoTheme.rose,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'If your next scheduled dose is less than 4 hours away, skip the missed dose entirely. Doubling causes supra-therapeutic plasma toxicity.',
                              style: TextStyle(
                                color: ChronoTheme.textSecondary,
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Copy Advisory to Clipboard
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () => _copyProtocol(context, protocol),
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text(
                      'Copy Missed-Dose Advisory to Clipboard',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ChronoTheme.primary,
                      side: BorderSide(color: ChronoTheme.primary.withOpacity(0.35)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _applyLateDose(BuildContext context, int newMinuteOfDay) {
    final clamped = newMinuteOfDay.clamp(0, 1439);
    state.markDoseTakenAt(dose.medicationId, clamped);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sync_rounded, color: ChronoTheme.secondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Logged at ${IntervalMath.formatMinuteOfDay(clamped)}. Subsequent doses dynamically recalibrated.',
                style: const TextStyle(color: ChronoTheme.textPrimary, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: ChronoTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ChronoTheme.border),
        ),
      ),
    );
  }

  void _copyProtocol(BuildContext context, _ClinicalProtocol protocol) {
    final text = 'ChronoMed Missed Dose Guidance for ${dose.medicationName}:\n'
        '• Grace Window: ${protocol.graceWindow}\n'
        '• Clinical Rule: ${protocol.actionRule}\n'
        '• Rationale: ${protocol.pharmacologyRationale}\n'
        '• Golden Mandate: Never double dose.';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Missed dose protocol copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  _ClinicalProtocol _getClinicalProtocol(String name, Medication? med) {
    final lower = name.toLowerCase();

    if (lower.contains('levothyroxine')) {
      return const _ClinicalProtocol(
        graceWindow: '≤ 4 Hours Post-Wake',
        actionRule:
            'If within 4 hours of waking and fasting, take immediately with water. Postpone breakfast/coffee by ≥ 30-60 mins. Delay any Calcium/Iron supplements by +4 hours.',
        pharmacologyRationale:
            'Levothyroxine requires an acidic, fasting gastric environment for enteral absorption. Chelation with multivalent cations destroys bioavailability.',
      );
    }

    if (lower.contains('metformin')) {
      return const _ClinicalProtocol(
        graceWindow: 'With Next Meal',
        actionRule:
            'Take with your next meal or substantial snack. If discovered hours later on an empty stomach, wait until your next meal.',
        pharmacologyRationale:
            'Metformin taken on an empty stomach triggers severe gastrointestinal irritation and nausea. Co-administration with carbohydrates smooths hepatic uptake.',
      );
    }

    if (lower.contains('atorvastatin') || lower.contains('statin')) {
      return const _ClinicalProtocol(
        graceWindow: '≤ 12 Hours to Next Dose',
        actionRule:
            'If missed at bedtime, take upon waking in the morning. However, if less than 12 hours remain until the next bedtime dose, skip and resume tonight.',
        pharmacologyRationale:
            'Long plasma half-life (>14 hours) allows morning catch-up, but taking two doses within 12 hours causes elevated myopathy and rhabdomyolysis risks.',
      );
    }

    if (lower.contains('calcium')) {
      return const _ClinicalProtocol(
        graceWindow: 'With Any Meal',
        actionRule:
            'Take with lunch, dinner, or snack. Never take within 4 hours of morning Levothyroxine.',
        pharmacologyRationale:
            'Calcium carbonate requires gastric acid produced during meals for optimal solubility and elemental calcium dissociation.',
      );
    }

    if (lower.contains('omeprazole')) {
      return const _ClinicalProtocol(
        graceWindow: '30m Pre-Meal',
        actionRule:
            'Take 30–60 minutes before your next major meal. If you have already eaten, wait until 30 minutes before your next meal.',
        pharmacologyRationale:
            'Proton pump inhibitors require active canalicular proton pumps stimulated by food intake to achieve covalent H+/K+ ATPase inhibition.',
      );
    }

    return const _ClinicalProtocol(
      graceWindow: 'Within 50% Dosing Interval',
      actionRule:
          'Take as soon as remembered. If more than half the interval until your next dose has passed, skip and resume regular schedule.',
      pharmacologyRationale:
          'Maintaining steady-state plasma concentrations without crossing supra-therapeutic toxicity thresholds is the primary safety objective.',
    );
  }
}

class _ClinicalProtocol {
  final String graceWindow;
  final String actionRule;
  final String pharmacologyRationale;

  const _ClinicalProtocol({
    required this.graceWindow,
    required this.actionRule,
    required this.pharmacologyRationale,
  });
}

class _OffsetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OffsetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ChronoTheme.primary.withOpacity(0.35)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: ChronoTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
