import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../plant_assets.dart'; // dùng cùng background với mini game tưới nước

class LightMiniGameResult {
  final double score0to1;
  final int elapsedMs; // chỉ để tham khảo
  const LightMiniGameResult({required this.score0to1, required this.elapsedMs});
}

/// Mini-game Ánh sáng: KÉO MÂY CHE NẮNG (KHÔNG đếm giờ)
/// - Kéo thả mây để che bớt mặt trời.
/// - Ánh sáng = 1 - tỉ lệ mặt trời bị che.
/// - Mục tiêu: đưa Ánh sáng vào "Vùng vàng" (targetLow..targetHigh).
class LightAdjustMinigamePage extends StatefulWidget {
  final double targetLow;   // 0..1
  final double targetHigh;  // 0..1
  final double current;     // 0..1
  final int durationSec;    // giữ để tương thích, không dùng

  const LightAdjustMinigamePage({
    super.key,
    required this.targetLow,
    required this.targetHigh,
    required this.current,
    this.durationSec = 15,
  });

  @override
  State<LightAdjustMinigamePage> createState() => _LightAdjustMinigamePageState();
}

class _LightAdjustMinigamePageState extends State<LightAdjustMinigamePage>
    with SingleTickerProviderStateMixin {
  // ====== cấu hình/ trạng thái ======
  final double _sunDia = 120;
  final List<_Cloud> _clouds = [];
  late final DateTime _start;

  // vùng vàng (đã thu nhỏ 1/2 so với dải gốc)
  late double _center;     // tâm vùng vàng
  late double _tolerance;  // nửa bề rộng vùng vàng

  // nháy vùng vàng
  late final AnimationController _pulse =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  // key để đo kích thước sky (đúng hệ toạ độ)
  final GlobalKey _skyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();

    // tính tâm & tolerance từ mục tiêu, sau đó THU NHỎ 1/2
    final baseHalf = ((widget.targetHigh - widget.targetLow).abs() / 2.0);
    _center = ((widget.targetLow + widget.targetHigh) / 2.0).clamp(0.0, 1.0);
    _tolerance = (baseHalf * 0.5).clamp(0.04, 0.18); // 🔧 nhỏ hơn một nửa

    // seed mây sau 1 frame khi đã có size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final w = _skyWidth;
      _seedClouds(w, (1.0 - widget.current).clamp(0.0, 1.0));
      setState(() {}); // render lần đầu với mây
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // precache background để mượt
    precacheImage(const AssetImage(PlantAssets.bg), context);
  }

  double get _skyWidth {
    final box = _skyKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size.width ?? 360.0;
  }

  double get _skyHeight {
    final box = _skyKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size.height ?? 260.0;
  }

  void _seedClouds(double skyW, double wantCover) {
    _clouds.clear();
    final rnd = math.Random();
    const n = 4;
    for (int i = 0; i < n; i++) {
      final w = 120 + rnd.nextInt(80); // 120..200
      final h = 60 + rnd.nextInt(24);  // 60..84
      final y = 40 + rnd.nextInt(120);
      final x = (i.isEven ? skyW * 0.15 : skyW * 0.55) + (rnd.nextDouble() - 0.5) * 60.0;
      _clouds.add(_Cloud(x: x, y: y.toDouble(), w: w.toDouble(), h: h.toDouble()));
    }
    // đẩy nhẹ để gần wantCover
    final sun = _sunRect(skyW);
    final currentCover = _coverRatioAccurate(sun);
    final dir = (wantCover - currentCover);
    for (final c in _clouds) {
      c.x += dir.sign * 14;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ====== hình học / ánh sáng ======
  Rect _sunRect(double skyWidth) {
    final sunX = skyWidth / 2 - _sunDia / 2;
    const sunY = 40.0;
    return Rect.fromLTWH(sunX, sunY, _sunDia, _sunDia);
  }

  /// TÍNH CHUẨN HƠN: lấy mẫu điểm trong hình tròn mặt trời (grid 32x32),
  /// đếm phần trăm điểm nằm dưới bất kỳ đám mây nào.
  double _coverRatioAccurate(Rect sun) {
    const N = 32; // 1024 điểm – nhẹ
    int inCircle = 0, covered = 0;
    final cx = sun.center.dx, cy = sun.center.dy;
    final r = sun.width / 2;
    for (int iy = 0; iy < N; iy++) {
      for (int ix = 0; ix < N; ix++) {
        final px = sun.left + (ix + 0.5) * sun.width / N;
        final py = sun.top + (iy + 0.5) * sun.height / N;
        final dx = px - cx, dy = py - cy;
        if (dx * dx + dy * dy <= r * r) {
          inCircle++;
          bool underCloud = false;
          for (final c in _clouds) {
            if (px >= c.x && px <= c.x + c.w && py >= c.y && py <= c.y + c.h) {
              underCloud = true;
              break;
            }
          }
          if (underCloud) covered++;
        }
      }
    }
    if (inCircle == 0) return 0.0;
    return (covered / inCircle).clamp(0.0, 1.0);
  }

  double _currentLight() {
    final w = _skyWidth;
    final sun = _sunRect(w);
    final cover = _coverRatioAccurate(sun);
    return (1.0 - cover).clamp(0.0, 1.0);
  }

  void _finish() {
    final elapsedMs = DateTime.now().difference(_start).inMilliseconds;
    final light = _currentLight();
    // chấm theo độ gần tâm vùng vàng
    final closeness =
    (1.0 - ((light - _center).abs() / (_tolerance == 0 ? 1 : _tolerance)))
        .clamp(0.0, 1.0);
    Navigator.pop(
      context,
      LightMiniGameResult(score0to1: closeness, elapsedMs: elapsedMs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = _currentLight();
    final pct = (light * 100).round();
    final inBand = (light - _center).abs() <= _tolerance;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 👉 nền giống mini game tưới nước
          Image.asset(PlantAssets.bg, fit: BoxFit.cover),
          // overlay nhẹ để chữ dễ đọc
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.00),
                  Colors.white.withOpacity(0.10),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header (không có đồng hồ)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Text('Kéo mây che bớt mặt trời!',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Một số cây thích BÓNG RÂM MỘT PHẦN – hãy che vừa đủ.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                const SizedBox(height: 10),

                // Khung bầu trời + mây kéo thả
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SkyWithSunAndClouds(
                    key: _skyKey,
                    sunDia: _sunDia,
                    clouds: _clouds,
                    pulse: _pulse,
                    targetCenter: _center,
                    tolerance: _tolerance,
                    onChanged: () => setState(() {}),
                  ),
                ),

                const SizedBox(height: 14),

                // Đồng hồ đo ánh sáng + vùng vàng (đã thu nhỏ)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _LightMeter(
                    value: light,
                    center: _center,
                    tolerance: _tolerance,
                    pulse: _pulse,
                  ),
                ),

                const SizedBox(height: 10),

                // Chip trạng thái
                _StatusChip(
                  text: inBand
                      ? 'ĐÚNG VÙNG VÀNG • $pct%'
                      : (light < _center ? 'Thiếu sáng • $pct%' : 'Thừa sáng • $pct%'),
                  color: inBand ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                ),

                const Spacer(),

                // Nút áp dụng
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: _finish,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Áp dụng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======= WIDGETS PHỤ =======

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wb_sunny, color: color, size: 18),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

class _Cloud {
  double x, y, w, h;
  _Cloud({required this.x, required this.y, required this.w, required this.h});
}

/// Bầu trời + mặt trời + mây kéo thả + dải “vùng vàng”
class _SkyWithSunAndClouds extends StatefulWidget {
  final double sunDia;
  final List<_Cloud> clouds;
  final Animation<double> pulse;
  final double targetCenter;
  final double tolerance;
  final VoidCallback onChanged;

  const _SkyWithSunAndClouds({
    super.key,
    required this.sunDia,
    required this.clouds,
    required this.pulse,
    required this.targetCenter,
    required this.tolerance,
    required this.onChanged,
  });

  @override
  State<_SkyWithSunAndClouds> createState() => _SkyWithSunAndCloudsState();
}

class _SkyWithSunAndCloudsState extends State<_SkyWithSunAndClouds> {
  final GlobalKey _stackKey = GlobalKey(); // toạ độ cha (Stack)
  _Cloud? _dragging;
  Offset _offsetInCloud = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        const h = 260.0;

        final sunX = w / 2 - widget.sunDia / 2;
        const sunY = 40.0;
        final sun = Rect.fromLTWH(sunX, sunY, widget.sunDia, widget.sunDia);

        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0x80E3F2FD),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Stack(
            key: _stackKey,
            children: [
              // trời nhẹ
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99B3E5FC), Color(0x99E1F5FE)],
                    ),
                  ),
                ),
              ),

              // mặt trời
              Positioned(
                left: sun.left,
                top: sun.top,
                child: Container(
                  width: sun.width,
                  height: sun.height,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Color(0xFFFFF176), Color(0xFFFFC107)]),
                    boxShadow: [BoxShadow(color: Color(0x66FFC107), blurRadius: 20)],
                  ),
                  alignment: Alignment.center,
                  child: const Text('☀️', style: TextStyle(fontSize: 36)),
                ),
              ),

              // vùng vàng (giải thích mục tiêu)
              Positioned(
                left: 16,
                right: 16,
                top: sun.bottom + 24,
                height: 20,
                child: AnimatedBuilder(
                  animation: widget.pulse,
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.22 + 0.10 * widget.pulse.value),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade600),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Vùng vàng: đủ sáng – không quá gắt',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Colors.brown),
                    ),
                  ),
                ),
              ),

              // mây kéo thả
              ...widget.clouds.map((c) {
                return Positioned(
                  left: c.x,
                  top: c.y,
                  child: GestureDetector(
                    onPanStart: (d) {
                      // toạ độ local theo Stack cha
                      final box = _stackKey.currentContext!.findRenderObject() as RenderBox;
                      final local = box.globalToLocal(d.globalPosition);
                      _dragging = c;
                      _offsetInCloud = Offset(local.dx - c.x, local.dy - c.y);
                    },
                    onPanUpdate: (d) {
                      if (_dragging == null) return;
                      final box = _stackKey.currentContext!.findRenderObject() as RenderBox;
                      final local = box.globalToLocal(d.globalPosition);
                      setState(() {
                        _dragging!.x =
                            (local.dx - _offsetInCloud.dx).clamp(0.0, w - _dragging!.w);
                        _dragging!.y =
                            (local.dy - _offsetInCloud.dy).clamp(0.0, h - _dragging!.h);
                      });
                      widget.onChanged(); // cập nhật đồng hồ đo
                    },
                    onPanEnd: (_) => _dragging = null,
                    child: _CloudWidget(w: c.w, h: c.h),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _CloudWidget extends StatelessWidget {
  final double w, h;
  const _CloudWidget({required this.w, required this.h});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: w, height: h, child: CustomPaint(painter: _CloudPainter()));
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final p = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.1, size.height * 0.35, size.width * 0.8, size.height * 0.45),
          const Radius.circular(22)))
      ..addOval(Rect.fromCircle(center: Offset(size.width * 0.25, size.height * 0.35), radius: size.height * 0.28))
      ..addOval(Rect.fromCircle(center: Offset(size.width * 0.50, size.height * 0.25), radius: size.height * 0.33))
      ..addOval(Rect.fromCircle(center: Offset(size.width * 0.75, size.height * 0.35), radius: size.height * 0.30));
    canvas.drawPath(p, base);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFB0BEC5);
    canvas.drawPath(p, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Đồng hồ đo ánh sáng hiện tại (0..1) + vùng vàng
class _LightMeter extends StatelessWidget {
  final double value, center, tolerance;
  final Animation<double> pulse;
  const _LightMeter({
    required this.value,
    required this.center,
    required this.tolerance,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        const trackH = 20.0;
        final goldW = (tolerance * 2 * w).clamp(24.0, w);
        final goldL = (center * w - goldW / 2).clamp(0.0, w - goldW);
        final vX = (value * w).clamp(0.0, w);

        return Container(
          width: w,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
          ),
          alignment: Alignment.center,
          child: Stack(
            children: [
              Positioned(
                left: 12,
                right: 12,
                top: 14,
                height: trackH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(color: const Color(0xFFE3F2FD)),
                ),
              ),
              Positioned(
                left: 12 + goldL,
                top: 14,
                height: trackH,
                width: goldW,
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.22 + 0.10 * pulse.value),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade600),
                    ),
                  ),
                ),
              ),
              // kim giá trị hiện tại
              Positioned(
                left: 12 + vX - 1.5,
                top: 10,
                height: trackH + 8,
                width: 3,
                child: Container(color: const Color(0xFF1E88E5)),
              ),
            ],
          ),
        );
      },
    );
  }
}
