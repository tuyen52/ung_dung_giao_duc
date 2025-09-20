import 'dart:async';
import 'package:flutter/material.dart';

class NutrientMiniGameResult {
  /// Điểm 0..1 theo độ gần vùng vàng
  final double score0to1;
  /// Tổng “mức dinh dưỡng” 0..1 mà bé pha
  final double totalLevel;
  const NutrientMiniGameResult({required this.score0to1, required this.totalLevel});
}

/// Mini-game bón phân (không đếm giờ): bấm/nhấn giữ N–P–K để đưa mức dinh dưỡng vào vùng vàng.
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

  double _level = 0.25; // 0..1
  Timer? _holdTimer;
  late final AnimationController _pulse =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  // ----- logic -----
  double get _center => ((widget.targetLow + widget.targetHigh) / 2).clamp(0.0, 1.0);
  double get _half   => ((widget.targetHigh - widget.targetLow) / 2).clamp(0.06, 0.25);
  bool   get _inBand => (_level - _center).abs() <= _half;

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
    final closeness =
    (1.0 - ((_level - _center).abs() / (_half == 0 ? 1 : _half))).clamp(0.0, 1.0);
    Navigator.pop(
      context,
      NutrientMiniGameResult(score0to1: closeness, totalLevel: _level),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final low = _pct(widget.targetLow);
    final high = _pct(widget.targetHigh);
    final now = _pct(_level);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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

              Text('Bón phân N–P–K cho vừa đủ!',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Mục tiêu: $low–$high%  •  Đang: $now%',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
              const SizedBox(height: 6),

              // Bình + vùng vàng
              Expanded(
                child: Center(
                  child: _TankWithBand(
                    level: _level,
                    center: _center,
                    half: _half,
                    pulse: _pulse,
                  ),
                ),
              ),

              // Nút điều khiển
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
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

              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: FilledButton.icon(
                  onPressed: _finish,
                  icon: Icon(_inBand ? Icons.verified : Icons.check_circle_outline),
                  label: const Text('Áp dụng'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== UI phụ ==================

class _TankWithBand extends StatelessWidget {
  final double level;     // 0..1
  final double center;    // 0..1
  final double half;      // 0..0.5
  final Animation<double> pulse;
  const _TankWithBand({
    required this.level,
    required this.center,
    required this.half,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    const outerW = 260.0, outerH = 240.0;
    const inset = 16.0;
    const innerW = outerW - inset * 2;         // phần “ruột bình”
    const innerH = outerH - inset * 2;

    // tính toạ độ theo phần ruột (để nước không chạm viền)
    final fillTop = (1 - level) * innerH;
    final bandTop = (1 - (center + half)) * innerH;
    final bandBottom = (1 - (center - half)) * innerH;

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
            left: inset, right: inset,
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

          // Nước (fill) – không dính viền
          Positioned(
            left: inset, right: inset, top: inset,
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
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // icon chai phân
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
