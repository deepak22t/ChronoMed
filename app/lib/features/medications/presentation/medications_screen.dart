import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';
import 'add_medication_dialog.dart';

/// Medications management screen (Mobile-First).
class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final meds = state.medications;

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: Column(
        children: [
          _MedsHeader(count: meds.length),
          Expanded(
            child: meds.isEmpty
                ? const _EmptyMedsPlaceholder()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: meds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _MedicationCard(med: meds[i], state: state),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, state),
        backgroundColor: ChronoTheme.cyan,
        foregroundColor: ChronoTheme.obsidian,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Medication',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ChronoTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddMedicationSheet(onAdd: state.addMedication),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _MedsHeader extends StatelessWidget {
  final int count;
  const _MedsHeader({required this.count});

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
                'Medication Regimen',
                style: TextStyle(
                  color: ChronoTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pharmacokinetic rules & constraints',
                style: TextStyle(color: ChronoTheme.textDim, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          ChronoTheme.badge('$count ACTIVE', ChronoTheme.cyan),
        ],
      ),
    );
  }
}

// ── Medication Card ──────────────────────────────────────────────────────────

class _MedicationCard extends StatelessWidget {
  final Medication med;
  final AppState state;

  const _MedicationCard({required this.med, required this.state});

  @override
  Widget build(BuildContext context) {
    final rules = med.rules;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ChronoTheme.cyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ChronoTheme.cyan.withOpacity(0.25)),
                ),
                child: const Icon(Icons.medication_rounded,
                    color: ChronoTheme.cyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(
                        color: ChronoTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      med.dosage,
                      style: const TextStyle(
                        color: ChronoTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: ChronoTheme.rose, size: 20),
                tooltip: 'Remove',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (rules.requiresEmptyStomach)
                ChronoTheme.badge('EMPTY STOMACH', ChronoTheme.rose),
              if (rules.requiresFood)
                ChronoTheme.badge('WITH FOOD', ChronoTheme.emerald),
              if (rules.circadianPreference != CircadianWindow.anyTime)
                ChronoTheme.badge(
                  rules.circadianPreference.displayName.toUpperCase(),
                  ChronoTheme.violet,
                ),
              if (rules.separationConstraints.isNotEmpty)
                ChronoTheme.badge(
                  '${rules.separationConstraints.length} CATION GAP',
                  ChronoTheme.amber,
                ),
            ],
          ),
          if (rules.separationConstraints.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...rules.separationConstraints.map(
              (c) => Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ChronoTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: ChronoTheme.amber, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '≥ ${c.minimumSeparationMinutes}m from ${c.targetIdentifier}',
                        style: const TextStyle(
                            color: ChronoTheme.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChronoTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Medication?',
            style: TextStyle(color: ChronoTheme.textPrimary)),
        content: Text(
          'Remove ${med.name} from your regimen? Schedule will automatically recalculate.',
          style: const TextStyle(color: ChronoTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: ChronoTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.removeMedication(med.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChronoTheme.rose,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyMedsPlaceholder extends StatelessWidget {
  const _EmptyMedsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medication_outlined, size: 56, color: ChronoTheme.textMuted),
          SizedBox(height: 14),
          Text(
            'No medications in regimen.',
            style: TextStyle(color: ChronoTheme.textMuted, fontSize: 15),
          ),
          SizedBox(height: 6),
          Text(
            'Tap "Add Medication" below to search FDA drug library.',
            style: TextStyle(color: ChronoTheme.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
