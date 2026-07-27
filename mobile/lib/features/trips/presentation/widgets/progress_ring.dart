import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';

/// A ring drawn around something, filled in proportion to how far along it is.
///
/// Shared on purpose. A trip that is on its third day of seven and a shopping
/// list with three items left are the same shape of fact, and drawing them the
/// same way is what makes the app read as one product rather than four screens
/// built at four different times.
///
/// A painter rather than [CircularProgressIndicator]: that one animates its way
/// to the value, which is right for a download and wrong for a fact that was
/// already true when the screen opened.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.size,
    required this.colour,
    this.value,
    this.stroke = 3,
    this.child,
  });

  final double size;
  final Color colour;

  /// 0 to 1, or null when there is no progress to show and only the neutral
  /// track is drawn — an upcoming trip has not started running yet.
  final double? value;

  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value,
          colour: colour,
          stroke: stroke,
          track: AppColors.border,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.colour,
    required this.stroke,
    required this.track,
  });

  final double? value;
  final Color colour;
  final double stroke;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    final progress = value;
    if (progress == null || progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      // From twelve o'clock, clockwise, the way anybody reading a dial expects.
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.colour != colour ||
      old.stroke != stroke ||
      old.track != track;
}
