import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:core_engine/core_engine.dart';
import 'package:clinical_data/clinical_data.dart';
import '../../../core/theme/chrono_theme.dart';

/// Mobile BottomSheet for adding a new medication.
class AddMedicationSheet extends StatefulWidget {
  final void Function(Medication) onAdd;
  const AddMedicationSheet({super.key, required this.onAdd});

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  final _searchController = TextEditingController();
  final _dosageController = TextEditingController();
  final _nameController = TextEditingController();

  DrugRegistry? _registry;
  bool _registryLoading = true;

  Medication? _selectedDrug;
  CircadianWindow _circadian = CircadianWindow.anyTime;
  bool _requiresEmptyStomach = false;
  bool _requiresFood = false;
  bool _hasCationConflict = false;

  @override
  void initState() {
    super.initState();
    _loadRegistry();
  }

  Future<void> _loadRegistry() async {
    try {
      final json = await rootBundle.loadString('assets/top_50_drugs.json');
      final reg = DrugRegistry()..loadFromJsonString(json);
      if (mounted) {
        setState(() {
          _registry = reg;
          _registryLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _registryLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (query.length < 2 || _registry == null) return;
    final found = _registry!.findByQuery(query);
    if (found == null) return;
    setState(() {
      _selectedDrug = found;
      _nameController.text = found.name;
      _dosageController.text = found.dosage;
      _requiresEmptyStomach = found.rules.requiresEmptyStomach;
      _requiresFood = found.rules.requiresFood;
      _circadian = found.rules.circadianPreference;
      _hasCationConflict = found.rules.separationConstraints.isNotEmpty;
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();
    if (name.isEmpty || dosage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter medication name and dosage.'),
          backgroundColor: ChronoTheme.rose,
        ),
      );
      return;
    }

    final separationConstraints = <DrugSeparationConstraint>[
      if (_hasCationConflict) ...[
        const DrugSeparationConstraint(
          targetIdentifier: 'Calcium Carbonate',
          minimumSeparationMinutes: 240,
          clinicalRationale: 'Polyvalent cation chelation reduces absorption',
        ),
        const DrugSeparationConstraint(
          targetIdentifier: 'Ferrous Sulfate',
          minimumSeparationMinutes: 240,
          clinicalRationale: 'Iron chelation complex reduces bioavailability',
        ),
      ],
    ];

    final med = Medication(
      id: 'med_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      dosage: dosage,
      rules: PharmacokineticRule(
        requiresEmptyStomach: _requiresEmptyStomach && !_requiresFood,
        requiresFood: _requiresFood && !_requiresEmptyStomach,
        circadianPreference: _circadian,
        separationConstraints: separationConstraints,
      ),
    );

    widget.onAdd(med);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
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
            // Title
            Row(
              children: [
                const Icon(Icons.medication_rounded, color: ChronoTheme.cyan, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Add Medication',
                  style: TextStyle(
                    color: ChronoTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: ChronoTheme.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextFormField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: ChronoTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search 50 FDA drugs (e.g. Metformin)...',
                prefixIcon: const Icon(Icons.search_rounded, color: ChronoTheme.textMuted, size: 18),
                suffixIcon: _registryLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: ChronoTheme.cyan)),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            if (_selectedDrug != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ChronoTheme.emerald.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ChronoTheme.emerald.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: ChronoTheme.emerald, size: 14),
                    SizedBox(width: 6),
                    Text('Auto-filled from drug library', style: TextStyle(color: ChronoTheme.emerald, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            // Med Name
            const _Label('Medication Name *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: ChronoTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'e.g. Metformin',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),

            // Dosage
            const _Label('Dosage *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _dosageController,
              style: const TextStyle(color: ChronoTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'e.g. 500 mg, 50 mcg',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Toggles
            const _Label('Clinical Timing Rules'),
            const SizedBox(height: 8),
            _MobileRuleSwitch(
              label: 'Empty Stomach',
              subtitle: '60m before / 120m after meals',
              color: ChronoTheme.rose,
              value: _requiresEmptyStomach && !_requiresFood,
              onChanged: (v) => setState(() {
                _requiresEmptyStomach = v;
                if (v) _requiresFood = false;
              }),
            ),
            const SizedBox(height: 6),
            _MobileRuleSwitch(
              label: 'Requires Food',
              subtitle: 'Must be taken with a meal',
              color: ChronoTheme.emerald,
              value: _requiresFood && !_requiresEmptyStomach,
              onChanged: (v) => setState(() {
                _requiresFood = v;
                if (v) _requiresEmptyStomach = false;
              }),
            ),
            const SizedBox(height: 6),
            _MobileRuleSwitch(
              label: 'Cation Conflict (Ca²⁺/Fe²⁺)',
              subtitle: '≥ 4h gap from Calcium & Iron',
              color: ChronoTheme.amber,
              value: _hasCationConflict,
              onChanged: (v) => setState(() => _hasCationConflict = v),
            ),
            const SizedBox(height: 12),

            // Circadian Window
            const _Label('Preferred Time of Day'),
            const SizedBox(height: 6),
            DropdownButtonFormField<CircadianWindow>(
              value: _circadian,
              dropdownColor: ChronoTheme.surfaceElevated,
              style: const TextStyle(color: ChronoTheme.textPrimary, fontSize: 13),
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              items: CircadianWindow.values
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => _circadian = v!),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add to Daily Regimen', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChronoTheme.cyan,
                  foregroundColor: ChronoTheme.obsidian,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dosageController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: ChronoTheme.textDim,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      );
}

class _MobileRuleSwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MobileRuleSwitch({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.08) : ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value ? color.withOpacity(0.35) : ChronoTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: value ? ChronoTheme.textPrimary : ChronoTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: ChronoTheme.textDim, fontSize: 10)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            inactiveThumbColor: ChronoTheme.textDim,
            inactiveTrackColor: ChronoTheme.surfaceElevated,
          ),
        ],
      ),
    );
  }
}
