import 'package:flutter/material.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';
import '../../../main.dart' show defaultRoutine, defaultMedications;

/// Settings & About screen.
/// Exposes: overslept simulation, reset to defaults, engine stats, guardrails info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: Column(
        children: [
          _SettingsHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                // Engine Stats
                _SectionTitle('Engine Telemetry'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChronoTheme.metricTile(
                        label: 'LAST SOLVE',
                        value: '${state.lastSolveDurationMs}ms',
                        valueColor: ChronoTheme.cyan,
                        icon: Icons.speed_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChronoTheme.metricTile(
                        label: 'MEDICATIONS',
                        value: '${state.medications.length}',
                        valueColor: ChronoTheme.textPrimary,
                        icon: Icons.medication_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChronoTheme.metricTile(
                        label: 'ADHERENCE',
                        value: '${(state.adherenceRatio * 100).round()}%',
                        valueColor: state.adherenceRatio >= 0.8
                            ? ChronoTheme.emerald
                            : ChronoTheme.amber,
                        icon: Icons.bar_chart_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Simulation Tools
                _SectionTitle('Simulation Tools'),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.alarm_add_rounded,
                  iconColor: ChronoTheme.amber,
                  title: 'Simulate: I Overslept (+2h 15m)',
                  subtitle:
                      'Triggers DynamicRecalibrator — shifts all downstream doses to preserve separation windows.',
                  onTap: () {
                    state.simulateOverslept();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Overslept simulation applied. Check Today & Timeline tabs.'),
                        backgroundColor: ChronoTheme.amber,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.refresh_rounded,
                  iconColor: ChronoTheme.rose,
                  title: 'Reset to Default Regimen',
                  subtitle:
                      'Restores the default 6-medication schedule and clears all customizations.',
                  onTap: () => _confirmReset(context, state),
                ),
                const SizedBox(height: 28),

                // Zero-Hallucination Mandate
                _SectionTitle('Clinical Safety'),
                const SizedBox(height: 12),
                _GuardrailsCard(),
                const SizedBox(height: 28),

                // About
                _SectionTitle('About ChronoMed'),
                const SizedBox(height: 12),
                _AboutCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ChronoTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset to Defaults',
            style: TextStyle(color: ChronoTheme.textPrimary)),
        content: const Text(
          'This will remove all custom medications and restore the default polypharmacy regimen. Continue?',
          style: TextStyle(color: ChronoTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: ChronoTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              state.reset(
                defaultRoutine: defaultRoutine,
                defaultMedications: defaultMedications,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset complete.'),
                  backgroundColor: ChronoTheme.emerald,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChronoTheme.rose,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: ChronoTheme.surface,
        border: Border(bottom: BorderSide(color: ChronoTheme.border)),
      ),
      child: const Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings',
                  style: TextStyle(
                      color: ChronoTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Text('Engine telemetry, simulation tools & clinical info',
                  style: TextStyle(color: ChronoTheme.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: ChronoTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ChronoTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: iconColor.withOpacity(0.25)),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: ChronoTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: ChronoTheme.textMuted,
                          fontSize: 12,
                          height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: ChronoTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _GuardrailsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChronoTheme.rose.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronoTheme.rose.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel_rounded, color: ChronoTheme.rose, size: 18),
              SizedBox(width: 8),
              Text(
                'Zero-Hallucination Mandate',
                style: TextStyle(
                    color: ChronoTheme.rose,
                    fontWeight: FontWeight.w800,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Large Language Models (LLMs) are strictly forbidden from '
            'calculating medication timings or drug-drug interactions. '
            'All scheduling is 100% deterministic, symbolic constraint-satisfaction code — '
            'verified by FDA-cited clinical constants.',
            style: TextStyle(
                color: ChronoTheme.textSecondary, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ChronoTheme.badge('CSP SOLVER', ChronoTheme.cyan),
              ChronoTheme.badge('FDA CONSTANTS', ChronoTheme.emerald),
              ChronoTheme.badge('ZERO LLM', ChronoTheme.rose),
              ChronoTheme.badge('OFFLINE-FIRST', ChronoTheme.violet),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ChronoTheme.cyan, ChronoTheme.emerald],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medical_services_rounded,
                    color: ChronoTheme.obsidian, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ChronoMed',
                      style: TextStyle(
                          color: ChronoTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  Text('v1.0.0 · Flutter Windows Desktop',
                      style:
                          TextStyle(color: ChronoTheme.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: ChronoTheme.border),
          const SizedBox(height: 12),
          _AboutRow(label: 'Engine', value: 'Pure Dart 3.5 AOT'),
          _AboutRow(label: 'Algorithm', value: 'CSP Backtracking + MRV'),
          _AboutRow(label: 'Solve Time', value: '~7ms measured'),
          _AboutRow(label: 'Drug Library', value: '50 FDA Profiles'),
          _AboutRow(label: 'Chelation Gap', value: '≥ 240 minutes'),
          _AboutRow(label: 'Fasting Pre-Meal', value: '≥ 60 minutes'),
          _AboutRow(label: 'Fasting Post-Meal', value: '≥ 120 minutes'),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: ChronoTheme.textMuted, fontSize: 12)),
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
