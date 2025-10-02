import 'dart:async';
import 'package:flutter/material.dart';
import '../core/plant_core.dart';
import '../plant_assets.dart';

class WateringMiniGameResult {
  /// Điểm nước cộng thẳng vào chỉ số: 0 hoặc 5/10/15/20 (0 nếu chưa chạm mốc 5)
  final int addedPoints;
  /// Mực nước (0..1) tại thời điểm bấm Xong – chỉ để debug/telemetry nếu cần
  final double finalLevel;
  final int elapsedMs; // vẫn giữ để tương thích, nhưng không giới hạn thời gian
  const WateringMiniGameResult({
    required this.addedPoints,
    required this.finalLevel,
    required this.elapsedMs,
  });
}

/// Mini-game tưới nước: Nhấn & giữ để đổ. Nhận **mốc cao nhất đã CHẠM/QUA**: 5/10/15/20.
class WateringMinigamePage extends StatefulWidget {
  final PlantStage stage;

  const WateringMinigamePage({
    super.key,
    required this.stage,
  });

  @override
  State<WateringMinigamePage> createState() => _WateringMinigamePageState();
}

class _WateringMinigamePageState extends State<WateringMinigamePage>
    with SingleTickerProviderStateMixin {
  // ===== Tuning theo stage (tốc độ đổ + rò)
  late final double _pourSpeedPerSec; // tốc độ đổ (0..1 / giây)
  static const double _drainPerSec = 0.06; // tốc độ rò khi thả

  // 4 mốc cộng điểm
  static const List<int> _marks = [5, 10, 15, 20];
  static const int _maxMark = 20;
  static final List<double> _markFractions =
  _marks.map((m) => m / _maxMark).toList(); // [0.25, 0.5, 0.75, 1.0]

  // ticker nội bộ (chỉ để cập nhật vật lý, KHÔNG đếm ngược)
  late Timer _timer;
  late DateTime _startAll;
  DateTime _lastTick = DateTime.now();

  double _level = 0.30; // 0..1
  bool _pouring = false;

  late final AnimationController _pulse =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    switch (widget.stage) {
      case PlantStage.seed:
        _pourSpeedPerSec = 0.36;
        break;
      case PlantStage.seedling:
        _pourSpeedPerSec = 0.42;
        break;
      case PlantStage.adult:
        _pourSpeedPerSec = 0.45;
        break;
      case PlantStage.flowering:
        _pourSpeedPerSec = 0.55;
        break;
    }

    _startAll = DateTime.now();
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

    setState(() {
      _level = next;
    });
  }

  /// Trả về index mốc cao nhất đã **chạm hoặc vượt**; -1 nếu chưa đạt mốc 5.
  int _achievedMarkIndex(double level) {
    for (int i = _markFractions.length - 1; i >= 0; i--) {
      if (level + 1e-9 >= _markFractions[i]) return i; // chạm/vượt mốc
    }
    return -1;
  }

  void _finish() {
    if (_timer.isActive) _timer.cancel();

    final elapsedMs = DateTime.now().difference(_startAll).inMilliseconds;
    final idx = _achievedMarkIndex(_level);
    final added = idx >= 0 ? _marks[idx] : 0;

    Navigator.pop(
      context,
      WateringMiniGameResult(
        addedPoints: added,
        finalLevel: _level,
        elapsedMs: elapsedMs,
      ),
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

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final theme = Theme.of(context);
    final achieved = _achievedMarkIndex(_level); // mốc hiện tại đã đạt

    Widget buildControls({bool isLandscape = false}) {
      final content = Column(
        mainAxisAlignment: isLandscape ? MainAxisAlignment.center : MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 10, top: isLandscape ? 20 : 0),
            child: _StatusChip(
              text: 'Mốc đã đạt: ${achieved >= 0 ? _marks[achieved] : 0}',
              color: achieved >= 0 ? const Color(0xFF2E7D32) : const Color(0xFF455A64),
            ),
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
          ? SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: content))
          : content;
    }

    Widget buildPotScene() => Center(
      child: _FaucetPotScene(
        level: _level,
        pouring: _pouring,
        pulse: _pulse,
        marks: _marks,
        markFractions: _markFractions,
        achievedIndex: achieved,
      ),
    );

    Widget portrait() => Column(
      children: [
        const SizedBox(height: 48),
        Text('Tưới nước & chọn mốc điểm',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Giữ nút để đổ nước • Thả để dừng',
            style:
            theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
        const SizedBox(height: 2),
        Text(
          'Giai đoạn: ${_stageLabel(widget.stage)}',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.black45),
        ),
        const SizedBox(height: 6),
        Expanded(child: buildPotScene()),
        buildControls(),
      ],
    );

    Widget landscape() => Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FittedBox(child: buildPotScene()),
          ),
        ),
        Expanded(flex: 2, child: buildControls(isLandscape: true)),
      ],
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
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
          SafeArea(
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: orientation == Orientation.portrait
                      ? portrait()
                      : landscape(),
                ),
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
                // KHÔNG còn TimerPill / đếm thời gian
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======= WIDGET PHỤ =======

class _FaucetPotScene extends StatelessWidget {
  final double level; // 0..1
  final bool pouring;
  final Animation<double> pulse;
  final List<int> marks; // [5,10,15,20]
  final List<double> markFractions; // [0.25,0.5,0.75,1.0]
  final int achievedIndex; // mốc cao nhất đã đạt (-1 nếu chưa đạt)

  const _FaucetPotScene({
    required this.level,
    required this.pouring,
    required this.pulse,
    required this.marks,
    required this.markFractions,
    required this.achievedIndex,
  });

  @override
  Widget build(BuildContext context) {
    const sceneH = 380.0;
    const potW = 220.0;
    const potH = 220.0; // vuông
    const potTop = 64.0; // hạ chậu để chừa khoảng dòng nước
    const inner = 6.0;

    const streamTop = 0.0;
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
              marks: marks,
              markFractions: markFractions,
              achievedIndex: achievedIndex,
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
  final List<int> marks;
  final List<double> markFractions; // 0..1 từ đáy lên
  final int achievedIndex; // -1 nếu chưa đạt mốc 5
  final Animation<double> pulse;

  const _PotWithWater({
    required this.width,
    required this.height,
    required this.innerPad,
    required this.level,
    required this.marks,
    required this.markFractions,
    required this.achievedIndex,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final innerW = width - innerPad * 2;
    final innerH = height - innerPad * 2;

    final waterTop = (1.0 - level) * innerH;

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
          // Nước
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
          // Các mốc 5/10/15/20 (từ đáy lên). Mốc đã đạt => xanh (pulsing).
          ...List.generate(marks.length, (i) {
            final frac = markFractions[i];
            final yFromTop = innerPad + (1.0 - frac) * innerH;
            final isAchieved = achievedIndex >= 0 && i <= achievedIndex;
            return Positioned(
              left: innerPad + 6,
              right: innerPad + 6,
              top: yFromTop - 1.5,
              height: 3,
              child: AnimatedBuilder(
                animation: pulse,
                builder: (_, __) => Container(
                  decoration: BoxDecoration(
                    color: isAchieved
                        ? (Color.lerp(Colors.green.shade600, Colors.green.shade300, 0.5 + 0.5 * pulse.value))
                        : Colors.amber.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
          // Nhãn mốc
          ...List.generate(marks.length, (i) {
            final frac = markFractions[i];
            final yFromTop = (innerPad + (1.0 - frac) * innerH - 22)
                .clamp(0.0, height - 22);
            final isTopAchieved = achievedIndex == i;
            return Positioned(
              left: 0,
              right: 0,
              top: yFromTop,
              child: IgnorePointer(
                child: Text(
                  '${marks[i]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isTopAchieved ? Colors.green.shade800 : Colors.brown,
                  ),
                ),
              ),
            );
          }),
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
