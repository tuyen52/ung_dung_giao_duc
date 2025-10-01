import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/plant_core.dart';

class GaugeRing extends StatelessWidget {
  final String label;
  final Widget icon;
  final double value; // 0..100
  final Band band;    // vùng mục tiêu; nếu low==high coi như không vẽ
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
            painter: _GaugePainter(
              value: value.clamp(0, 100).toDouble(),
              band: band,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(height: 4),
                  Text(
                    value.clamp(0, 100).toStringAsFixed(0),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0..100
  final Band band;

  _GaugePainter({
    required this.value,
    required this.band,
  });

  static const double _baseW = 10;   // bề rộng vòng nền & progress
  static const double _progW = 10;
  static const double _bandW = 6;    // bề rộng “vùng vàng” (mảnh hơn)
  static const double _gap   = 2;    // khoảng cách giữa band và progress

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 6;

    // vẽ “vùng vàng” ở vòng trong để không che progress
    final rBand = r - (_progW / 2) - (_bandW / 2) - _gap;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _baseW
      ..color = const Color(0xFFE9EDF0); // nền xám nhạt

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _progW
      ..color = Colors.green; // ✅ CHỈ SỐ HIỆN TẠI = MÀU XANH LÁ

    final bandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _bandW
      ..color = Colors.amber.withOpacity(0.95); // “vùng vàng”

    // nền
    canvas.drawCircle(center, r, base);

    // “vùng vàng” – chỉ vẽ nếu band có span > 0 (UI đã map Band(0,100) -> Band(0,0) khi chưa yêu cầu)
    final span = (band.high - band.low).clamp(0, 100).toDouble();
    if (span > 0.0001) {
      final startBand = -math.pi * 0.5 + (band.low / 100.0) * 2 * math.pi;
      final sweepBand = (span / 100.0) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: rBand),
        startBand,
        sweepBand,
        false,
        bandPaint,
      );
    }

    // giá trị hiện tại (xanh lá)
    final start = -math.pi * 0.5; // từ 12h
    final sweep = (value / 100.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      start,
      sweep,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.band.low != band.low || old.band.high != band.high;
}
