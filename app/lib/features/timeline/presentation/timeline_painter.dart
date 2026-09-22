import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';

/// High-Definition 24-Hour Circadian Map Painter.
/// Features collision-free pill cards, glowing 'NOW' indicator,
/// circadian meal gradients, and crisp dark-mode typography.
class TimelinePainter extends CustomPainter {
  final Routine routine;
  final List<ScheduledDose> doses;
  final int currentMinuteOfDay;
  final String? selectedDoseId;

  static const double _canvasHeight = 1680.0;
  static const double _gutterWidth = 54.0;
  static const double _heightPerMinute = _canvasHeight / 1440.0;

  TimelinePainter({
    required this.routine,
    required this.doses,
    required this.currentMinuteOfDay,
    this.selectedDoseId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawHourGrid(canvas, size);
    _drawSleepBands(canvas, size);
    _drawFastingBands(canvas, size);
    _drawMealBands(canvas, size);
    _drawDoses(canvas, size);
    _drawNowIndicator(canvas, size);
  }

  // ── 1. Hour Grid ───────────────────────────────────────────────────────────
  void _drawHourGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.7)
      ..strokeWidth = 1.0;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (var h = 0; h < 24; h++) {
      final y = h * 60 * _heightPerMinute;
      canvas.drawLine(Offset(_gutterWidth, y), Offset(size.width, y), gridPaint);

      final isMajor = h % 3 == 0;
      final label = h == 0
          ? '12 AM'
          : h < 12
              ? '$h AM'
              : h == 12
                  ? '12 PM'
                  : '${h - 12} PM';

      tp.text = TextSpan(
        text: label,
        style: TextStyle(
          color: isMajor ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          fontSize: isMajor ? 10 : 9,
          fontWeight: isMajor ? FontWeight.w700 : FontWeight.w500,
          fontFamily: 'monospace',
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(4, y - 6));
    }
  }

  // ── 2. Sleep Bands ─────────────────────────────────────────────────────────
  void _drawSleepBands(Canvas canvas, Size size) {
    final sleepPaint = Paint()..color = const Color(0xFF6366F1).withOpacity(0.08);
    final wakeY = routine.wakeTimeMinutes * _heightPerMinute;
    final sleepY = routine.sleepTimeMinutes * _heightPerMinute;

    // Pre-wake sleep
    canvas.drawRect(Rect.fromLTRB(_gutterWidth, 0, size.width, wakeY), sleepPaint);
    // Post-bedtime sleep
    canvas.drawRect(Rect.fromLTRB(_gutterWidth, sleepY, size.width, _canvasHeight), sleepPaint);

    _drawBandBadge(canvas, '🌙 SLEEP / REST', _gutterWidth + 10, wakeY / 2 - 10, const Color(0xFF818CF8));
    _drawBandBadge(canvas, '🌙 SLEEP / REST', _gutterWidth + 10, sleepY + (_canvasHeight - sleepY) / 2 - 10, const Color(0xFF818CF8));
  }

  // ── 3. Fasting Hazard Bands ────────────────────────────────────────────────
  void _drawFastingBands(Canvas canvas, Size size) {
    const preBuf = ClinicalBuffers.emptyStomachPreMealBufferMinutes;
    const postBuf = ClinicalBuffers.emptyStomachPostMealBufferMinutes;

    final fastFill = Paint()..color = const Color(0xFFF43F5E).withOpacity(0.06);
    final fastBorder = Paint()
      ..color = const Color(0xFFF43F5E).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final meal in routine.meals) {
      final preStart = (meal.startTimeMinutes - preBuf) * _heightPerMinute;
      final preEnd = meal.startTimeMinutes * _heightPerMinute;
      if (preStart >= 0) {
        final r = Rect.fromLTRB(_gutterWidth + 2, preStart, size.width - 6, preEnd);
        final rRect = RRect.fromRectAndRadius(r, const Radius.circular(6));
        canvas.drawRRect(rRect, fastFill);
        canvas.drawRRect(rRect, fastBorder);
        _drawBandBadge(canvas, '⚠️ FASTING BUFFER (Pre-${meal.displayName})', _gutterWidth + 10, preStart + 4, const Color(0xFFF43F5E));
      }

      final postStart = meal.endTimeMinutes * _heightPerMinute;
      final postEnd = (meal.endTimeMinutes + postBuf) * _heightPerMinute;
      if (postEnd <= _canvasHeight) {
        final r = Rect.fromLTRB(_gutterWidth + 2, postStart, size.width - 6, postEnd);
        final rRect = RRect.fromRectAndRadius(r, const Radius.circular(6));
        canvas.drawRRect(rRect, fastFill);
        canvas.drawRRect(rRect, fastBorder);
        _drawBandBadge(canvas, '⚠️ FASTING BUFFER (Post-${meal.displayName})', _gutterWidth + 10, postStart + 4, const Color(0xFFF43F5E));
      }
    }
  }

  // ── 4. Meal Bands ──────────────────────────────────────────────────────────
  void _drawMealBands(Canvas canvas, Size size) {
    final mealFill = Paint()..color = const Color(0xFF10B981).withOpacity(0.14);
    final mealBorder = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final meal in routine.meals) {
      final top = meal.startTimeMinutes * _heightPerMinute;
      final bottom = meal.endTimeMinutes * _heightPerMinute;
      final rect = Rect.fromLTRB(_gutterWidth + 2, top, size.width - 6, bottom);
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      canvas.drawRRect(rRect, mealFill);
      canvas.drawRRect(rRect, mealBorder);

      final icon = meal.type == MealType.breakfast
          ? '🍳'
          : meal.type == MealType.lunch
              ? '🥗'
              : '🍲';

      _drawBandBadge(
        canvas,
        '$icon ${meal.displayName.toUpperCase()} (${meal.startTimeMinutes ~/ 60}:${(meal.startTimeMinutes % 60).toString().padLeft(2, '0')})',
        _gutterWidth + 10,
        top + 6,
        const Color(0xFF34D399),
      );
    }
  }

  // ── 5. Dose Cards (Collision-Resistant & Polished) ──────────────────────────
  void _drawDoses(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);

    // Track vertical positions to prevent visual collision
    double lastCardBottom = -100.0;

    for (var i = 0; i < doses.length; i++) {
      final dose = doses[i];
      final targetY = dose.scheduledMinute * _heightPerMinute;
      final isTaken = dose.status == DoseStatus.taken;
      final isSelected = dose.id == selectedDoseId;

      final color = isTaken
          ? const Color(0xFF10B981)
          : dose.status == DoseStatus.due
              ? const Color(0xFF22D3EE)
              : dose.status == DoseStatus.missed
                  ? const Color(0xFFF43F5E)
                  : const Color(0xFFF59E0B);

      // Node point on timeline track
      canvas.drawCircle(Offset(_gutterWidth + 12, targetY), 6, Paint()..color = color);
      canvas.drawCircle(
        Offset(_gutterWidth + 12, targetY),
        3,
        Paint()..color = const Color(0xFF07090E),
      );

      // Card positioning (prevent collision)
      var cardY = targetY - 18;
      if (cardY < lastCardBottom + 4) {
        cardY = lastCardBottom + 4;
      }
      const cardHeight = 42.0;
      lastCardBottom = cardY + cardHeight;

      const cardLeft = _gutterWidth + 26;
      final cardWidth = (size.width - cardLeft - 10).clamp(140.0, 520.0);
      final cardRect = Rect.fromLTWH(cardLeft, cardY, cardWidth, cardHeight);
      final rRect = RRect.fromRectAndRadius(cardRect, const Radius.circular(10));

      // Glow if selected
      if (isSelected) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawRRect(rRect, glowPaint);
      }

      // Card surface
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = isTaken
              ? const Color(0xFF111827)
              : isSelected
                  ? color.withOpacity(0.18)
                  : const Color(0xFF161F30),
      );

      // Card border
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = isTaken
              ? const Color(0xFF1F2937)
              : isSelected
                  ? color
                  : color.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.8 : 1.2,
      );

      // Text inside card: Time pill + Drug Name
      tp.text = TextSpan(
        children: [
          TextSpan(
            text: '${dose.formattedTime}  ',
            style: TextStyle(
              color: isTaken ? const Color(0xFF64748B) : color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          TextSpan(
            text: '${dose.medicationName} ',
            style: TextStyle(
              color: isTaken ? const Color(0xFF64748B) : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              decoration: isTaken ? TextDecoration.lineThrough : null,
            ),
          ),
          TextSpan(
            text: '(${dose.dosage})',
            style: TextStyle(
              color: isTaken ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
      tp.layout(maxWidth: cardWidth - 16);
      tp.paint(canvas, Offset(cardRect.left + 10, cardRect.top + 7));

      // Second row instruction note
      final tpSub = TextPainter(
        text: TextSpan(
          text: isTaken ? '✓ Taken' : dose.clinicalInstruction,
          style: TextStyle(
            color: isTaken ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: cardWidth - 16);
      tpSub.paint(canvas, Offset(cardRect.left + 10, cardRect.top + 23));
    }
  }

  // ── 6. Now Indicator (Glowing Beaming Line) ─────────────────────────────────
  void _drawNowIndicator(Canvas canvas, Size size) {
    if (currentMinuteOfDay < 0 || currentMinuteOfDay >= 1440) return;

    final y = currentMinuteOfDay * _heightPerMinute;

    // Glowing line
    canvas.drawLine(
      Offset(_gutterWidth - 8, y),
      Offset(size.width, y),
      Paint()
        ..color = const Color(0xFF22D3EE).withOpacity(0.5)
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Sharp line
    canvas.drawLine(
      Offset(_gutterWidth - 8, y),
      Offset(size.width, y),
      Paint()
        ..color = const Color(0xFF22D3EE)
        ..strokeWidth = 1.5,
    );

    // Glowing pulsing dot
    canvas.drawCircle(
      Offset(_gutterWidth - 8, y),
      6,
      Paint()
        ..color = const Color(0xFF22D3EE).withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(_gutterWidth - 8, y),
      3.5,
      Paint()..color = const Color(0xFF22D3EE),
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'NOW',
        style: TextStyle(
          color: Color(0xFF22D3EE),
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(_gutterWidth - 8, y - 13));
  }

  void _drawBandBadge(Canvas canvas, String text, double x, double y, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) =>
      oldDelegate.currentMinuteOfDay != currentMinuteOfDay ||
      oldDelegate.doses != doses ||
      oldDelegate.routine != routine ||
      oldDelegate.selectedDoseId != selectedDoseId;
}
