import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/plant_core.dart';

class GaugeRing extends StatelessWidget {
  final String label;
  final Widget icon;
  final double value; // 0..100
  final Band band;
  final double size;

  const GaugeRing({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.band,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _GaugePainter(value: value, band: band),
            child: Center(child: icon),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value.toStringAsFixed(0),
            style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0..100
  final Band band;
  _GaugePainter({required this.value, required this.band});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 6;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0xFFE9EDF0);

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10
      ..color = Colors.blueGrey;

    final bandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.amber.withOpacity(0.6);

    // Vòng nền
    canvas.drawCircle(c, r, base);

    // Dải vàng (band)
    final startAngle = -math.pi * 0.5; // bắt đầu từ 12h
    final sweepBand = (band.high - band.low) / 100.0 * 2 * math.pi;
    final startBand = startAngle + (band.low / 100.0) * 2 * math.pi;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), startBand, sweepBand,
        false, bandPaint);

    // Giá trị hiện tại
    final sweep = (value / 100.0) * 2 * math.pi;
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), startAngle, sweep, false, progress);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.band != band;
}
