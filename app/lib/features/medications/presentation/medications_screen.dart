import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';
import '../../settings/presentation/physician_summary_sheet.dart';
import 'add_medication_dialog.dart';

enum _MedFilter { all, emptyStomach, withFood, cationConflict }

/// Phase 4: Symmetrical & Minimalist Medication Cabinet
///
/// Implements Calm Health design principles:
/// - Soothing 2-color palette (Soft Glacial Blue & Muted Sage).
/// - 8-point spatial symmetry (16px margins, 12px gaps, 16px card radius).
/// - Zero cartoon emojis; pure vector outline glyphs.
/// - Clinical detail inspection modal for pharmacokinetic properties.
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

    // Apply search & category filter
    final filteredMeds = allMeds.where((m) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = m.name.toLowerCase().contains(q);
        final matchesDose = m.dosage.toLowerCase().contains(q);
        if (!matchesName && !matchesDose) return false;
      }
      return switch (_selectedFilter) {
        _MedFilter.all => true,
        _MedFilter.emptyStomach => m.rules.requiresEmptyStomach,
        _MedFilter.withFood => m.rules.requiresFood,
        _MedFilter.cationConflict => m.rules.separationConstraints.isNotEmpty,
      };
    }).toList();

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: SafeArea(
        child: Column(
          children: [
            // Symmetrical Header
            _CabinetHeader(
              totalCount: allMeds.length,
              onAddPressed: () => _showAddDialog(context, state),
              onExportPressed: () => PhysicianSummarySheet.show(context, state),
            ),

            // Search & Filter Section
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
                  _FilterChipsRow(
                    selectedFilter: _selectedFilter,
                    onFilterSelected: (filter) =>
                        setState(() => _selectedFilter = filter),
                  ),
                ],
              ),
            ),

            // Medication List
            Expanded(
              child: filteredMeds.isEmpty
                  ? _EmptyCabinetState(
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
                        onTap: () => _showDetailSheet(
                          context,
                          filteredMeds[i],
                          state,
                        ),
                        onDelete: () => _confirmDelete(
                          context,
                          filteredMeds[i],
                          state,
                        ),
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
          'Add Prescription',
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
          'Remove Prescription?',
          style: TextStyle(
            color: ChronoTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Text(
          'Remove ${med.name} (${med.dosage}) from your active regimen? Your daily circadian schedule will re-optimize automatically.',
          style: const TextStyle(
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
              Navigator.pop(ctx);
              state.removeMedication(med.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChronoTheme.rose,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── Symmetrical Cabinet Header ────────────────────────────────────────────────

class _CabinetHeader extends StatelessWidget {
  final int totalCount;
  final VoidCallback onAddPressed;
  final VoidCallback onExportPressed;

  const _CabinetHeader({
    required this.totalCount,
    required this.onAddPressed,
    required this.onExportPressed,
  });

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
                'Prescription Cabinet',
                style: TextStyle(
                  color: ChronoTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pharmacokinetic timing & clinical rules',
                style: TextStyle(
                  color: ChronoTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          // EHR Summary Button
          InkWell(
            onTap: onExportPressed,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ChronoTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ChronoTheme.primary.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 12, color: ChronoTheme.primary),
                  SizedBox(width: 4),
                  Text(
                    'EHR',
                    style: TextStyle(
                      color: ChronoTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                    color: ChronoTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalCount ACTIVE',
                  style: const TextStyle(
                    color: ChronoTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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

// ── Search Bar ───────────────────────────────────────────────────────────────

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
        hintText: 'Search active medications...',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

// ── Filter Chips Row ──────────────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  final _MedFilter selectedFilter;
  final ValueChanged<_MedFilter> onFilterSelected;

  const _FilterChipsRow({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      (_MedFilter.all, 'All'),
      (_MedFilter.emptyStomach, 'Empty Stomach'),
      (_MedFilter.withFood, 'With Food'),
      (_MedFilter.cationConflict, 'Cation Conflict'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((item) {
          final isSelected = selectedFilter == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => onFilterSelected(item.$1),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ChronoTheme.cyanSurface
                      : ChronoTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? ChronoTheme.primary
                        : ChronoTheme.border,
                  ),
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: isSelected
                        ? ChronoTheme.textPrimary
                        : ChronoTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

// ── Symmetrical Medication Card ──────────────────────────────────────────────

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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ChronoTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Glyph + Title/Dose + Detail Chevron
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
                    Icons.medication_outlined,
                    color: ChronoTheme.primary,
                    size: 20,
                  ),
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
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ChronoTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: ChronoTheme.borderSubtle),
                        ),
                        child: Text(
                          med.dosage,
                          style: const TextStyle(
                            color: ChronoTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: ChronoTheme.textSecondary,
                    size: 20,
                  ),
                  tooltip: 'Clinical details',
                  onPressed: onTap,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Symmetrical Clinical Rule Pills (Calm 2-color palette)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Timing Window Pill
                _RulePill(
                  icon: switch (rules.circadianPreference) {
                    CircadianWindow.morning => Icons.wb_sunny_outlined,
                    CircadianWindow.afternoon => Icons.wb_twilight_outlined,
                    CircadianWindow.evening => Icons.nightlight_outlined,
                    CircadianWindow.bedtime => Icons.bedtime_outlined,
                    CircadianWindow.anyTime => Icons.schedule_outlined,
                  },
                  label: rules.circadianPreference.displayName,
                  color: ChronoTheme.primary,
                ),

                // Meal Rule Pill
                if (rules.requiresEmptyStomach)
                  const _RulePill(
                    icon: Icons.no_meals_outlined,
                    label: 'Empty Stomach',
                    color: ChronoTheme.textSecondary,
                  ),
                if (rules.requiresFood)
                  const _RulePill(
                    icon: Icons.restaurant_outlined,
                    label: 'With Food',
                    color: ChronoTheme.secondary,
                  ),

                // Separation Rule Pill
                if (rules.separationConstraints.isNotEmpty)
                  _RulePill(
                    icon: Icons.sync_problem_rounded,
                    label:
                        '≥ ${rules.separationConstraints.first.minimumSeparationMinutes ~/ 60}h Cation Gap',
                    color: ChronoTheme.rose,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rule Pill ─────────────────────────────────────────────────────────────────

class _RulePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RulePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
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

// ── Medication Detail Bottom Sheet ────────────────────────────────────────────

class _MedicationDetailSheet extends StatelessWidget {
  final Medication med;
  final VoidCallback onDelete;

  const _MedicationDetailSheet({
    required this.med,
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

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ChronoTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ChronoTheme.border),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: ChronoTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(
                        color: ChronoTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Strength: ${med.dosage}',
                      style: const TextStyle(
                        color: ChronoTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
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

          const SizedBox(height: 18),
          const Divider(color: ChronoTheme.border, height: 1),
          const SizedBox(height: 16),

          // Pharmacokinetic Attributes List
          const Text(
            'PHARMACOKINETIC PROFILE',
            style: TextStyle(
              color: ChronoTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // Circadian Timing
          _DetailRow(
            icon: Icons.access_time_rounded,
            title: 'Optimal Administration Window',
            value: rules.circadianPreference.displayName,
            subtitle: _getCircadianExplanation(rules.circadianPreference),
            color: ChronoTheme.primary,
          ),
          const SizedBox(height: 10),

          // Prandial Constraint
          _DetailRow(
            icon: rules.requiresEmptyStomach
                ? Icons.no_meals_outlined
                : rules.requiresFood
                    ? Icons.restaurant_outlined
                    : Icons.check_circle_outline_rounded,
            title: 'Meal Timing Requirement',
            value: rules.requiresEmptyStomach
                ? 'Empty Stomach Required'
                : rules.requiresFood
                    ? 'Take With Food'
                    : 'Flexible (No Meal Constraint)',
            subtitle: rules.requiresEmptyStomach
                ? 'Fasting required: ≥ 60m pre-meal or ≥ 120m post-meal to avoid absorption inhibition.'
                : rules.requiresFood
                    ? 'Co-administration with dietary lipids or carbohydrates enhances bioavailability.'
                    : 'Bioavailability is stable regardless of gastric fullness.',
            color: rules.requiresEmptyStomach
                ? ChronoTheme.textSecondary
                : rules.requiresFood
                    ? ChronoTheme.secondary
                    : ChronoTheme.primary,
          ),

          // Separation Constraints / Chelation
          if (rules.separationConstraints.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...rules.separationConstraints.map(
              (c) => _DetailRow(
                icon: Icons.sync_problem_rounded,
                title: 'Chelation Separation: ${c.targetIdentifier}',
                value: '≥ ${c.minimumSeparationMinutes} min mandatory gap',
                subtitle: c.clinicalRationale,
                color: ChronoTheme.rose,
              ),
            ),
          ],

          const SizedBox(height: 22),

          // Remove Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text(
                'Remove Prescription from Cabinet',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ChronoTheme.rose,
                side: BorderSide(color: ChronoTheme.rose.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCircadianExplanation(CircadianWindow window) {
    return switch (window) {
      CircadianWindow.morning =>
        'Cortisol & diurnal metabolic peak optimize therapeutic uptake.',
      CircadianWindow.bedtime =>
        'Aligns with nocturnal hepatic enzyme synthesis (e.g. HMG-CoA reductase).',
      CircadianWindow.afternoon =>
        'Avoids morning cation competition while maintaining therapeutic serum levels.',
      CircadianWindow.evening =>
        'Synchronized with nocturnal blood pressure dipping and circadian rest.',
      CircadianWindow.anyTime =>
        'Consistent 24-hour therapeutic window with no circadian peak sensitivity.',
    };
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ChronoTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: ChronoTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: ChronoTheme.textMuted,
                    fontSize: 11,
                    height: 1.3,
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

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyCabinetState extends StatelessWidget {
  final bool hasQuery;
  final VoidCallback onResetFilters;

  const _EmptyCabinetState({
    required this.hasQuery,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ChronoTheme.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: ChronoTheme.border),
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 28,
                color: ChronoTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No matching prescriptions' : 'Cabinet is Empty',
              style: const TextStyle(
                color: ChronoTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'No medications matched your filter criteria.'
                  : 'Add your medications to compute an optimal circadian schedule.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ChronoTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (hasQuery) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onResetFilters,
                child: const Text(
                  'Reset Filters',
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
