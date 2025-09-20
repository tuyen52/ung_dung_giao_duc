import 'dart:async';
import 'package:flutter/material.dart';
import '../plant_assets.dart'; // nền giống các mini-game khác

class NutrientMiniGameResult {
  /// Điểm 0..1 theo độ gần vùng vàng
  final double score0to1;

  /// Tổng “mức dinh dưỡng” 0..1 mà bé pha
  final double totalLevel;

  const NutrientMiniGameResult({
    required this.score0to1,
    required this.totalLevel,
  });
}

/// Mini-game bón phân (không đếm giờ):
/// Bấm / nhấn giữ N–P–K để đưa mức dinh dưỡng vào VÙNG VÀNG (đã thu nhỏ),
/// có thêm VẠCH CHUẨN chính xác ở giữa vùng.
class NutrientMixMinigamePage extends StatefulWidget {
  final double targetLow;   // 0..1
  final double targetHigh;  // 0..1
  final int durationSec;    // Giữ để tương thích, KHÔNG dùng

  const NutrientMixMinigamePage({
    super.key,
    required this.targetLow,
    required this.targetHigh,
    this.durationSec = 20,
  });

  @override
  State<NutrientMixMinigamePage> createState() => _NutrientMixMinigamePageState();
}

class _NutrientMixMinigamePageState extends State<NutrientMixMinigamePage>
    with SingleTickerProviderStateMixin {
  // 👉 BẮT ĐẦU TỪ 0%
  double _level = 0.0; // 0..1
  Timer? _holdTimer;

  late final AnimationController _pulse =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // precache background để mượt
    precacheImage(const AssetImage(PlantAssets.bg), context);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  // ----- logic -----
  double get _baseCenter =>
      ((widget.targetLow + widget.targetHigh) / 2).clamp(0.0, 1.0);

  // half gốc của band cha
  double get _baseHalf =>
      ((widget.targetHigh - widget.targetLow) / 2).clamp(0.06, 0.25);

  // 👉 vùng vàng hiển thị & chấm điểm: THU NHỎ 1/2 để tăng độ khó
  double get _visHalf => (_baseHalf * 0.5).clamp(0.04, 0.18);

  bool get _inBand => (_level - _baseCenter).abs() <= _visHalf;

  void _add(double v) => setState(() => _level = (_level + v).clamp(0, 1));
  void _minus(double v) => setState(() => _level = (_level - v).clamp(0, 1));

  void _startHold(void Function() fn) {
    fn();
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 110), (_) => fn());
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  int _pct(double x) => (x * 100).round();

  void _finish() {
    // chấm theo vùng vàng đã thu nhỏ
    final closeness =
    (1.0 - ((_level - _baseCenter).abs() / (_visHalf == 0 ? 1 : _visHalf)))
        .clamp(0.0, 1.0);
    Navigator.pop(
      context,
      NutrientMiniGameResult(score0to1: closeness, totalLevel: _level),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final visLow = (_baseCenter - _visHalf).clamp(0.0, 1.0);
    final visHigh = (_baseCenter + _visHalf).clamp(0.0, 1.0);

    final low = _pct(visLow);
    final high = _pct(visHigh);
    final now = _pct(_level);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 👉 nền giống các màn khác
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
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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

                Text(
                  'Bón phân N–P–K cho vừa đủ!',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mục tiêu: $low–$high%  •  Đang: $now%',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 10),

                // Bình + vùng vàng (đã thu nhỏ) + Vạch chuẩn
                Expanded(
                  child: Center(
                    child: _TankWithBandAndLine(
                      level: _level,
                      center: _baseCenter,
                      half: _visHalf,
                      pulse: _pulse,
                    ),
                  ),
                ),

                // Nút điều khiển (to hơn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DoseButton(
                        color: const Color(0xFFE53935),
                        icon: 'N',
                        label: '+5%',
                        onTap: () => _add(0.05),
                        onHoldStart: () => _startHold(() => _add(0.05)),
                        onHoldEnd: _stopHold,
                      ),
                      _DoseButton(
                        color: const Color(0xFFFB8C00),
                        icon: 'P',
                        label: '+10%',
                        onTap: () => _add(0.10),
                        onHoldStart: () => _startHold(() => _add(0.10)),
                        onHoldEnd: _stopHold,
                      ),
                      _DoseButton(
                        color: const Color(0xFF8BC34A),
                        icon: 'K',
                        label: '+15%',
                        onTap: () => _add(0.15),
                        onHoldStart: () => _startHold(() => _add(0.15)),
                        onHoldEnd: _stopHold,
                      ),
                      _DoseButton(
                        color: Colors.blueGrey,
                        icon: '↺',
                        label: '−5%',
                        onTap: () => _minus(0.05),
                        onHoldStart: () => _startHold(() => _minus(0.05)),
                        onHoldEnd: _stopHold,
                      ),
                    ],
                  ),
                ),

                // Nút Áp dụng
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilledButton.icon(
                    onPressed: _finish,
                    icon: Icon(_inBand ? Icons.verified : Icons.check_circle_outline),
                    label: const Text('Áp dụng'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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

// ================== UI phụ ==================

/// “Bình” chứa dung dịch + VÙNG VÀNG (đã thu nhỏ) + VẠCH CHUẨN chính xác
class _TankWithBandAndLine extends StatelessWidget {
  final double level;     // 0..1
  final double center;    // 0..1
  final double half;      // 0..0.5 (đã thu nhỏ)
  final Animation<double> pulse;

  const _TankWithBandAndLine({
    required this.level,
    required this.center,
    required this.half,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    const outerW = 260.0, outerH = 240.0;
    const inset = 16.0;
    const innerW = outerW - inset * 2; // phần “ruột bình”
    const innerH = outerH - inset * 2;

    // toạ độ theo phần ruột (để nước không chạm viền)
    final fillTop = (1 - level) * innerH;
    final bandTop = (1 - (center + half)) * innerH;
    final bandBottom = (1 - (center - half)) * innerH;
    final lineY = (1 - center) * innerH; // vạch chuẩn

    return SizedBox(
      width: outerW,
      height: outerH,
      child: Stack(
        children: [
          // Khung bình
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.blueGrey.shade200, width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
              ),
            ),
          ),

          // Vùng vàng (nằm trong ruột bình, không chạm viền)
          Positioned(
            left: inset,
            right: inset,
            top: inset + bandTop,
            height: (bandBottom - bandTop).clamp(12.0, innerH),
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.22 + 0.10 * pulse.value),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade600),
                ),
              ),
            ),
          ),

          // VẠCH CHUẨN chính xác (giữa vùng vàng)
          Positioned(
            left: inset + 4,
            right: inset + 4,
            top: inset + lineY - 1,
            height: 2,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => Container(
                color: Color.lerp(Colors.orange, Colors.green, pulse.value),
              ),
            ),
          ),

          // Nhãn “Vạch chuẩn”
          Positioned(
            left: 0,
            right: 0,
            top: (inset + lineY - 24).clamp(0.0, outerH - 24),
            child: const IgnorePointer(
              child: Text(
                'Vạch chuẩn',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.brown),
              ),
            ),
          ),

          // Nước (fill) – chỉ trong “ruột bình”
          Positioned(
            left: inset,
            right: inset,
            top: inset,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.bottomCenter,
                width: innerW,
                height: innerH,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: innerW,
                  height: innerH - fillTop,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // icon chai phân (giữ cho vui mắt)
          const Positioned(top: 8, left: 10, child: Text('🧪', style: TextStyle(fontSize: 28))),
        ],
      ),
    );
  }
}

class _DoseButton extends StatelessWidget {
  final Color color;
  final String icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const _DoseButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onHoldStart(),
      onLongPressEnd: (_) => onHoldEnd(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // to hơn
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
