import 'dart:async';
import 'package:flutter/material.dart';
import '../core/plant_core.dart'; // dùng PlantStage
import '../plant_assets.dart'; // dùng chung background với màn chính

class WateringMiniGameResult {
  final double score0to1;
  final int elapsedMs;
  const WateringMiniGameResult(
      {required this.score0to1, required this.elapsedMs});
}

/// Mini-game tưới nước: nhấn & giữ để đổ nước; canh mực nước trùng “vạch chuẩn”.
class WateringMinigamePage extends StatefulWidget {
  final double targetLow; // 0..1
  final double targetHigh; // 0..1
  final int durationSec;
  final PlantStage stage; // theo giai đoạn

  const WateringMinigamePage({
    super.key,
    required this.targetLow,
    required this.targetHigh,
    required this.stage,
    this.durationSec = 15,
  });

  @override
  State<WateringMinigamePage> createState() => _WateringMinigamePageState();
}

class _WateringMinigamePageState extends State<WateringMinigamePage>
    with SingleTickerProviderStateMixin {
  // tuning theo stage
  late final double _tolerance; // vùng chấp nhận quanh vạch (0..1)
  late final double _pourSpeedPerSec; // tốc độ đổ
  static const double _drainPerSec = 0.06; // rò khi thả

  late Timer _timer;
  late DateTime _startAll;
  DateTime _lastTick = DateTime.now();

  double _level = 0.30; // 0..1
  bool _pouring = false;

  int _timeNearLineMs = 0;
  int _left = 0;

  late final AnimationController _pulse =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  // Vạch chuẩn = giữa targetLow & targetHigh
  double get _line =>
      ((widget.targetLow + widget.targetHigh) / 2.0).clamp(0.0, 1.0);
  bool _nearLine(double v) => (v - _line).abs() <= _tolerance;

  @override
  void initState() {
    super.initState();
    switch (widget.stage) {
      case PlantStage.seed:
        _tolerance = 0.12;
        _pourSpeedPerSec = 0.36;
        break; // ±12%
      case PlantStage.seedling:
        _tolerance = 0.10;
        _pourSpeedPerSec = 0.42;
        break;
      case PlantStage.adult:
        _tolerance = 0.08;
        _pourSpeedPerSec = 0.45;
        break; // ±8%
      case PlantStage.flowering:
        _tolerance = 0.06;
        _pourSpeedPerSec = 0.55;
        break; // ±6%
    }

    _startAll = DateTime.now();
    _left = widget.durationSec;
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // precache background để mượt
    precacheImage(const AssetImage(PlantAssets.bg), context);
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _tick(Timer t) {
    final now = DateTime.now();
    final dt = now.difference(_lastTick);
    _lastTick = now;

    final seconds = dt.inMilliseconds / 1000.0;
    double next =
        _level + ((_pouring ? _pourSpeedPerSec : -_drainPerSec) * seconds);
    next = next.clamp(0.0, 1.0);

    if (_nearLine(next)) _timeNearLineMs += dt.inMilliseconds;

    final elapsed = now.difference(_startAll).inSeconds;
    final remain = (widget.durationSec - elapsed).clamp(0, widget.durationSec);

    setState(() {
      _level = next;
      _left = remain;
    });

    if (remain <= 0) _finish();
  }

  void _finish() {
    if (_timer.isActive) _timer.cancel();
    final elapsedMs = DateTime.now().difference(_startAll).inMilliseconds;

    final closeness = (1.0 -
        ((_level - _line).abs() / (_tolerance == 0 ? 1 : _tolerance)))
        .clamp(0.0, 1.0);
    final timeRatio =
    elapsedMs <= 0 ? 0.0 : (_timeNearLineMs / elapsedMs).clamp(0.0, 1.0);
    final score = (0.6 * closeness + 0.4 * timeRatio).clamp(0.0, 1.0);

    Navigator.pop(
      context,
      WateringMiniGameResult(score0to1: score, elapsedMs: elapsedMs),
    );
  }

  String _stageLabel(PlantStage s) {
    switch (s) {
      case PlantStage.seed:
        return 'Hạt';
      case PlantStage.seedling:
        return 'Cây con';
      case PlantStage.adult:
        return 'Trưởng thành';
      case PlantStage.flowering:
        return 'Ra hoa';
    }
  }

  // ============== WIDGET BUILDERS ==============

  Widget _buildPortraitLayout() {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Header được xử lý bên ngoài, phần này chỉ chứa nội dung chính
        const SizedBox(height: 48), // Khoảng trống cho header
        Text('Tưới nước canh đúng vạch!',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Giữ nút để đổ nước • Thả để dừng',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
        const SizedBox(height: 2),
        Text(
          'Giai đoạn: ${_stageLabel(widget.stage)} • Dung sai ±${(_tolerance * 100).round()}%',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.black45),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildPotScene()),
        _buildControls(),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Khu vực chậu cây, co giãn cho vừa
        Expanded(
          flex: 3, // Chiếm nhiều không gian hơn
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FittedBox(child: _buildPotScene()),
          ),
        ),
        // Cột điều khiển bên phải
        Expanded(
          flex: 2, // Chiếm ít không gian hơn
          child: _buildControls(isLandscape: true),
        ),
      ],
    );
  }

  /// Tách riêng khu vực chậu cây để tái sử dụng
  Widget _buildPotScene() {
    return Center(
      child: _FaucetPotScene(
        level: _level,
        line: _line,
        tolerance: _tolerance,
        pouring: _pouring,
        pulse: _pulse,
      ),
    );
  }

  /// Tách riêng cụm điều khiển để tái sử dụng
  Widget _buildControls({bool isLandscape = false}) {
    final pctNow = (_level * 100).round();
    final inNear = _nearLine(_level);
    final statusText = inNear ? 'ĐÚNG VẠCH' : (_level < _line ? 'THIẾU' : 'THỪA');
    final statusColor = inNear ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    final content = Column(
      mainAxisAlignment: isLandscape ? MainAxisAlignment.center : MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10, top: isLandscape ? 20 : 0),
          child: _StatusChip(text: '$statusText • $pctNow%', color: statusColor),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pouring = true),
            onTapUp: (_) => setState(() => _pouring = false),
            onTapCancel: () => setState(() => _pouring = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: _pouring ? const Color(0xFF0288D1) : const Color(0xFF29B6F6),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.opacity, color: Colors.white),
                  SizedBox(width: 8),
                  Text('NHẤN & GIỮ',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: isLandscape ? 20 : 14),
          child: FilledButton.icon(
            onPressed: _finish,
            icon: const Icon(Icons.check_circle),
            label: const Text('Xong'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              elevation: 6,
            ),
          ),
        ),
      ],
    );

    return isLandscape
        ? SingleChildScrollView(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: content))
        : content;
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nền và overlay
          Image.asset(PlantAssets.bg, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.00),
                  Colors.white.withOpacity(0.10)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Layout chính
          SafeArea(
            child: Stack(
              children: [
                // Bố cục thay đổi theo chiều xoay
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: orientation == Orientation.portrait
                      ? _buildPortraitLayout()
                      : _buildLandscapeLayout(),
                ),

                // Header luôn nằm trên cùng
                Positioned(
                  top: 8,
                  left: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _TimerPill(secondsLeft: _left),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ... CÁC WIDGET PHỤ KHÁC GIỮ NGUYÊN ...
class _TimerPill extends StatelessWidget {
  final int secondsLeft;
  const _TimerPill({required this.secondsLeft});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)
        ],
      ),
      child: Row(children: [
        const Icon(Icons.timer, size: 18),
        const SizedBox(width: 6),
        Text('${secondsLeft}s',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _FaucetPotScene extends StatelessWidget {
  final double level; // 0..1
  final double line; // 0..1
  final double tolerance; // 0..1
  final bool pouring;
  final Animation<double> pulse;

  const _FaucetPotScene({
    required this.level,
    required this.line,
    required this.tolerance,
    required this.pouring,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    const sceneH = 380.0;
    const potW = 220.0;
    const potH = 220.0; // vuông
    const potTop = 64.0; // hạ chậu để chừa khoảng dòng nước
    const inner = 6.0; // khoảng đệm

    const streamTop = 0.0; // dòng nước bắt đầu từ mép trên

    final innerHeight = potH - inner * 2;
    final waterSurfaceY = potTop + inner + (1.0 - level) * innerHeight;

    return SizedBox(
      width: potW + 160,
      height: sceneH,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (pouring)
            Positioned(
              top: streamTop,
              child: Container(
                width: 12,
                height: (waterSurfaceY - streamTop).clamp(0.0, potH + 120.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF81D4FA), Color(0xFF4FC3F7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FC3F7).withOpacity(0.35),
                      blurRadius: 8,
                    )
                  ],
                ),
              ),
            ),
          Positioned(
            top: potTop,
            child: _PotWithWater(
              width: potW,
              height: potH,
              innerPad: inner,
              level: level,
              lineRatioFromTop: (1.0 - line),
              toleranceRatio: tolerance,
              pulse: pulse,
            ),
          ),
        ],
      ),
    );
  }
}

class _PotWithWater extends StatelessWidget {
  final double width;
  final double height;
  final double innerPad; // khoảng cách viền -> mặt trong
  final double level; // 0..1
  final double lineRatioFromTop; // 0..1 theo inner
  final double toleranceRatio; // 0..1 theo inner
  final Animation<double> pulse;

  const _PotWithWater({
    required this.width,
    required this.height,
    required this.innerPad,
    required this.level,
    required this.lineRatioFromTop,
    required this.toleranceRatio,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final innerW = width - innerPad * 2;
    final innerH = height - innerPad * 2;

    final waterTop = (1.0 - level) * innerH;
    final lineY = lineRatioFromTop * innerH;
    final tolPx = (toleranceRatio * innerH).clamp(4.0, innerH);

    return SizedBox(
      width: width,
      height: height + 4,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey.shade200, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            left: innerPad,
            right: innerPad,
            top: innerPad + waterTop,
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(6)),
              child: Container(
                height: innerH - waterTop,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF90CAF9), Color(0xFF64B5F6)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: innerPad + 6,
            right: innerPad + 6,
            top: innerPad + (lineY - tolPx),
            height: (tolPx * 2).clamp(6.0, innerH),
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.20 + 0.10 * pulse.value),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          Positioned(
            left: innerPad + 4,
            right: innerPad + 4,
            top: innerPad + lineY - 1,
            height: 2,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => Container(
                color: Color.lerp(Colors.orange, Colors.green, pulse.value),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: (innerPad + lineY - tolPx - 22).clamp(0.0, height - 22),
            child: const IgnorePointer(
              child: Text(
                'Vạch chuẩn',
                textAlign: TextAlign.center,
                style:
                TextStyle(fontWeight: FontWeight.w800, color: Colors.brown),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.info_rounded, color: color, size: 18),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}