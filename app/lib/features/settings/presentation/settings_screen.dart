import 'package:flutter/material.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';
import '../../../main.dart' show defaultRoutine, defaultMedications;
import '../../medications/presentation/interaction_matrix_sheet.dart';
import 'physician_summary_sheet.dart';

/// Phase 6: Elevated Clinical Settings & Engine Telemetry Screen
///
/// Implements Calm Health design principles:
/// - Real-Time Deterministic Engine Telemetry (Latency, Prescriptions, Adherence).
/// - Dynamic Simulation Lab (Overslept +2h 15m with toggle & live reset).
/// - Zero-Hallucination Clinical Mandate Architecture.
/// - Symmetrical System Specifications & Build Telemetry.
/// - Zero cartoon emojis; pure medical-grade vector outline icons.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            // Symmetrical Header
            const _SettingsHeader(),

            // Scrollable Settings Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 48),
                children: [
                  // Section 1: Real-Time Engine Telemetry
                  const _SectionHeader(
                    title: 'ENGINE TELEMETRY',
                    subtitle: 'Deterministic CSP solver metrics',
                    icon: Icons.speed_rounded,
                  ),
                  const SizedBox(height: 10),
                  _TelemetryMetricsCard(state: state),

                  const SizedBox(height: 24),

                  // Section 2: Clinical Simulation Lab
                  const _SectionHeader(
                    title: 'SIMULATION LAB',
                    subtitle: 'Test dynamic schedule recalibration',
                    icon: Icons.science_outlined,
                  ),
                  const SizedBox(height: 10),
                  _OversleptSimulatorCard(state: state),
                  const SizedBox(height: 10),
                  _ResetRegimenCard(onReset: () => _confirmReset(context, state)),

                  const SizedBox(height: 24),

                  // Section 3: Physician Care Handoff
                  const _SectionHeader(
                    title: 'PHYSICIAN CARE HANDOFF',
                    subtitle: 'Clinical summary for doctors & pharmacists',
                    icon: Icons.assignment_outlined,
                  ),
                  const SizedBox(height: 10),
                  _PhysicianExportCard(
                    onTap: () => PhysicianSummarySheet.show(context, state),
                  ),

                  const SizedBox(height: 24),

                  // Section 4: Pharmacokinetic Safety Matrix
                  const _SectionHeader(
                    title: 'PHARMACOKINETIC SAFETY MATRIX',
                    subtitle: 'Pairwise chelation & bioavailability audit',
                    icon: Icons.hub_outlined,
                  ),
                  const SizedBox(height: 10),
                  _SafetyMatrixSettingsCard(
                    onTap: () => InteractionMatrixSheet.show(context, state),
                  ),

                  const SizedBox(height: 24),

                  // Section 5: Zero-Hallucination Clinical Mandate
                  const _SectionHeader(
                    title: 'CLINICAL SAFETY MANDATE',
                    subtitle: 'Deterministic guarantees vs AI hallucination',
                    icon: Icons.verified_user_outlined,
                  ),
                  const SizedBox(height: 10),
                  const _ClinicalSafetyCard(),

                  const SizedBox(height: 24),

                  // Section 4: Architecture Specifications
                  const _SectionHeader(
                    title: 'SYSTEM SPECIFICATIONS',
                    subtitle: 'Runtime build & algorithm configuration',
                    icon: Icons.terminal_rounded,
                  ),
                  const SizedBox(height: 10),
                  const _SystemSpecsCard(),
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
          'Restore Default Regimen?',
          style: TextStyle(
            color: ChronoTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: const Text(
          'This will remove all custom medications, restore the reference 6-drug clinical polypharmacy regimen, and reset routine anchors.',
          style: TextStyle(
            color: ChronoTheme.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: ChronoTheme.textSecondary),
            ),
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
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: ChronoTheme.secondary, size: 18),
                      SizedBox(width: 8),
                      Text('Regimen restored to clinical defaults.'),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChronoTheme.rose,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Reset Regimen'),
          ),
        ],
      ),
    );
  }
}

// ── Symmetrical Header ────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

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
                'Settings & Engine',
                style: TextStyle(
                  color: ChronoTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Deterministic CSP engine & safety telemetry',
                style: TextStyle(
                  color: ChronoTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ChronoTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ChronoTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: ChronoTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'AOT ENGINE ONLINE',
                  style: TextStyle(
                    color: ChronoTheme.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
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

// ── Telemetry Metrics Card ───────────────────────────────────────────────────

class _TelemetryMetricsCard extends StatelessWidget {
  final AppState state;
  const _TelemetryMetricsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final solveMs = state.lastSolveDurationMs;
    final medCount = state.medications.length;
    final adherencePct = (state.adherenceRatio * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronoTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _TelemetryMetricTile(
                  label: 'SOLVE LATENCY',
                  value: '${solveMs}ms',
                  valueColor: ChronoTheme.primary,
                  icon: Icons.bolt_rounded,
                  caption: '< 15ms target',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TelemetryMetricTile(
                  label: 'ACTIVE DRUGS',
                  value: '$medCount',
                  valueColor: ChronoTheme.textPrimary,
                  icon: Icons.medication_outlined,
                  caption: 'In memory',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TelemetryMetricTile(
                  label: 'ADHERENCE',
                  value: '$adherencePct%',
                  valueColor: adherencePct >= 80
                      ? ChronoTheme.secondary
                      : ChronoTheme.primary,
                  icon: Icons.check_circle_outline_rounded,
                  caption: 'Today ratio',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: ChronoTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.memory_rounded,
                  size: 13,
                  color: ChronoTheme.secondary,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Deterministic backtracking solver executes with 0ms network latency.',
                    style: TextStyle(
                      color: ChronoTheme.textSecondary,
                      fontSize: 11,
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
}

class _TelemetryMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final String caption;

  const _TelemetryMetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChronoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: valueColor),
              const SizedBox(width: 5),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: ChronoTheme.monoFont,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(
              color: ChronoTheme.textDim,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overslept Simulator Card ──────────────────────────────────────────────────

class _OversleptSimulatorCard extends StatelessWidget {
  final AppState state;
  const _OversleptSimulatorCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final isOverslept = state.isOversleptMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverslept
              ? ChronoTheme.primary.withOpacity(0.5)
              : ChronoTheme.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOverslept
                  ? ChronoTheme.cyanSurface
                  : ChronoTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isOverslept
                    ? ChronoTheme.primary
                    : ChronoTheme.border,
              ),
            ),
            child: Icon(
              Icons.alarm_add_rounded,
              color: isOverslept ? ChronoTheme.primary : ChronoTheme.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Simulate Overslept Routine',
                      style: TextStyle(
                        color: ChronoTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOverslept
                            ? ChronoTheme.cyanSurface
                            : ChronoTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOverslept
                              ? ChronoTheme.primary
                              : ChronoTheme.borderSubtle,
                        ),
                      ),
                      child: Text(
                        isOverslept ? '+2h 15m ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          color: isOverslept
                              ? ChronoTheme.primary
                              : ChronoTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Delays waking by 2h 15m. DynamicRecalibrator cascades meal and dose times forward to preserve separation constraints.',
                  style: TextStyle(
                    color: ChronoTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    state.simulateOverslept();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              isOverslept
                                  ? Icons.restore_rounded
                                  : Icons.alarm_on_rounded,
                              color: ChronoTheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOverslept
                                  ? 'Restored standard routine schedule.'
                                  : 'Overslept (+2h 15m) applied. Schedule shifted.',
                            ),
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
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isOverslept
                          ? ChronoTheme.surfaceElevated
                          : ChronoTheme.cyanSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOverslept
                            ? ChronoTheme.border
                            : ChronoTheme.primary.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOverslept
                              ? Icons.restore_rounded
                              : Icons.play_arrow_rounded,
                          size: 15,
                          color: ChronoTheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOverslept
                              ? 'Restore Standard Schedule'
                              : 'Trigger Late Wake-up (+2h 15m)',
                          style: const TextStyle(
                            color: ChronoTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
}

// ── Reset Regimen Card ────────────────────────────────────────────────────────

class _ResetRegimenCard extends StatelessWidget {
  final VoidCallback onReset;
  const _ResetRegimenCard({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onReset,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ChronoTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ChronoTheme.roseSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ChronoTheme.rose.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.restore_page_outlined,
                color: ChronoTheme.rose,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reset to Reference Regimen',
                    style: TextStyle(
                      color: ChronoTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Restores default 6-medication schedule & resets anchors',
                    style: TextStyle(
                      color: ChronoTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: ChronoTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Clinical Safety Mandate Card ──────────────────────────────────────────────

class _ClinicalSafetyCard extends StatelessWidget {
  const _ClinicalSafetyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronoTheme.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                color: ChronoTheme.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Zero-Hallucination Mandate',
                style: TextStyle(
                  color: ChronoTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Large Language Models (LLMs) are strictly forbidden from calculating medication '
            'timings, meal buffers, or drug-drug interactions. ChronoMed runs 100% deterministic, '
            'symbolic constraint-satisfaction algorithms verified by FDA-cited clinical rules.',
            style: TextStyle(
              color: ChronoTheme.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SafetyPill(label: 'Deterministic CSP', color: ChronoTheme.primary),
              _SafetyPill(label: 'FDA Clinical Grounding', color: ChronoTheme.secondary),
              _SafetyPill(label: 'Zero LLM Math', color: ChronoTheme.rose),
              _SafetyPill(label: '100% Offline-First', color: ChronoTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _SafetyPill extends StatelessWidget {
  final String label;
  final Color color;
  const _SafetyPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color == ChronoTheme.textSecondary
                  ? ChronoTheme.textPrimary
                  : color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── System Specifications Card ────────────────────────────────────────────────

class _SystemSpecsCard extends StatelessWidget {
  const _SystemSpecsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ChronoTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ChronoTheme.border),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: ChronoTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ChronoMed Health System',
                    style: TextStyle(
                      color: ChronoTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'v1.0.0 · Multi-Platform (Web, Android, Desktop)',
                    style: TextStyle(
                      color: ChronoTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: ChronoTheme.border, height: 1),
          const SizedBox(height: 10),
          const _SpecRow(label: 'Engine Runtime', value: 'Pure Dart 3.5 AOT'),
          const _SpecRow(label: 'Algorithm', value: 'Backtracking CSP + MRV'),
          const _SpecRow(label: 'Solve Latency', value: '< 15ms target (~7ms)'),
          const _SpecRow(label: 'FDA Drug Profiles', value: '50 Indexed Molecules'),
          const _SpecRow(label: 'Cation Chelation Gap', value: '≥ 240 min (Ca²⁺/Fe²⁺)'),
          const _SpecRow(label: 'Fasting Pre-Meal Buffer', value: '≥ 60 min'),
          const _SpecRow(label: 'Fasting Post-Meal Buffer', value: '≥ 120 min'),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ChronoTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: ChronoTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: ChronoTheme.monoFont,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Physician Export Card ─────────────────────────────────────────────────────

class _PhysicianExportCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PhysicianExportCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronoTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ChronoTheme.cyanSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ChronoTheme.primary.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: ChronoTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Physician Regimen Summary',
                              style: TextStyle(
                                color: ChronoTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ChronoTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'EHR Ready',
                              style: TextStyle(
                                color: ChronoTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Generate an EHR-ready, structured Markdown report with circadian anchors, prandial rules, chelation buffers, and zero-hallucination verification.',
                        style: TextStyle(
                          color: ChronoTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Text(
                            'View & Export Report',
                            style: TextStyle(
                              color: ChronoTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: ChronoTheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Safety Matrix Settings Card ───────────────────────────────────────────────

class _SafetyMatrixSettingsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SafetyMatrixSettingsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronoTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ChronoTheme.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ChronoTheme.secondary.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.hub_outlined,
                    color: ChronoTheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Pharmacokinetic Safety Matrix',
                              style: TextStyle(
                                color: ChronoTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ChronoTheme.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '100% Guarded',
                              style: TextStyle(
                                color: ChronoTheme.secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Audit pairwise chelation separation gaps, absorption competition, and chronobiological peak alignments for your active polypharmacy regimen.',
                        style: TextStyle(
                          color: ChronoTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Text(
                            'Open Interactive Safety Matrix',
                            style: TextStyle(
                              color: ChronoTheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: ChronoTheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


