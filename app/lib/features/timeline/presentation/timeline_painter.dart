import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';

/// 120 FPS CustomPainter rendering the 24-Hour Living Timeline.
/// Mobile-optimized with a 48px compact gutter and full-width touchable dose cards.
class TimelinePainter extends CustomPainter {
  final Routine routine;
  final List<ScheduledDose> doses;
  final int currentMinuteOfDay;
  final String? selectedDoseId;

  static const double _canvasHeight = 1600.0;
  static const double _gutterWidth = 48.0;
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

  // ── 1. Hour Grid ───────────────────────────────────────────────────────
  void _drawHourGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (var h = 0; h < 24; h++) {
      final y = h * 60 * _heightPerMinute;
      canvas.drawLine(Offset(_gutterWidth, y), Offset(size.width, y), gridPaint);

      final label = h == 0
          ? '12A'
          : h < 12
              ? '${h}A'
              : h == 12
                  ? '12P'
                  : '${h - 12}P';

      tp.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(4, y - 6));
    }
  }

  // ── 2. Sleep Bands ─────────────────────────────────────────────────────
  void _drawSleepBands(Canvas canvas, Size size) {
    final sleepPaint = Paint()..color = const Color(0xFF818CF8).withOpacity(0.07);
    final wakeY = routine.wakeTimeMinutes * _heightPerMinute;
    final sleepY = routine.sleepTimeMinutes * _heightPerMinute;

    canvas.drawRect(Rect.fromLTRB(_gutterWidth, 0, size.width, wakeY), sleepPaint);
    canvas.drawRect(Rect.fromLTRB(_gutterWidth, sleepY, size.width, _canvasHeight), sleepPaint);

    _drawBandLabel(canvas, 'SLEEP', _gutterWidth + 8, wakeY / 2 - 6, const Color(0xFF818CF8));
    _drawBandLabel(canvas, 'SLEEP', _gutterWidth + 8, sleepY + (_canvasHeight - sleepY) / 2 - 6, const Color(0xFF818CF8));
  }

  // ── 3. Fasting Hazard Bands ────────────────────────────────────────────
  void _drawFastingBands(Canvas canvas, Size size) {
    const preBuf = ClinicalBuffers.emptyStomachPreMealBufferMinutes;
    const postBuf = ClinicalBuffers.emptyStomachPostMealBufferMinutes;

    final fastPaint = Paint()..color = const Color(0xFFF43F5E).withOpacity(0.06);
    final fastBorderPaint = Paint()
      ..color = const Color(0xFFF43F5E).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final meal in routine.meals) {
      final preStart = (meal.startTimeMinutes - preBuf) * _heightPerMinute;
      final preEnd = meal.startTimeMinutes * _heightPerMinute;
      if (preStart >= 0) {
        final r = Rect.fromLTRB(_gutterWidth, preStart, size.width - 4, preEnd);
        canvas.drawRect(r, fastPaint);
        canvas.drawRect(r, fastBorderPaint);
        _drawBandLabel(canvas, 'FASTING', _gutterWidth + 6, preStart + 3, const Color(0xFFF43F5E));
      }

      final postStart = meal.endTimeMinutes * _heightPerMinute;
      final postEnd = (meal.endTimeMinutes + postBuf) * _heightPerMinute;
      if (postEnd <= _canvasHeight) {
        final r = Rect.fromLTRB(_gutterWidth, postStart, size.width - 4, postEnd);
        canvas.drawRect(r, fastPaint);
        canvas.drawRect(r, fastBorderPaint);
        _drawBandLabel(canvas, 'FASTING', _gutterWidth + 6, postStart + 3, const Color(0xFFF43F5E));
      }
    }
  }

  // ── 4. Meal Bands ──────────────────────────────────────────────────────
  void _drawMealBands(Canvas canvas, Size size) {
    final mealFill = Paint()..color = const Color(0xFF10B981).withOpacity(0.12);
    final mealBorder = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (final meal in routine.meals) {
      final top = meal.startTimeMinutes * _heightPerMinute;
      final bottom = meal.endTimeMinutes * _heightPerMinute;
      final rect = Rect.fromLTRB(_gutterWidth, top, size.width - 4, bottom);
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

      canvas.drawRRect(rRect, mealFill);
      canvas.drawRRect(rRect, mealBorder);

      tp.text = TextSpan(
        text: '🍽 ${meal.displayName.toUpperCase()}',
        style: const TextStyle(
          color: Color(0xFF6EE7B7),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(_gutterWidth + 8, top + 4));
    }
  }

  // ── 5. Dose Cards (Mobile Sized) ───────────────────────────────────────
  void _drawDoses(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (final dose in doses) {
      final y = dose.scheduledMinute * _heightPerMinute;
      final isTaken = dose.status == DoseStatus.taken;
      final isSelected = dose.id == selectedDoseId;

      final dotColor = isTaken
          ? const Color(0xFF10B981)
          : dose.status == DoseStatus.missed
              ? const Color(0xFFF43F5E)
              : dose.status == DoseStatus.due
                  ? const Color(0xFF22D3EE)
                  : const Color(0xFFF59E0B);

      // Selection glow
      if (isSelected) {
        final glowPaint = Paint()
          ..color = dotColor.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(_gutterWidth + 12, y), 10, glowPaint);
      }

      // Dot indicator
      canvas.drawCircle(Offset(_gutterWidth + 12, y), 5, Paint()..color = dotColor);

      // Card background
      final cardLeft = _gutterWidth + 24;
      final cardWidth = (size.width - cardLeft - 8).clamp(120.0, 500.0);
      final cardRect = Rect.fromLTWH(cardLeft, y - 18, cardWidth, 36);
      final rRect = RRect.fromRectAndRadius(cardRect, const Radius.circular(8));

      canvas.drawRRect(
        rRect,
        Paint()
          ..color = isTaken
              ? const Color(0xFF141A28)
              : isSelected
                  ? dotColor.withOpacity(0.15)
                  : const Color(0xFF141B2B),
      );
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = isTaken ? const Color(0xFF1E293B) : dotColor.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Time + name text
      tp.text = TextSpan(
        children: [
          TextSpan(
            text: '${dose.formattedTime}  ',
            style: TextStyle(
              color: isTaken ? const Color(0xFF475569) : dotColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          TextSpan(
            text: '${dose.medicationName} (${dose.dosage})',
            style: TextStyle(
              color: isTaken ? const Color(0xFF475569) : const Color(0xFFF1F5F9),
              fontWeight: FontWeight.w600,
              fontSize: 11,
              decoration: isTaken ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      );
      tp.layout(maxWidth: cardWidth - 16);
      tp.paint(canvas, Offset(cardRect.left + 8, cardRect.top + 10));
    }
  }

  // ── 6. Now Indicator ───────────────────────────────────────────────────
  void _drawNowIndicator(Canvas canvas, Size size) {
    if (currentMinuteOfDay < 0 || currentMinuteOfDay >= 1440) return;

    final y = currentMinuteOfDay * _heightPerMinute;

    canvas.drawLine(
      Offset(_gutterWidth - 4, y),
      Offset(size.width, y),
      Paint()
        ..color = const Color(0xFFF43F5E)
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      Offset(_gutterWidth - 4, y),
      4,
      Paint()..color = const Color(0xFFF43F5E),
    );

    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = const TextSpan(
        text: 'NOW',
        style: TextStyle(
          color: Color(0xFFF43F5E),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      )
      ..layout();
    tp.paint(canvas, Offset(_gutterWidth - 4, y - 12));
  }

  void _drawBandLabel(Canvas canvas, String text, double x, double y, Color color) {
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(0.6),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      )
      ..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) =>
      oldDelegate.currentMinuteOfDay != currentMinuteOfDay ||
      oldDelegate.doses != doses ||
      oldDelegate.routine != routine ||
      oldDelegate.selectedDoseId != selectedDoseId;
}
