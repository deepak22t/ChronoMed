import 'package:flutter/material.dart';
import 'package:core_engine/core_engine.dart';
import '../../../core/theme/chrono_theme.dart';

/// Calm Health 24-Hour Circadian Map Painter.
///
/// Features low-glare soothing opacity bands, collision-resistant pill cards,
/// gentle Glacial Blue "NOW" indicator, and crisp dark-mode typography.
class TimelinePainter extends CustomPainter {
  final Routine routine;
  final List<ScheduledDose> doses;
  final int currentMinuteOfDay;
  final String? selectedDoseId;

  static const double _canvasHeight = 1680.0;
  static const double _gutterWidth = 52.0;
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
      ..color = ChronoTheme.borderSubtle
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
          color: isMajor ? ChronoTheme.textSecondary : ChronoTheme.textDim,
          fontSize: isMajor ? 10 : 9,
          fontWeight: isMajor ? FontWeight.w700 : FontWeight.w500,
          fontFamily: ChronoTheme.monoFont,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(4, y - 6));
    }
  }

  // ── 2. Sleep Bands (Soft Neutral Slate) ────────────────────────────────────
  void _drawSleepBands(Canvas canvas, Size size) {
    final sleepPaint = Paint()..color = const Color(0xFF64748B).withOpacity(0.06);
    final wakeY = routine.wakeTimeMinutes * _heightPerMinute;
    final sleepY = routine.sleepTimeMinutes * _heightPerMinute;

    canvas.drawRect(Rect.fromLTRB(_gutterWidth, 0, size.width, wakeY), sleepPaint);
    canvas.drawRect(Rect.fromLTRB(_gutterWidth, sleepY, size.width, _canvasHeight), sleepPaint);

    _drawBandLabel(canvas, 'SLEEP WINDOW', _gutterWidth + 10, wakeY / 2 - 8, ChronoTheme.textMuted);
    _drawBandLabel(canvas, 'SLEEP WINDOW', _gutterWidth + 10, sleepY + (_canvasHeight - sleepY) / 2 - 8, ChronoTheme.textMuted);
  }

  // ── 3. Fasting Buffer Bands ────────────────────────────────────────────────
  void _drawFastingBands(Canvas canvas, Size size) {
    const preBuf = ClinicalBuffers.emptyStomachPreMealBufferMinutes;
    const postBuf = ClinicalBuffers.emptyStomachPostMealBufferMinutes;

    final fastFill = Paint()..color = ChronoTheme.rose.withOpacity(0.04);
    final fastBorder = Paint()
      ..color = ChronoTheme.rose.withOpacity(0.18)
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
        _drawBandLabel(canvas, 'FASTING BUFFER (${meal.displayName})', _gutterWidth + 8, preStart + 4, ChronoTheme.rose);
      }

      final postStart = meal.endTimeMinutes * _heightPerMinute;
      final postEnd = (meal.endTimeMinutes + postBuf) * _heightPerMinute;
      if (postEnd <= _canvasHeight) {
        final r = Rect.fromLTRB(_gutterWidth + 2, postStart, size.width - 6, postEnd);
        final rRect = RRect.fromRectAndRadius(r, const Radius.circular(6));
        canvas.drawRRect(rRect, fastFill);
        canvas.drawRRect(rRect, fastBorder);
        _drawBandLabel(canvas, 'FASTING BUFFER (${meal.displayName})', _gutterWidth + 8, postStart + 4, ChronoTheme.rose);
      }
    }
  }

  // ── 4. Meal Bands (Soft Muted Sage) ─────────────────────────────────────────
  void _drawMealBands(Canvas canvas, Size size) {
    final mealFill = Paint()..color = ChronoTheme.secondary.withOpacity(0.08);
    final mealBorder = Paint()
      ..color = ChronoTheme.secondary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final meal in routine.meals) {
      final top = meal.startTimeMinutes * _heightPerMinute;
      final bottom = meal.endTimeMinutes * _heightPerMinute;
      final rect = Rect.fromLTRB(_gutterWidth + 2, top, size.width - 6, bottom);
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      canvas.drawRRect(rRect, mealFill);
      canvas.drawRRect(rRect, mealBorder);

      final timeStr = '${meal.startTimeMinutes ~/ 60}:${(meal.startTimeMinutes % 60).toString().padLeft(2, '0')}';
      _drawBandLabel(
        canvas,
        '${meal.displayName.toUpperCase()} ($timeStr)',
        _gutterWidth + 10,
        top + 6,
        ChronoTheme.secondary,
      );
    }
  }

  // ── 5. Dose Cards (Collision-Resistant & Quiet) ─────────────────────────────
  void _drawDoses(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    double lastCardBottom = -100.0;

    for (var i = 0; i < doses.length; i++) {
      final dose = doses[i];
      final targetY = dose.scheduledMinute * _heightPerMinute;
      final isTaken = dose.status == DoseStatus.taken;
      final isSelected = dose.id == selectedDoseId;

      final color = isTaken ? ChronoTheme.secondary : ChronoTheme.primary;

      // Small circular node on timeline axis
      canvas.drawCircle(Offset(_gutterWidth + 12, targetY), 5, Paint()..color = color);
      canvas.drawCircle(Offset(_gutterWidth + 12, targetY), 2.5, Paint()..color = ChronoTheme.obsidian);

      // Collision avoidance
      var cardY = targetY - 18;
      if (cardY < lastCardBottom + 4) {
        cardY = lastCardBottom + 4;
      }
      const cardHeight = 40.0;
      lastCardBottom = cardY + cardHeight;

      const cardLeft = _gutterWidth + 24;
      final cardWidth = (size.width - cardLeft - 10).clamp(140.0, 520.0);
      final cardRect = Rect.fromLTWH(cardLeft, cardY, cardWidth, cardHeight);
      final rRect = RRect.fromRectAndRadius(cardRect, const Radius.circular(8));

      // Card surface
      canvas.drawRRect(
        rRect,
        Paint()..color = isTaken ? ChronoTheme.surface : ChronoTheme.surfaceCard,
      );
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = isSelected ? color : (isTaken ? ChronoTheme.borderSubtle : ChronoTheme.border)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Card Text
      tp.text = TextSpan(
        children: [
          TextSpan(
            text: '${dose.formattedTime}  ',
            style: TextStyle(
              color: isTaken ? ChronoTheme.textDim : color,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              fontFamily: ChronoTheme.monoFont,
            ),
          ),
          TextSpan(
            text: '${dose.medicationName} (${dose.dosage})',
            style: TextStyle(
              color: isTaken ? ChronoTheme.textMuted : ChronoTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              decoration: isTaken ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      );
      tp.layout(maxWidth: cardWidth - 16);
      tp.paint(canvas, Offset(cardRect.left + 10, cardRect.top + 6));

      // Subtitle note
      final tpSub = TextPainter(
        text: TextSpan(
          text: isTaken ? 'Taken' : dose.clinicalInstruction,
          style: TextStyle(
            color: isTaken ? ChronoTheme.secondary : ChronoTheme.textSecondary,
            fontSize: 9.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: cardWidth - 16);
      tpSub.paint(canvas, Offset(cardRect.left + 10, cardRect.top + 22));
    }
  }

  // ── 6. Now Indicator (Gentle Glacial Blue Line) ─────────────────────────────
  void _drawNowIndicator(Canvas canvas, Size size) {
    if (currentMinuteOfDay < 0 || currentMinuteOfDay >= 1440) return;

    final y = currentMinuteOfDay * _heightPerMinute;

    canvas.drawLine(
      Offset(_gutterWidth - 6, y),
      Offset(size.width, y),
      Paint()
        ..color = ChronoTheme.primary.withOpacity(0.6)
        ..strokeWidth = 1.2,
    );

    canvas.drawCircle(
      Offset(_gutterWidth - 6, y),
      3.5,
      Paint()..color = ChronoTheme.primary,
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'NOW',
        style: TextStyle(
          color: ChronoTheme.primary,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(_gutterWidth - 6, y - 12));
  }

  void _drawBandLabel(Canvas canvas, String text, double x, double y, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(0.8),
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
