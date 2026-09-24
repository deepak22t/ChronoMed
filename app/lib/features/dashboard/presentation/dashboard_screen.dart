import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/theme/chrono_theme.dart';
import '../../ai_assistant/presentation/ai_consultation_sheet.dart';

/// ChronoMed Today Screen
///
/// Implements the exact Circadian Rhythm & Biological Daylight Wave design
/// with multi-phase circadian daylight wave, central hour rail, branching connectors,
/// frosted glass dosage cards, and glowing floating action button.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF090D14),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Bar (Cortisol Peak & Harry J.)
                _buildTopAppBar(context, state),

                // Greeting (Good Morning, Harry)
                _buildGreetingHeader(state),

                // Circadian Daylight Wave + Center Rail + Cards
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 90),
                    child: _CircadianDaylightTimeline(state: state),
                  ),
                ),
              ],
            ),

            // Glowing Floating Action Button (Bottom Right)
            Positioned(
              right: 20,
              bottom: 24,
              child: _buildGlowingFab(context, state),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Top Status Bar ───────────────────────────────────────────────────────
  Widget _buildTopAppBar(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Capsule Icon in tilted turquoise
          Transform.rotate(
            angle: -0.7,
            child: Container(
              width: 26,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF2DD4BF),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x662DD4BF),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),

          // Center: Glowing Cortisol Phase Pill
          GestureDetector(
            onTap: () => AiConsultationSheet.show(
              context,
              state,
              initialQuestion: 'Why is the Morning Cortisol Peak important for my medications?',
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0B2129),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2DD4BF).withOpacity(0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2DD4BF).withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Morning Cortisol Peak',
                    style: TextStyle(
                      color: Color(0xFFCCFBF1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '•',
                      style: TextStyle(
                        color: Color(0xFF5EEAD4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    IntervalMath.formatMinuteOfDay(state.currentMinuteOfDay),
                    style: const TextStyle(
                      color: Color(0xFF2DD4BF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: ChronoTheme.monoFont,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: User Profile Avatar
          Row(
            children: [
              const Text(
                'HARRY J.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E293B),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'HJ',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Greeting Header ─────────────────────────────────────────────────────
  Widget _buildGreetingHeader(AppState state) {
    final hour = state.currentMinuteOfDay ~/ 60;
    final greeting = hour < 12
        ? 'Good Morning, Harry.'
        : (hour < 17 ? 'Good Afternoon, Harry.' : 'Good Evening, Harry.');

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            IntervalMath.formatMinuteOfDay(state.currentMinuteOfDay),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              fontFamily: ChronoTheme.monoFont,
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Glowing Floating Action Button ───────────────────────────────────────
  Widget _buildGlowingFab(BuildContext context, AppState state) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        AiConsultationSheet.show(context, state);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF4EE2CF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4EE2CF).withOpacity(0.55),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: -0.6,
                child: Container(
                  width: 18,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF07090E),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF07090E),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 4. Circadian Daylight Timeline & Cards ────────────────────────────────────

class _CircadianDaylightTimeline extends StatelessWidget {
  final AppState state;

  const _CircadianDaylightTimeline({required this.state});

  @override
  Widget build(BuildContext context) {
    const timelineHeight = 680.0;
    const waveColumnWidth = 145.0;

    return SizedBox(
      height: timelineHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Custom-Painted Daylight Wave & Hour Rail with Connectors
          CustomPaint(
            size: const Size(waveColumnWidth, timelineHeight),
            painter: _CircadianWaveRailPainter(
              currentMinuteOfDay: state.currentMinuteOfDay,
            ),
          ),

          // Right: Exact Cards Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Card 1: Levothyroxine Sodium (Morning Fasting Dose)
                  _buildLevothyroxineCard(context, state),

                  const SizedBox(height: 14),

                  // Card 2: Breakfast (Meal Anchor)
                  _buildBreakfastCard(context, state),

                  const SizedBox(height: 14),

                  // Card 3: Multivitamin (Active In-Focus Dose with Neon Glow)
                  _buildMultivitaminCard(context, state),

                  const SizedBox(height: 14),

                  // Card 4: Calcium Carbonate (Afternoon Cation-Protected Dose)
                  _buildCalciumCard(context, state),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card 1: Levothyroxine Sodium
  Widget _buildLevothyroxineCard(BuildContext context, AppState state) {
    final dose = state.doses.firstWhere(
      (d) => d.medicationName.toLowerCase().contains('levothyroxine'),
      orElse: () => state.doses.isNotEmpty
          ? state.doses.first
          : const ScheduledDose(
              id: 'med_levo',
              medicationId: 'med_levo',
              medicationName: 'LEVOTHYROXINE SODIUM',
              dosage: '50mcg',
              scheduledMinute: 420,
              status: DoseStatus.taken,
              clinicalInstruction: 'Empty stomach 60 min before food',
              safeFoodWindowNote: 'Fasting Window Active',
            ),
    );

    final isTaken = dose.status == DoseStatus.taken;

    return GestureDetector(
      onTap: () => _openDoseDetail(context, dose, state),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131A26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF38BDF8).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Time range + capsule icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '07:00 AM - 07:45 AM',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                Transform.rotate(
                  angle: -0.6,
                  child: Container(
                    width: 14,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Title & Dose
            const Text(
              'LEVOTHYROXINE SODIUM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '50mcg',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 9),

            // Footer Row: Fasting Window + 100% adherence mark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Empty Stomach Window\n(07:00 AM)',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9.5,
                    height: 1.25,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    state.toggleDose(dose.id);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isTaken ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTaken ? '100%' : 'Pending',
                        style: TextStyle(
                          color: isTaken ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '07:02 AM',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9.5,
                          fontFamily: ChronoTheme.monoFont,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Card 2: Breakfast (Meal Anchor)
  Widget _buildBreakfastCard(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111722),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.restaurant_rounded,
            color: Color(0xFF94A3B8),
            size: 15,
          ),
          SizedBox(width: 9),
          Text(
            'BREAKFAST',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(width: 4),
          Text(
            '(08:30 AM)',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Multivitamin (Active In-Focus Dose with Neon Glow)
  Widget _buildMultivitaminCard(BuildContext context, AppState state) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        AiConsultationSheet.show(
          context,
          state,
          focusMedication: 'Multivitamin',
          initialQuestion: 'Why is Multivitamin scheduled after breakfast?',
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131A26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00E5FF),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.28),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: 10:00 AM + cyan capsule icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '10:00 AM',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                Transform.rotate(
                  angle: -0.6,
                  child: Container(
                    width: 14,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Title & Dose
            const Text(
              'MULTIVITAMIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '1 Capsule',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              '(10:00 AM - 11:30 AM)',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),

            // Progress/Buffer bar
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.72,
                child: Container(
                  color: const Color(0xFF00E5FF).withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Buffered by 90 mins',
              style: TextStyle(
                color: Color(0xFF2DD4BF),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card 4: Calcium Carbonate (Afternoon Cation-Protected Dose)
  Widget _buildCalciumCard(BuildContext context, AppState state) {
    final dose = state.doses.firstWhere(
      (d) => d.medicationName.toLowerCase().contains('calcium'),
      orElse: () => const ScheduledDose(
        id: 'med_calcium',
        medicationId: 'med_calcium',
        medicationName: 'CALCIUM CARBONATE',
        dosage: '500mg',
        scheduledMinute: 780,
        status: DoseStatus.scheduled,
        clinicalInstruction: 'With food. 4-hour gap after thyroid.',
        safeFoodWindowNote: 'Cation Gap Verified',
      ),
    );

    return GestureDetector(
      onTap: () => _openDoseDetail(context, dose, state),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131A26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Time range + capsule icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '13:00 PM - 14:00 PM',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                Transform.rotate(
                  angle: -0.6,
                  child: Container(
                    width: 14,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Title & Dose
            const Text(
              'CALCIUM CARBONATE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '500mg',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 9),

            // Emerald Cation Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF042F2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: const Text(
                '4h Cation Gap Respected',
                style: TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 7),

            // Gap & Afternoon Window Footer
            const Row(
              children: [
                Text(
                  'Gap ',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                  ),
                ),
                Text(
                  '5h 28m',
                  style: TextStyle(
                    color: Color(0xFF2DD4BF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Afternoon Window',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.5,
                  ),
                ),
                Text(
                  '13:00 PM',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9.5,
                    fontFamily: ChronoTheme.monoFont,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDoseDetail(BuildContext context, ScheduledDose dose, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ChronoTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExactDoseDetailSheet(dose: dose, state: state),
    );
  }
}

// ── 5. Circadian Wave & Rail CustomPainter ────────────────────────────────────

class _CircadianWaveRailPainter extends CustomPainter {
  final int currentMinuteOfDay;

  _CircadianWaveRailPainter({required this.currentMinuteOfDay});

  @override
  void paint(Canvas canvas, Size size) {
    final H = size.height;
    final railX = size.width - 25.0; // Vertical rail position

    // 1. Draw organic vertical S-curve daylight wave band
    final wavePath = Path();
    wavePath.moveTo(0, 0);
    wavePath.lineTo(25, 0);

    // Smooth bezier curve following cortisol morning peak and sunset
    wavePath.cubicTo(20, H * 0.10, 48, H * 0.20, 68, H * 0.26); // Swell starts
    wavePath.cubicTo(88, H * 0.32, 98, H * 0.38, 85, H * 0.44); // 10:00 AM Sun Peak Crest
    wavePath.cubicTo(70, H * 0.50, 46, H * 0.58, 56, H * 0.66); // Afternoon dip
    wavePath.cubicTo(66, H * 0.74, 58, H * 0.82, 36, H * 0.90); // Twilight evening
    wavePath.cubicTo(24, H * 0.95, 20, H * 0.98, 22, H);       // Night

    wavePath.lineTo(0, H);
    wavePath.close();

    // Fill wave with daylight gradient
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.34, 0.55, 0.78, 1.0],
      colors: [
        const Color(0xFFF59E0B).withOpacity(0.40), // Sunrise Gold
        const Color(0xFFFDE68A).withOpacity(0.32), // Morning Sun Peak
        const Color(0xFF334155).withOpacity(0.22), // Afternoon Slate
        const Color(0xFF1E293B).withOpacity(0.38), // Evening Twilight
        const Color(0xFF0F172A).withOpacity(0.60), // Midnight Dark
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, H))
      ..style = PaintingStyle.fill;
    canvas.drawPath(wavePath, fillPaint);

    // Contour outer glowing stroke line
    final contourPath = Path();
    contourPath.moveTo(25, 0);
    contourPath.cubicTo(20, H * 0.10, 48, H * 0.20, 68, H * 0.26);
    contourPath.cubicTo(88, H * 0.32, 98, H * 0.38, 85, H * 0.44);
    contourPath.cubicTo(70, H * 0.50, 46, H * 0.58, 56, H * 0.66);
    contourPath.cubicTo(66, H * 0.74, 58, H * 0.82, 36, H * 0.90);
    contourPath.cubicTo(24, H * 0.95, 20, H * 0.98, 22, H);

    const strokeGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF59E0B),
        Color(0xFFFBBF24),
        Color(0xFF38BDF8),
        Color(0xFF6366F1),
        Color(0xFF1E293B),
      ],
    );

    final strokePaint = Paint()
      ..shader = strokeGradient.createShader(Rect.fromLTWH(0, 0, size.width, H))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(contourPath, strokePaint);

    // 2. Draw text markers along the daylight wave
    final tp = TextPainter(textDirection: TextDirection.ltr);

    void drawMarker(String text, double x, double y, {Color color = const Color(0xFF94A3B8), double fontSize = 9.5}) {
      tp.text = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          fontFamily: ChronoTheme.monoFont,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(x, y));
    }

    drawMarker('06:00 AM', 6, 8);
    drawMarker('08:00 AM', 8, H * 0.20);
    drawMarker('10:00 AM  Sun ☀️', 6, H * 0.32, color: const Color(0xFFFBBF24));
    drawMarker('13:00 PM', 6, H * 0.50);
    drawMarker('Evening', 8, H * 0.58, color: const Color(0xFF64748B));
    drawMarker('02:00 PM', 6, H * 0.66);
    drawMarker('Night', 8, H * 0.78, color: const Color(0xFF64748B));
    drawMarker('06:00 AM', 6, H - 18);

    // 3. Highlighted cyan pill at the 10:00 AM sun crest: "09:45 AM"
    final pillY = H * 0.36;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(76, pillY), width: 56, height: 18),
      const Radius.circular(9),
    );
    canvas.drawRRect(
      pillRect,
      Paint()..color = const Color(0xFF042F2E),
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = const Color(0xFF2DD4BF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    tp.text = const TextSpan(
      text: '09:45 AM',
      style: TextStyle(
        color: Color(0xFF2DD4BF),
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        fontFamily: ChronoTheme.monoFont,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(54, pillY - 6));

    // Pointer line from 09:45 AM pill to railX
    canvas.drawLine(
      Offset(104, pillY),
      Offset(railX, pillY),
      Paint()
        ..color = const Color(0xFF2DD4BF)
        ..strokeWidth = 1.2,
    );

    // 4. Center vertical timeline rail
    final railPaint = Paint()
      ..color = const Color(0xFF334155).withOpacity(0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(railX, 10), Offset(railX, H - 10), railPaint);

    // Ticks & Hours along the rail
    final hourPoints = <({String label, double y, bool isNode, Color? nodeColor})>[
      (label: '07', y: 48, isNode: true, nodeColor: const Color(0xFF38BDF8)),
      (label: '08', y: 135, isNode: true, nodeColor: const Color(0xFF94A3B8)),
      (label: '09', y: 195, isNode: true, nodeColor: const Color(0xFF2DD4BF)),
      (label: '10', y: pillY, isNode: false, nodeColor: null),
      (label: '11', y: 285, isNode: false, nodeColor: null),
      (label: '12', y: 345, isNode: false, nodeColor: null),
      (label: '13', y: 415, isNode: true, nodeColor: const Color(0xFF64748B)),
      (label: '14', y: 475, isNode: false, nodeColor: null),
      (label: '04', y: 535, isNode: false, nodeColor: null),
      (label: '05', y: 590, isNode: false, nodeColor: null),
      (label: '06', y: 645, isNode: false, nodeColor: null),
    ];

    for (final pt in hourPoints) {
      // Small horizontal tick on rail
      canvas.drawLine(
        Offset(railX - 3, pt.y),
        Offset(railX + 3, pt.y),
        Paint()..color = const Color(0xFF64748B)..strokeWidth = 1.0,
      );

      // Label next to rail
      tp.text = TextSpan(
        text: pt.label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          fontFamily: ChronoTheme.monoFont,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(railX - 16, pt.y - 5.5));

      // Branching connector line to card if it's an active dose/meal node
      if (pt.isNode) {
        final color = pt.nodeColor ?? const Color(0xFF38BDF8);

        // Branch node circle on rail
        canvas.drawCircle(Offset(railX, pt.y), 3.5, Paint()..color = color);

        // Circuit line branching into the card on the right
        final branchPath = Path();
        branchPath.moveTo(railX, pt.y);
        branchPath.cubicTo(
          railX + 10,
          pt.y,
          railX + 12,
          pt.y,
          size.width,
          pt.y,
        );

        canvas.drawPath(
          branchPath,
          Paint()
            ..color = color.withOpacity(0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircadianWaveRailPainter oldDelegate) =>
      oldDelegate.currentMinuteOfDay != currentMinuteOfDay;
}

// ── 6. Dose Detail Modal Sheet ────────────────────────────────────────────────

class _ExactDoseDetailSheet extends StatelessWidget {
  final ScheduledDose dose;
  final AppState state;

  const _ExactDoseDetailSheet({required this.dose, required this.state});

  @override
  Widget build(BuildContext context) {
    final isTaken = dose.status == DoseStatus.taken;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.formattedTime,
                    style: const TextStyle(
                      color: Color(0xFF2DD4BF),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: ChronoTheme.monoFont,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dose.medicationName} (${dose.dosage})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Clinical rationale card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131A26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CLINICAL INSTRUCTION',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dose.clinicalInstruction,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  'FOOD-DRUG WINDOW',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dose.safeFoodWindowNote,
                  style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    AiConsultationSheet.show(
                      context,
                      state,
                      focusMedication: dose.medicationName,
                      initialQuestion: 'Why is ${dose.medicationName} scheduled at ${dose.formattedTime}?',
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF2DD4BF)),
                  label: const Text('Ask AI', style: TextStyle(color: Color(0xFF2DD4BF))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2DD4BF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    state.toggleDose(dose.id);
                    Navigator.pop(context);
                  },
                  icon: Icon(isTaken ? Icons.undo_rounded : Icons.check_rounded, size: 16),
                  label: Text(isTaken ? 'Mark Pending' : 'Mark Taken'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTaken ? const Color(0xFF334155) : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
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
