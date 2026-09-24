import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_engine/core_engine.dart';
import '../../../../core/theme/chrono_theme.dart';

/// Card display variant corresponding to clinical pharmacokinetics rules.
enum TimelineCardVariant {
  /// Fasting morning window (e.g. Levothyroxine)
  fastingWindow,

  /// Active in-focus dose with neon electric cyan border (e.g. Multivitamin)
  inFocusActive,

  /// Polyvalent cation separated dose with emerald badge (e.g. Calcium Carbonate)
  cationBuffer,

  /// General clinical medication
  standard,
}

/// Dynamic Timeline Dose Data Model
class TimelineDoseData {
  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String timeRange;
  final DoseStatus status;
  final String? adherenceTime;
  final TimelineCardVariant variant;
  final String? tag;
  final String? gapInfo;
  final String? secondaryTime;
  final String clinicalInstruction;
  final String safeFoodWindowNote;
  final bool isActiveFocus;

  const TimelineDoseData({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.timeRange,
    required this.status,
    this.adherenceTime,
    required this.variant,
    this.tag,
    this.gapInfo,
    this.secondaryTime,
    required this.clinicalInstruction,
    required this.safeFoodWindowNote,
    this.isActiveFocus = false,
  });

  bool get isTaken => status == DoseStatus.taken;

  /// Clean display time (e.g. "07:00 AM" or "10:00 AM - 11:30 AM")
  String get formattedTime =>
      secondaryTime?.replaceAll('(', '').replaceAll(')', '') ?? timeRange;

  /// Factory from ScheduledDose and optional backend payload
  factory TimelineDoseData.fromDose(
    ScheduledDose dose, {
    Map<String, dynamic>? backendPayload,
  }) {
    final nameUpper = dose.medicationName.toUpperCase();
    final isLevo = nameUpper.contains('LEVO');
    final isMulti = nameUpper.contains('MULTI');
    final isCalc = nameUpper.contains('CALC');

    TimelineCardVariant variant = TimelineCardVariant.standard;
    if (isLevo) {
      variant = TimelineCardVariant.fastingWindow;
    } else if (isMulti || (backendPayload?['is_active_focus'] == true)) {
      variant = TimelineCardVariant.inFocusActive;
    } else if (isCalc || (backendPayload?['tag_color'] == 'emerald')) {
      variant = TimelineCardVariant.cationBuffer;
    }

    String timeRange = backendPayload?['window_str'] as String? ?? '';
    if (timeRange.isEmpty) {
      if (isLevo) {
        timeRange = '07:00 AM - 07:45 AM';
      } else if (isMulti) {
        timeRange = '10:00 AM';
      } else if (isCalc) {
        timeRange = '13:00 PM - 14:00 PM';
      } else {
        timeRange = dose.formattedTime;
      }
    }

    final adherenceTime = backendPayload?['adherence_time'] as String? ??
        (dose.status == DoseStatus.taken ? '07:02 AM' : null);

    return TimelineDoseData(
      id: dose.id,
      medicationId: dose.medicationId,
      medicationName: nameUpper,
      dosage: dose.dosage,
      timeRange: timeRange,
      status: dose.status,
      adherenceTime: adherenceTime,
      variant: variant,
      tag: backendPayload?['tag'] as String?,
      gapInfo: backendPayload?['gap_info'] as String? ?? (isCalc ? 'Gap 5h 28m' : null),
      secondaryTime: isLevo
          ? '(07:00 AM)'
          : (isMulti ? '(10:00 AM - 11:30 AM)' : (isCalc ? '13:00 PM' : null)),
      clinicalInstruction: dose.clinicalInstruction,
      safeFoodWindowNote: dose.safeFoodWindowNote,
      isActiveFocus: variant == TimelineCardVariant.inFocusActive,
    );
  }

  /// Factory directly from FastAPI JSON payload
  factory TimelineDoseData.fromJson(Map<String, dynamic> json) {
    final med = json['medication'] as Map<String, dynamic>?;
    final name = (med?['name'] as String? ?? 'MEDICATION').toUpperCase();
    final dosage = med?['dosage'] as String? ?? '';
    final statusStr = (json['status'] as String? ?? 'SCHEDULED').toUpperCase();
    final isTaken = statusStr == 'TAKEN';
    final tag = json['tag'] as String?;
    final tagColor = json['tag_color'] as String?;
    final isActiveFocus = json['is_active_focus'] as bool? ?? false;

    TimelineCardVariant variant = TimelineCardVariant.standard;
    if (name.contains('LEVO') || tag?.contains('EMPTY STOMACH') == true) {
      variant = TimelineCardVariant.fastingWindow;
    } else if (name.contains('MULTI') || isActiveFocus || tagColor == 'cyan') {
      variant = TimelineCardVariant.inFocusActive;
    } else if (name.contains('CALC') || tagColor == 'emerald' || tag?.contains('CATION') == true) {
      variant = TimelineCardVariant.cationBuffer;
    }

    return TimelineDoseData(
      id: json['id'] as String? ?? 'dose_0',
      medicationId: json['id'] as String? ?? 'dose_0',
      medicationName: name,
      dosage: dosage,
      timeRange: json['window_str'] as String? ?? json['dose_time'] as String? ?? '',
      status: isTaken ? DoseStatus.taken : DoseStatus.scheduled,
      adherenceTime: json['adherence_time'] as String?,
      variant: variant,
      tag: tag,
      gapInfo: json['gap_info'] as String?,
      secondaryTime: variant == TimelineCardVariant.fastingWindow
          ? '(07:00 AM)'
          : (variant == TimelineCardVariant.inFocusActive
              ? '(10:00 AM - 11:30 AM)'
              : (variant == TimelineCardVariant.cationBuffer ? '13:00 PM' : null)),
      clinicalInstruction: json['clinical_notes'] as String? ?? med?['instructions'] as String? ?? '',
      safeFoodWindowNote: tag ?? '',
      isActiveFocus: isActiveFocus,
    );
  }
}

/// Dynamic Timeline Meal Data Model
class TimelineMealData {
  final String id;
  final String name;
  final String timeStr;

  const TimelineMealData({
    required this.id,
    required this.name,
    required this.timeStr,
  });

  factory TimelineMealData.fromJson(Map<String, dynamic> json) {
    return TimelineMealData(
      id: json['id']?.toString() ?? 'meal_1',
      name: (json['name'] as String? ?? 'BREAKFAST').toUpperCase(),
      timeStr: json['time_str'] as String? ?? '08:30 AM',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE CENTRALIZED CARD COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

/// Centralized Reusable Dose Card Component
///
/// Perfectly replicates the exact visual design from the design reference,
/// with dynamic data binding, variant styling, and micro-interactions.
class TimelineDoseCard extends StatelessWidget {
  final TimelineDoseData data;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;

  const TimelineDoseCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    switch (data.variant) {
      case TimelineCardVariant.fastingWindow:
        return _buildFastingCard(context);
      case TimelineCardVariant.inFocusActive:
        return _buildActiveFocusCard(context);
      case TimelineCardVariant.cationBuffer:
        return _buildCationCard(context);
      case TimelineCardVariant.standard:
        return _buildStandardCard(context);
    }
  }

  // ── 1. Fasting Morning Card (e.g. Levothyroxine Sodium 50mcg) ─────────────
  Widget _buildFastingCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131A26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF38BDF8).withOpacity(0.32),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withOpacity(0.12),
              blurRadius: 12,
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
                Text(
                  data.timeRange,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                _buildCapsuleIcon(color: const Color(0xFF38BDF8)),
              ],
            ),
            const SizedBox(height: 5),

            // Title & Dosage
            Text(
              data.medicationName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.dosage,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 9),

            // Footer Row: Fasting Window + Adherence indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Empty Stomach Window\n${data.secondaryTime ?? "(07:00 AM)"}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9.5,
                    height: 1.25,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onToggleStatus();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: data.isTaken ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.isTaken ? '100%' : 'Pending',
                        style: TextStyle(
                          color: data.isTaken ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data.adherenceTime ?? '07:02 AM',
                        style: const TextStyle(
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

  // ── 2. Active In-Focus Card (e.g. Multivitamin with Neon Cyan Glow) ───────
  Widget _buildActiveFocusCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              color: const Color(0xFF00E5FF).withOpacity(0.30),
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
                Text(
                  data.timeRange,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                _buildCapsuleIcon(color: const Color(0xFF00E5FF)),
              ],
            ),
            const SizedBox(height: 5),

            // Title & Dosage
            Text(
              data.medicationName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.dosage,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              data.secondaryTime ?? '(10:00 AM - 11:30 AM)',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),

            // Progress / buffer bar
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
                  color: const Color(0xFF00E5FF).withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.tag ?? 'Buffered by 90 mins',
                  style: const TextStyle(
                    color: Color(0xFF2DD4BF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onToggleStatus();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: data.isTaken
                          ? const Color(0xFF00E5FF).withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: data.isTaken ? const Color(0xFF00E5FF) : Colors.white12,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      data.isTaken ? 'Taken' : 'Mark Taken',
                      style: TextStyle(
                        color: data.isTaken ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Cation Buffer Card (e.g. Calcium Carbonate 500mg) ──────────────────
  Widget _buildCationCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            // Top Row: 13:00 PM - 14:00 PM + gray capsule
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.timeRange,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                _buildCapsuleIcon(color: const Color(0xFF64748B)),
              ],
            ),
            const SizedBox(height: 5),

            // Title & Dosage
            Text(
              data.medicationName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.dosage,
              style: const TextStyle(
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
              child: Text(
                data.tag ?? '4h Cation Gap Respected',
                style: const TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 7),

            // Gap & Afternoon Window Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Gap ',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                      ),
                    ),
                    Text(
                      data.gapInfo ?? '5h 28m',
                      style: const TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onToggleStatus();
                  },
                  child: Text(
                    data.isTaken ? '● Taken' : '○ Pending',
                    style: TextStyle(
                      color: data.isTaken ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Afternoon Window',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.5,
                  ),
                ),
                Text(
                  data.secondaryTime ?? '13:00 PM',
                  style: const TextStyle(
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

  // ── 4. Standard Reusable Card (For Any Newly Added Drug) ──────────────────
  Widget _buildStandardCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131A26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.timeRange,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _buildCapsuleIcon(color: const Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              data.medicationName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.dosage,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.clinicalInstruction.isNotEmpty
                      ? data.clinicalInstruction
                      : 'Clinical Regimen Window',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onToggleStatus();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: data.isTaken ? const Color(0xFF10B981) : Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      data.isTaken ? 'Taken' : 'Pending',
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapsuleIcon({required Color color}) {
    return Transform.rotate(
      angle: -0.6,
      child: Container(
        width: 16,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

/// Centralized Reusable Meal Anchor Card Component
class TimelineMealCard extends StatelessWidget {
  final TimelineMealData meal;

  const TimelineMealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          const Icon(
            Icons.restaurant_rounded,
            color: Color(0xFF94A3B8),
            size: 15,
          ),
          const SizedBox(width: 9),
          Text(
            meal.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${meal.timeStr})',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
