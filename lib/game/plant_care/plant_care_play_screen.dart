import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'core/plant_core.dart';
import 'widgets/gauge_ring.dart';
import 'widgets/tool_button.dart';
import 'plant_assets.dart';

// Mini-games
import 'minigames/watering_minigame.dart';
import 'minigames/pest_catch_minigame.dart';
import 'minigames/light_adjust_minigame.dart';
import 'minigames/nutrient_mix_minigame.dart';
import 'minigames/prune_minigame.dart';

class PlantCarePlayScreen extends StatefulWidget {
  final bool isPaused;
  final DifficultyLevel difficulty;

  final Map<String, dynamic>? initialStateMap;

  // ✅ callback hệ thống
  final void Function(int correct, int wrong) onFinish;
  final Future<void> Function({
  required Map<String, dynamic> state,
  required int dayIndex,
  required int stars,
  required int timeLeftSec,
  }) onSaveProgress;
  final Future<void> Function() onClearProgress;

  final int totalDays;
  final int dayLengthSec;

  const PlantCarePlayScreen({
    super.key,
    required this.isPaused,
    required this.difficulty,
    required this.onFinish,
    required this.onSaveProgress,
    required this.onClearProgress,
    this.initialStateMap,
    this.totalDays = 5,
    this.dayLengthSec = 90,
  });

  @override
  State<PlantCarePlayScreen> createState() => _PlantCarePlayScreenState();
}

class _PlantCarePlayScreenState extends State<PlantCarePlayScreen>
    with TickerProviderStateMixin {
  late PlantState _state;
  Timer? _ticker;
  DateTime? _lastTick;
  double _accum = 0.0;
  bool _finishNotified = false;

  // Tổng sao tích lũy qua các ngày → dùng làm "correct"
  int _sumStars = 0;

  @override
  void initState() {
    super.initState();
    _state = widget.initialStateMap != null
        ? PlantState.fromMap(widget.initialStateMap!)
        : PlantState(
      difficultyLevel: widget.difficulty,
      totalDays: widget.totalDays,
      dayLengthSec: widget.dayLengthSec,
    );
    _state.setPaused(widget.isPaused);
    _startTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache toàn bộ ảnh để tránh nháy khi đổi stage
    for (final p in PlantAssets.all) {
      precacheImage(AssetImage(p), context);
    }
  }

  // ===== Public API cho Wrapper (giống Recycle Sort) =====
  Future<void> finishGame() async {
    _ticker?.cancel();
    await widget.onClearProgress();
    if (!mounted) return;
    widget.onFinish(_sumStars, 0); // correct = tổng sao, wrong = 0
  }

  Future<void> outToHome() async {
    await widget.onSaveProgress(
      state: _state.toMap(),
      dayIndex: _state.dayIndex,
      stars: _sumStars,
      timeLeftSec: _state.timeLeftSec,
    );
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/shell', (_) => false);
  }
  // =======================================================

  @override
  void didUpdateWidget(covariant PlantCarePlayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPaused != widget.isPaused) {
      _state.setPaused(widget.isPaused);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _lastTick = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final dt = now.difference(_lastTick!).inMilliseconds / 1000.0;
      _lastTick = now;

      _accum += dt;
      while (_accum >= 1.0) {
        _state.tick(1.0);
        _accum -= 1.0;
      }

      if (_state.timeLeftSec <= 0 && !_state.isFinished) {
        _onDayEnd();
      }

      if (_state.isFinished && !_finishNotified) {
        _finishNotified = true;
        finishGame(); // kết thúc tự nhiên
      }

      if (mounted) setState(() {});
    });
  }

  Future<void> _onDayEnd() async {
    final stars = _state.endDayAndScore(); // 0..3
    _sumStars += stars;

    await widget.onSaveProgress(
      state: _state.toMap(),
      dayIndex: _state.dayIndex - 1,
      stars: _sumStars,
      timeLeftSec: _state.timeLeftSec,
    );

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DaySummaryDialog(stars: stars, stage: _state.stage),
    );
    if (mounted) setState(() {});
  }

  String _mmss(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ======== MINI-GAMES (mục tiêu thay đổi theo NGÀY) ========

  // Tính mục tiêu theo ngày dựa trên band gốc (0..100) → (low, high) 0..1
  ({double low, double high}) _dailyBand({
    required Band band,
    required int seed,
    double shiftFactor = 0.5, // tịnh tiến tâm: tỉ lệ của half
    double scaleMin = 0.9,
    double scaleMax = 1.1,
  }) {
    final baseLow = band.low / 100.0;
    final baseHigh = band.high / 100.0;
    final baseCenter = (baseLow + baseHigh) / 2.0;
    final baseHalf = (baseHigh - baseLow) / 2.0;

    final rnd = math.Random(seed);
    final shift = (rnd.nextDouble() * 2 - 1) * baseHalf * shiftFactor;
    final scale = scaleMin + rnd.nextDouble() * (scaleMax - scaleMin);

    double center = (baseCenter + shift).clamp(0.0, 1.0);
    double half = (baseHalf * scale).clamp(0.06, 0.25);

    double low = center - half;
    double high = center + half;
    if (low < 0) {
      high = (high - low).clamp(0.0, 1.0);
      low = 0.0;
    }
    if (high > 1) {
      low = (low - (high - 1.0)).clamp(0.0, 1.0);
      high = 1.0;
    }
    return (low: low, high: high);
  }

  // -- Tưới nước
  Future<void> _openWateringMiniGame() async {
    final band = _state.stageConfig.bands[statWater]!;
    final seed = (_state.dayIndex * 733) ^
    (_state.stage.index * 997) ^
    (widget.difficulty.index * 53);
    final tgt = _dailyBand(
      band: band,
      seed: seed,
      shiftFactor: 0.4,
      scaleMin: 0.92,
      scaleMax: 1.08,
    );

    final res = await Navigator.push<WateringMiniGameResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WateringMinigamePage(
          targetLow: tgt.low,
          targetHigh: tgt.high,
          durationSec: 15,
          stage: _state.stage, // mini-game tự chỉnh tolerance/tốc độ theo stage
        ),
        fullscreenDialog: true,
      ),
    );
    if (res == null) return;

    final delta = 0.8 + res.score0to1 * 2.2;
    _state.applyTool(ToolType.water, delta: delta);
    setState(() {});
  }

  // -- Ánh sáng (mini-game kéo mây che nắng – không dùng đồng hồ)
  Future<void> _openLightMiniGame() async {
    final band = _state.stageConfig.bands[statLight]!;
    final current = (_state.stats.light / 100.0).clamp(0.0, 1.0);
    final seed = (_state.dayIndex * 131071) ^
    (_state.stage.index * 4099) ^
    (widget.difficulty.index * 233);
    final tgt = _dailyBand(
      band: band,
      seed: seed,
      shiftFactor: 0.5,
      scaleMin: 0.9,
      scaleMax: 1.1,
    );

    final res = await Navigator.push<LightMiniGameResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LightAdjustMinigamePage(
          targetLow: tgt.low,
          targetHigh: tgt.high,
          current: current,
          durationSec: 15, // giữ để tương thích, bản không giờ sẽ bỏ qua
        ),
        fullscreenDialog: true,
      ),
    );
    if (res == null) return;

    final center = (tgt.low + tgt.high) / 2.0;
    final needIncrease = current < center;
    final magnitude = 0.6 + res.score0to1 * 2.0;
    final delta = needIncrease ? magnitude : -magnitude;

    _state.applyTool(ToolType.light, delta: delta);
    setState(() {});
  }

  // -- Bón phân (mini-game không đồng hồ)
  Future<void> _openNutrientMiniGame() async {
    final band = _state.stageConfig.bands[statNutrient]!;
    final seed = (_state.dayIndex * 1000003) ^
    (_state.stage.index * 9176) ^
    (widget.difficulty.index * 271);
    final tgt = _dailyBand(
      band: band,
      seed: seed,
      shiftFactor: 0.5,
      scaleMin: 0.9,
      scaleMax: 1.1,
    );

    final res = await Navigator.push<NutrientMiniGameResult>(
      context,
      MaterialPageRoute(
        builder: (_) => NutrientMixMinigamePage(
          targetLow: tgt.low,
          targetHigh: tgt.high,
        ),
        fullscreenDialog: true,
      ),
    );
    if (res == null) return;

    final delta = 0.6 + res.score0to1 * 2.4;
    _state.applyTool(ToolType.nutrient, delta: delta);
    setState(() {});
  }

  // -- Bắt sâu
  Future<void> _openPestMiniGame() async {
    final res = await Navigator.push<PestCatchMiniGameResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const PestCatchMinigamePage(
          durationSec: 20,
          bugs: 10,
        ),
        fullscreenDialog: true,
      ),
    );
    if (res == null) return;
    final delta = 0.6 + res.score0to1 * 2.4;
    _state.applyTool(ToolType.pest, delta: delta);
    setState(() {});
  }

  // -- Tỉa cành (mỗi ngày bố cục khác: truyền daySeed)
  Future<void> _openPruneMiniGame() async {
    // Seed ổn định theo NGÀY + giai đoạn + độ khó
    final daySeed = (_state.dayIndex * 4241) ^
    (_state.stage.index * 73) ^
    (widget.difficulty.index * 11);

    // Có thể tăng số cành ở giai đoạn sau
    final branches = switch (_state.stage) {
      PlantStage.seed => 5,
      PlantStage.seedling => 6,
      PlantStage.adult => 7,
      PlantStage.flowering => 8,
    };

    final res = await Navigator.push<PruneMiniGameResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PruneMinigamePage(
          durationSec: 20,   // giữ để tương thích
          branches: branches,
          daySeed: daySeed,  // ✅ mỗi ngày một bố cục
        ),
        fullscreenDialog: true,
      ),
    );
    if (res == null) return;
    final delta = 0.6 + res.score0to1 * 2.2;
    _state.applyTool(ToolType.prune, delta: delta);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final o = MediaQuery.of(context).orientation;
    final cfg = _state.stageConfig;

    final rightPanel = _RightStatsPanel(stats: _state.stats, bands: cfg.bands);

    // MỞ HẾT 5 CÔNG CỤ (chưa khoá theo giai đoạn)
    final toolBar = _ToolBar(
      stage: _state.stage,
      tools: const [
        ToolType.water,
        ToolType.light,
        ToolType.nutrient,
        ToolType.pest,
        ToolType.prune,
      ],
      onUse: (t) async {
        switch (t) {
          case ToolType.water:
            await _openWateringMiniGame();
            break;
          case ToolType.light:
            await _openLightMiniGame();
            break;
          case ToolType.nutrient:
            await _openNutrientMiniGame();
            break;
          case ToolType.pest:
            await _openPestMiniGame();
            break;
          case ToolType.prune:
            await _openPruneMiniGame();
            break;
        }
      },
    );

    final centerPlant =
    _PlantCard(stage: _state.stage, health: _state.stats.health);

    final topInfo = _TopInfoBar(
      dayIndex: _state.dayIndex,
      totalDays: _state.totalDays,
      timeText: _mmss(_state.timeLeftSec),
      stage: _state.stage,
      health: _state.stats.health,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _CuteBackground(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: o == Orientation.portrait
                  ? Column(
                key: const ValueKey('portrait'),
                children: [
                  topInfo,
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(child: Center(child: centerPlant)),
                          const SizedBox(width: 12),
                          SizedBox(width: 140, child: rightPanel),
                        ],
                      ),
                    ),
                  ),
                  toolBar,
                  const SizedBox(height: 8),
                ],
              )
                  : Row(
                key: const ValueKey('landscape'),
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        topInfo,
                        const SizedBox(height: 8),
                        Expanded(child: Center(child: centerPlant)),
                      ],
                    ),
                  ),
                  SizedBox(width: 180, child: rightPanel),
                  RotatedBox(quarterTurns: 1, child: toolBar),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== NỀN & THẺ CÂY (ảnh) =====

class _CuteBackground extends StatelessWidget {
  const _CuteBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(PlantAssets.bg, fit: BoxFit.cover),
        // overlay nhẹ để text/điểm dễ đọc trên nền
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.10),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlantCard extends StatelessWidget {
  final PlantStage stage;
  final double health;
  const _PlantCard({required this.stage, required this.health});

  String _imgForStage() {
    switch (stage) {
      case PlantStage.seed:
        return PlantAssets.stageSeed;
      case PlantStage.seedling:
        return PlantAssets.stageSeedling;
      case PlantStage.adult:
        return PlantAssets.stageAdult;
      case PlantStage.flowering:
        return PlantAssets.stageFlowering;
    }
  }

  String _stageText() {
    switch (stage) {
      case PlantStage.seed:
        return '🌱 Hạt';
      case PlantStage.seedling:
        return '🌿 Cây con';
      case PlantStage.adult:
        return '🌳 Trưởng thành';
      case PlantStage.flowering:
        return '🌸 Ra hoa';
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthColor = Color.lerp(
      const Color(0xFFE53935),
      const Color(0xFF2E7D32),
      (health / 100.0).clamp(0, 1),
    )!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_stageText(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // halo theo health
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: healthColor.withOpacity(.28),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                // ảnh cây
                Image.asset(
                  _imgForStage(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    final emoji = {
                      PlantStage.seed: '🌱',
                      PlantStage.seedling: '🌿',
                      PlantStage.adult: '🌳',
                      PlantStage.flowering: '🌸',
                    }[stage]!;
                    return Text(emoji, style: const TextStyle(fontSize: 96));
                  },
                ),
                // health badge
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, size: 16, color: Colors.pink),
                        const SizedBox(width: 4),
                        Text(health.toStringAsFixed(0),
                            style: const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Giữ các chỉ số trong vùng vàng để cây khoẻ!',
            style: TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ===== UI phụ (giữ nguyên) =====

class _TopInfoBar extends StatelessWidget {
  final int dayIndex;
  final int totalDays;
  final String timeText;
  final PlantStage stage;
  final double health;
  const _TopInfoBar({
    required this.dayIndex,
    required this.totalDays,
    required this.timeText,
    required this.stage,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip(const Icon(Icons.calendar_month, size: 18), 'Ngày $dayIndex/$totalDays'),
          const SizedBox(width: 8),
          _chip(const Icon(Icons.timer, size: 18), timeText),
          const SizedBox(width: 8),
          _chip(const Icon(Icons.local_florist, size: 18), _stageName(stage)),
          const Spacer(),
          Row(children: [
            const Icon(Icons.favorite, size: 18, color: Colors.pink),
            const SizedBox(width: 4),
            Text(health.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  String _stageName(PlantStage s) {
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

  Widget _chip(Widget icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(children: [icon, const SizedBox(width: 6), Text(text)]),
    );
  }
}

class _RightStatsPanel extends StatelessWidget {
  final Stats stats;
  final Map<String, Band> bands;
  const _RightStatsPanel({required this.stats, required this.bands});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GaugeRing(label: 'Nước', icon: const Icon(Icons.opacity), value: stats.water, band: bands[statWater]!),
        GaugeRing(label: 'Ánh sáng', icon: const Icon(Icons.wb_sunny), value: stats.light, band: bands[statLight]!),
        GaugeRing(label: 'Dinh dưỡng', icon: const Icon(Icons.grass), value: stats.nutrient, band: bands[statNutrient]!),
        GaugeRing(label: 'Sạch/Bảo vệ', icon: const Icon(Icons.spa), value: stats.clean, band: bands[statClean]!),
      ],
    );
  }
}

class _ToolBar extends StatelessWidget {
  final PlantStage stage;
  final List<ToolType> tools;
  final void Function(ToolType) onUse;
  const _ToolBar({required this.stage, required this.tools, required this.onUse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (tools.contains(ToolType.water))
            ToolButton(icon: Icons.opacity, label: 'Tưới', onTap: () => onUse(ToolType.water)),
          if (tools.contains(ToolType.light))
            ToolButton(icon: Icons.wb_sunny, label: 'Ánh sáng', onTap: () => onUse(ToolType.light)),
          if (tools.contains(ToolType.nutrient))
            ToolButton(icon: Icons.grass, label: 'Bón phân', onTap: () => onUse(ToolType.nutrient)),
          if (tools.contains(ToolType.pest))
            ToolButton(icon: Icons.bug_report, label: 'Bắt sâu', onTap: () => onUse(ToolType.pest)),
          if (tools.contains(ToolType.prune))
            ToolButton(icon: Icons.content_cut, label: 'Tỉa', onTap: () => onUse(ToolType.prune)),
        ],
      ),
    );
  }
}

class _DaySummaryDialog extends StatelessWidget {
  final int stars;
  final PlantStage stage;
  const _DaySummaryDialog({required this.stars, required this.stage});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Tổng kết ngày'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => Icon(i < stars ? Icons.star : Icons.star_border, size: 28, color: Colors.amber)),
          ),
          const SizedBox(height: 12),
          Text('Giai đoạn hiện tại: ${_stageName(stage)}'),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tiếp tục'))],
    );
  }

  static String _stageName(PlantStage s) {
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
}
