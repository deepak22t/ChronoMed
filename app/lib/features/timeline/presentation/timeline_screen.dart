import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';
import 'timeline_painter.dart';

/// 24-Hour Living Timeline screen (Mobile-First).
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: ChronoTheme.obsidian,
      body: Column(
        children: [
          _TimelineHeader(state: state),
          Expanded(
            child: state.hasConflict
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No timeline — schedule conflict detected.\nCheck the Today tab for details.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ChronoTheme.textMuted, fontSize: 14),
                      ),
                    ),
                  )
                : _LiveTimeline(state: state),
          ),
        ],
      ),
    );
  }
}

// ── Header (Mobile Optimized) ────────────────────────────────────────────────

class _TimelineHeader extends StatelessWidget {
  final AppState state;
  const _TimelineHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: ChronoTheme.surface,
        border: Border(bottom: BorderSide(color: ChronoTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '24h Living Timeline',
                    style: TextStyle(
                      color: ChronoTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Visual circadian & safety windows',
                    style: TextStyle(color: ChronoTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => state.simulateOverslept(),
                icon: const Icon(Icons.alarm_add_rounded, size: 14),
                label: const Text('Simulate +2h', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ChronoTheme.amber,
                  side: const BorderSide(color: ChronoTheme.amber),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Legend Wrap (Never overflows on mobile)
          const Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _LegendDot(color: ChronoTheme.emerald, label: 'Meal Window'),
              _LegendDot(color: Color(0xFFF43F5E), label: 'Fasting Buffer'),
              _LegendDot(color: ChronoTheme.amber, label: 'Medication'),
              _LegendDot(color: Color(0xFF818CF8), label: 'Sleep'),
            ],
          ),
        ],
      ),
    );
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: ChronoTheme.textDim, fontSize: 10)),
      ],
    );
  }
}

// ── Live Timeline Canvas ─────────────────────────────────────────────────────

class _LiveTimeline extends StatefulWidget {
  final AppState state;
  const _LiveTimeline({required this.state});

  @override
  State<_LiveTimeline> createState() => _LiveTimelineState();
}

class _LiveTimelineState extends State<_LiveTimeline> {
  final ScrollController _scrollController = ScrollController();
  ScheduledDose? _selectedDose;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  void _scrollToNow() {
    if (!_scrollController.hasClients) return;
    final targetOffset = (widget.state.currentMinuteOfDay / 1440.0) * 1600.0 - 150.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _onCanvasTap(TapUpDetails details, Size canvasSize) {
    const heightPerMinute = 1600.0 / 1440.0;
    const gutterWidth = 48.0;
    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy + _scrollController.offset;

    if (tapX < gutterWidth) return;

    for (final dose in widget.state.doses) {
      final doseY = dose.scheduledMinute * heightPerMinute;
      if ((tapY - doseY).abs() < 24) {
        setState(() => _selectedDose = dose);
        _showDoseBottomSheet(dose);
        return;
      }
    }
  }

  void _showDoseBottomSheet(ScheduledDose dose) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ChronoTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DoseDetailSheet(
        dose: dose,
        state: widget.state,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        _onCanvasTap(details, renderBox.size);
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SizedBox(
          height: 1600.0,
          child: LayoutBuilder(
            builder: (ctx, constraints) => CustomPaint(
              size: Size(constraints.maxWidth, 1600.0),
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
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Mobile Dose Detail Sheet ─────────────────────────────────────────────────

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
          Row(
            children: [
              Text(
                dose.formattedTime,
                style: const TextStyle(
                  color: ChronoTheme.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: ChronoTheme.monoFont,
                ),
              ),
              const SizedBox(width: 10),
              ChronoTheme.badge(
                isTaken ? 'TAKEN' : 'SCHEDULED',
                isTaken ? ChronoTheme.emerald : ChronoTheme.amber,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${dose.medicationName} (${dose.dosage})',
            style: const TextStyle(
              color: ChronoTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _DetailRow(icon: Icons.info_outline_rounded, color: ChronoTheme.cyan, text: dose.clinicalInstruction),
          const SizedBox(height: 8),
          _DetailRow(icon: Icons.restaurant_menu_rounded, color: ChronoTheme.emerald, text: dose.safeFoodWindowNote),
          const SizedBox(height: 20),
          if (!isTaken)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  state.markDoseTaken(dose.medicationId);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Mark as Taken Now', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChronoTheme.emerald,
                  foregroundColor: ChronoTheme.obsidian,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _DetailRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: ChronoTheme.textSecondary, fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }
}
