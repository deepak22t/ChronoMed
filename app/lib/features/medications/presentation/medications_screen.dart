import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';
import 'add_medication_dialog.dart';
import 'interaction_matrix_sheet.dart';

enum _MedFilter { all, emptyStomach, withFood, separationRequired }

/// Medications screen — manage the active medication regimen.
///
/// Simplified: single FAB for add, medication cards without decorative icon
/// squares, filters in plain language, detail sheet focused on clinical facts.
class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _searchController = TextEditingController();
  _MedFilter _selectedFilter = _MedFilter.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final allMeds = state.medications;

    final filteredMeds = allMeds.where((m) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!m.name.toLowerCase().contains(q) &&
            !m.dosage.toLowerCase().contains(q)) return false;
      }
      return switch (_selectedFilter) {
        _MedFilter.all               => true,
        _MedFilter.emptyStomach      => m.rules.requiresEmptyStomach,
        _MedFilter.withFood          => m.rules.requiresFood,
        _MedFilter.separationRequired => m.rules.separationConstraints.isNotEmpty,
      };
    }).toList();

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            _MedsHeader(
              totalCount: allMeds.length,
            ),

            // Search + filters
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  _SearchBar(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                  const SizedBox(height: 10),
                  _FilterRow(
                    selected: _selectedFilter,
                    onSelected: (f) => setState(() => _selectedFilter = f),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: filteredMeds.isEmpty
                  ? _EmptyState(
                      hasQuery: _searchQuery.isNotEmpty ||
                          _selectedFilter != _MedFilter.all,
                      onResetFilters: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _selectedFilter = _MedFilter.all;
                        });
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                      itemCount: filteredMeds.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _MedicationCard(
                        med: filteredMeds[i],
                        onTap: () => _showDetailSheet(context, filteredMeds[i], state),
                        onDelete: () => _confirmDelete(context, filteredMeds[i], state),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, state),
        backgroundColor: ChronoTheme.primary,
        foregroundColor: ChronoTheme.obsidian,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add medication',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMedicationSheet(onAdd: state.addMedication),
    );
  }

  void _showDetailSheet(BuildContext context, Medication med, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedicationDetailSheet(
        med: med,
        onOpenMatrix: () {
          Navigator.pop(context);
          InteractionMatrixSheet.show(context, state);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(context, med, state);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Medication med, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChronoTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ChronoTheme.border),
        ),
        title: const Text(
          'Remove medication?',
          style: TextStyle(
            color: ChronoTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Remove ${med.name} (${med.dosage}) from your regimen. Your schedule will re-optimize automatically.',
          style: const TextStyle(
            color: ChronoTheme.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: ChronoTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.removeMedication(med.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChronoTheme.rose,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _MedsHeader extends StatelessWidget {
  final int totalCount;

  const _MedsHeader({required this.totalCount});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medications',
                  style: TextStyle(
                    color: ChronoTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalCount active',
                  style: const TextStyle(
                    color: ChronoTheme.textSecondary,
                    fontSize: 11,
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

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: ChronoTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search medications...',
        hintStyle: const TextStyle(color: ChronoTheme.textMuted, fontSize: 13),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: ChronoTheme.textSecondary,
          size: 18,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  color: ChronoTheme.textSecondary,
                  size: 16,
                ),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: ChronoTheme.surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChronoTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChronoTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChronoTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final _MedFilter selected;
  final ValueChanged<_MedFilter> onSelected;

  const _FilterRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const filters = [
      (_MedFilter.all,               'All'),
      (_MedFilter.emptyStomach,      'Empty stomach'),
      (_MedFilter.withFood,          'With food'),
      (_MedFilter.separationRequired, 'Separation required'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((item) {
          final isSelected = selected == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelected(item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ChronoTheme.cyanSurface
                      : ChronoTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? ChronoTheme.primary.withOpacity(0.4)
                        : ChronoTheme.border,
                  ),
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: isSelected
                        ? ChronoTheme.primary
                        : ChronoTheme.textMuted,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Medication Card ────────────────────────────────────────────────────────────

class _MedicationCard extends StatelessWidget {
  final Medication med;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.med,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rules = med.rules;
    final timingColor = _timingColor(rules.circadianPreference);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChronoTheme.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceCard,
          borderRadius: BorderRadius.circular(ChronoTheme.radiusLarge),
          border: Border.all(color: ChronoTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar — communicates circadian window with color
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: timingColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(ChronoTheme.radiusLarge),
                  bottomLeft: Radius.circular(ChronoTheme.radiusLarge),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            med.name,
                            style: const TextStyle(
                              color: ChronoTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Text(
                          med.dosage,
                          style: const TextStyle(
                            color: ChronoTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Compact constraint summary — single line, no extra containers
                    Text(
                      _constraintSummary(rules),
                      style: const TextStyle(
                        color: ChronoTheme.textMuted,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _timingColor(CircadianWindow window) {
    return switch (window) {
      CircadianWindow.morning   => ChronoTheme.primary,
      CircadianWindow.bedtime   => ChronoTheme.secondary,
      CircadianWindow.afternoon => ChronoTheme.primary,
      CircadianWindow.evening   => ChronoTheme.secondary,
      CircadianWindow.anyTime   => ChronoTheme.border,
    };
  }

  String _constraintSummary(PharmacokineticRule rules) {
    final parts = <String>[];
    parts.add(rules.circadianPreference.displayName);
    if (rules.requiresEmptyStomach) parts.add('empty stomach');
    if (rules.requiresFood) parts.add('with food');
    if (rules.separationConstraints.isNotEmpty) {
      final mins = rules.separationConstraints.first.minimumSeparationMinutes;
      parts.add('${mins ~/ 60}h separation');
    }
    return parts.join('  ·  ');
  }
}

// ── Medication Detail Sheet ───────────────────────────────────────────────────

class _MedicationDetailSheet extends StatelessWidget {
  final Medication med;
  final VoidCallback onOpenMatrix;
  final VoidCallback onDelete;

  const _MedicationDetailSheet({
    required this.med,
    required this.onOpenMatrix,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rules = med.rules;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Drug name + dosage
          Row(
            children: [
              Expanded(
                child: Text(
                  med.name,
                  style: const TextStyle(
                    color: ChronoTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: ChronoTheme.textSecondary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            med.dosage,
            style: const TextStyle(
              color: ChronoTheme.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 18),
          const Divider(color: ChronoTheme.border, height: 1),
          const SizedBox(height: 14),

          // Clinical attributes — plain rows, no icon containers
          _PlainDetailRow(
            label: 'Timing',
            value: rules.circadianPreference.displayName,
          ),
          const SizedBox(height: 10),
          _PlainDetailRow(
            label: 'Meal',
            value: rules.requiresEmptyStomach
                ? 'Empty stomach required'
                : rules.requiresFood
                    ? 'Take with food'
                    : 'No meal constraint',
          ),

          if (rules.separationConstraints.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...rules.separationConstraints.map(
              (c) => _PlainDetailRow(
                label: 'Separation',
                value: '${c.minimumSeparationMinutes} min gap from ${c.targetIdentifier}',
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onOpenMatrix,
              icon: const Icon(Icons.hub_outlined, size: 16),
              label: const Text(
                'View in Safety Matrix',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ChronoTheme.primary,
                side: BorderSide(color: ChronoTheme.primary.withOpacity(0.35)),
                backgroundColor: ChronoTheme.primary.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text(
                'Remove medication',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ChronoTheme.rose,
                side: BorderSide(color: ChronoTheme.rose.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ChronoTheme.radiusDefault),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _PlainDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: ChronoTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: ChronoTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  final VoidCallback onResetFilters;

  const _EmptyState({required this.hasQuery, required this.onResetFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasQuery ? 'No matching medications' : 'No medications yet',
              style: const TextStyle(
                color: ChronoTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Try a different filter or search term.'
                  : 'Add your first medication using the button below.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ChronoTheme.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (hasQuery) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onResetFilters,
                child: const Text(
                  'Clear filters',
                  style: TextStyle(
                    color: ChronoTheme.primary,
                    fontWeight: FontWeight.w600,
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
