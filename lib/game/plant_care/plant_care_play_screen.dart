// lib/game/plant_care/plant_care_play_screen.dart

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
  int _sumStars = 0;
  int _spamDays = 0; // ngày bị coi là kết thúc sớm/không chơi (phạt nhẹ)
  late final int _rngSalt;

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
    _rngSalt = (widget.initialStateMap?['rngSalt'] as int?) ??
        (DateTime.now().microsecondsSinceEpoch & 0x7fffffff);
    _state.setPaused(widget.isPaused);
    _startTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final p in PlantAssets.all) {
      precacheImage(AssetImage(p), context);
    }
  }

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

  // Helper: chạy 1 tác vụ trong trạng thái pause để tránh decay/grow nền.
  Future<T?> _runPaused<T>(Future<T?> Function() op) async {
    _state.setPaused(true);
    if (mounted) setState(() {});
    try {
      return await op();
    } finally {
      if (!_state.isFinished) {
        _state.setPaused(false);
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> finishGame() async {
    _ticker?.cancel();
    await widget.onClearProgress();
    if (!mounted) return;
    widget.onFinish(_sumStars, _spamDays); // truyền cả số ngày spam
  }

  Future<void> outToHome() async {
    await widget.onSaveProgress(
      state: _stateMapWithSalt(),
      dayIndex: _state.dayIndex,
      stars: _sumStars,
      timeLeftSec: _state.timeLeftSec,
    );
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/shell', (_) => false);
  }

  Future<void> restartGame() async {
    _ticker?.cancel();
    await widget.onClearProgress();
    if (!mounted) return;
    setState(() {
      _state = PlantState(
        difficultyLevel: widget.difficulty,
        totalDays: widget.totalDays,
        dayLengthSec: widget.dayLengthSec,
      );
      _sumStars = 0;
      _spamDays = 0;
      _finishNotified = false;
      _accum = 0.0;
    });
    _startTicker();
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
      if (mounted) setState(() {});
    });
  }

  Future<void> _onDayEnd() async {
    final stars = _state.endDayAndScore();
    if (_state.lastDayFlaggedSpam) _spamDays++;
    _sumStars += stars;

    await widget.onSaveProgress(
      state: _stateMapWithSalt(),
      dayIndex: _state.dayIndex - 1, // ngày vừa hoàn thành
      stars: _sumStars,
      timeLeftSec: _state.timeLeftSec,
    );
    if (!mounted) return;

    await _runPaused(() async {
      return await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DaySummaryDialog(stars: stars, stage: _state.stage),
      );
    });

    if (_state.isFinished && !_finishNotified) {
      _finishNotified = true;
      if (mounted) finishGame();
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _promptEndDay() async {
    final playedPct = (_state.timeRatioToday * 100).round();
    final playedEnough = _state.timeRatioToday >= 0.25; // khớp core
    final usedTool = _state.hadToolUseToday;

    final msg = (!playedEnough || !usedTool)
        ? 'Nếu kết thúc sớm bây giờ, con có thể sẽ không được sao đâu nhé.\n'
        '${playedEnough ? '' : '• Con mới chơi khoảng $playedPct% của ngày.\n'}'
        '${usedTool ? '' : '• Con chưa dùng công cụ nào hôm nay.\n'}'
        'Con muốn thử thêm một chút rồi hãy kết thúc chứ?'
        : 'Con đã chăm cây khá tốt rồi. Kết thúc ngày để nhận sao nhé!';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết thúc ngày?'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chơi tiếp'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      if (!mounted) return;
      setState(() {
        _state.timeLeftSec = 0; // để chạy _onDayEnd
      });
    }
  }

  String _mmss(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int _dailySeed(int base) => (base ^ _rngSalt) & 0x7fffffff;

  Map<String, dynamic> _stateMapWithSalt() {
    final m = _state.toMap();
    m['rngSalt'] = _rngSalt;
    return m;
  }

  ({double low, double high}) _dailyBand({
    required Band band,
    required int seed,
    double shiftFactor = 0.5,
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
    const minTargetLow = 0.5;
    if (low < minTargetLow) {
      final offset = minTargetLow - low;
      low += offset;
      high = (high + offset).clamp(0.0, 1.0);
    }
    return (low: low, high: high);
  }

  Future<void> _openWateringMiniGame() async {
    final band = _state.stageConfig.bands[statWater]!;
    final seed0 = (_state.dayIndex * 733) ^ (_state.stage.index * 997) ^ (widget.difficulty.index * 53);
    final seed = _dailySeed(seed0);
    final tgt = _dailyBand(band: band, seed: seed, shiftFactor: 0.4, scaleMin: 0.92, scaleMax: 1.08);
    final res = await _runPaused(() async {
      return await Navigator.push<WateringMiniGameResult>(
        context,
        MaterialPageRoute(
          builder: (_) => WateringMinigamePage(
            targetLow: tgt.low,
            targetHigh: tgt.high,
            durationSec: 15,
            stage: _state.stage,
          ),
          fullscreenDialog: true,
        ),
      );
    });
    if (res == null) return;
    final delta = 0.8 + res.score0to1 * 2.2;
    _state.applyTool(ToolType.water, delta: delta);
    setState(() {});
  }

  Future<void> _openLightMiniGame() async {
    final band = _state.stageConfig.bands[statLight]!;
    final current = (_state.stats.light / 100.0).clamp(0.0, 1.0);
    final seed0 = (_state.dayIndex * 131071) ^ (_state.stage.index * 4099) ^ (widget.difficulty.index * 233);
    final seed = _dailySeed(seed0);
    final tgt = _dailyBand(band: band, seed: seed, shiftFactor: 0.5, scaleMin: 0.9, scaleMax: 1.1);
    final res = await _runPaused(() async {
      return await Navigator.push<LightMiniGameResult>(
        context,
        MaterialPageRoute(
          builder: (_) => LightAdjustMinigamePage(
            targetLow: tgt.low,
            targetHigh: tgt.high,
            current: current,
            durationSec: 15,
          ),
          fullscreenDialog: true,
        ),
      );
    });
    if (res == null) return;
    final center = (tgt.low + tgt.high) / 2.0;
    final needIncrease = current < center;
    final magnitude = 0.6 + res.score0to1 * 2.0;
    final delta = needIncrease ? magnitude : -magnitude;
    _state.applyTool(ToolType.light, delta: delta);
    setState(() {});
  }

  Future<void> _openNutrientMiniGame() async {
    final band = _state.stageConfig.bands[statNutrient]!;
    final seed0 = (_state.dayIndex * 1000003) ^ (_state.stage.index * 9176) ^ (widget.difficulty.index * 271);
    final seed = _dailySeed(seed0);
    final tgt = _dailyBand(band: band, seed: seed, shiftFactor: 0.5, scaleMin: 0.9, scaleMax: 1.1);
    final res = await _runPaused(() async {
      return await Navigator.push<NutrientMiniGameResult>(
        context,
        MaterialPageRoute(
          builder: (_) => NutrientMixMinigamePage(targetLow: tgt.low, targetHigh: tgt.high),
          fullscreenDialog: true,
        ),
      );
    });
    if (res == null) return;
    final delta = 0.6 + res.score0to1 * 2.4;
    _state.applyTool(ToolType.nutrient, delta: delta);
    setState(() {});
  }

  Future<void> _openPestMiniGame() async {
    final res = await _runPaused(() async {
      return await Navigator.push<PestCatchMiniGameResult>(
        context,
        MaterialPageRoute(
          builder: (_) => const PestCatchMinigamePage(durationSec: 20, bugs: 10),
          fullscreenDialog: true,
        ),
      );
    });
    if (res == null) return;
    final delta = 0.6 + res.score0to1 * 2.4;
    _state.applyTool(ToolType.pest, delta: delta);
    setState(() {});
  }

  Future<void> _openPruneMiniGame() async {
    final daySeed0 = (_state.dayIndex * 4241) ^ (_state.stage.index * 73) ^ (widget.difficulty.index * 11);
    final daySeed = _dailySeed(daySeed0);
    final branches = switch (_state.stage) {
      PlantStage.seed => 5,
      PlantStage.seedling => 6,
      PlantStage.adult => 7,
      PlantStage.flowering => 8,
    };
    final res = await _runPaused(() async {
      return await Navigator.push<PruneMiniGameResult>(
        context,
        MaterialPageRoute(
          builder: (_) => PruneMinigamePage(durationSec: 20, branches: branches, daySeed: daySeed),
          fullscreenDialog: true,
        ),
      );
    });
    if (res == null) return;
    final delta = 0.6 + res.score0to1 * 2.2;
    _state.applyTool(ToolType.prune, delta: delta);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final o = MediaQuery.of(context).orientation;
    final cfg = _state.stageConfig;
    final centerPlant = _PlantCard(stage: _state.stage, health: _state.stats.health);

    final topInfo = _TopInfoBar(
      dayIndex: _state.dayIndex,
      totalDays: _state.totalDays,
      timeText: _mmss(_state.timeLeftSec),
      stage: _state.stage,
      health: _state.stats.health,
      onEndDayPressed: _promptEndDay,
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
                          SizedBox(
                            width: 140,
                            child: _RightStatsPanel(
                                stats: _state.stats, bands: cfg.bands),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ToolBar(
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
                  ),
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
                  SizedBox(
                    width: 125,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          GaugeRing(
                              label: 'Nước',
                              icon: const Icon(Icons.opacity),
                              value: _state.stats.water,
                              band: cfg.bands[statWater]!,
                              size: 75),
                          GaugeRing(
                              label: 'Ánh sáng',
                              icon: const Icon(Icons.wb_sunny),
                              value: _state.stats.light,
                              band: cfg.bands[statLight]!,
                              size: 75),
                          GaugeRing(
                              label: 'Dinh dưỡng',
                              icon: const Icon(Icons.grass),
                              value: _state.stats.nutrient,
                              band: cfg.bands[statNutrient]!,
                              size: 75),
                          GaugeRing(
                              label: 'Sạch/Bảo vệ',
                              icon: const Icon(Icons.spa),
                              value: _state.stats.clean,
                              band: cfg.bands[statClean]!,
                              size: 75),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(-2, 0),
                        )
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ToolButton(
                              icon: Icons.opacity,
                              label: 'Tưới',
                              onTap: () => _openWateringMiniGame(),
                              size: 50),
                          ToolButton(
                              icon: Icons.wb_sunny,
                              label: 'Ánh sáng',
                              onTap: () => _openLightMiniGame(),
                              size: 50),
                          ToolButton(
                              icon: Icons.grass,
                              label: 'Bón phân',
                              onTap: () => _openNutrientMiniGame(),
                              size: 50),
                          ToolButton(
                              icon: Icons.bug_report,
                              label: 'Bắt sâu',
                              onTap: () => _openPestMiniGame(),
                              size: 50),
                          ToolButton(
                              icon: Icons.content_cut,
                              label: 'Tỉa',
                              onTap: () => _openPruneMiniGame(),
                              size: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... CÁC WIDGET PHÍA DƯỚI KHÔNG THAY ĐỔI ...

class _CuteBackground extends StatelessWidget {
  const _CuteBackground();
  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Image.asset(PlantAssets.bg, fit: BoxFit.cover),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.10)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    ]);
  }
}

class _PlantCard extends StatelessWidget {
  final PlantStage stage;
  final double health;
  const _PlantCard({required this.stage, required this.health});

  @override
  Widget build(BuildContext context) {
    final healthColor = Color.lerp(const Color(0xFFE53935), const Color(0xFF2E7D32), (health / 100.0).clamp(0, 1))!;

    return FittedBox(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.9),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_stageText(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: healthColor.withOpacity(.28), blurRadius: 24, spreadRadius: 4)],
                  ),
                ),
                Image.asset(_imgForStage(), fit: BoxFit.contain, errorBuilder: (_, __, ___) {
                  final emoji = {
                    PlantStage.seed: '🌱',
                    PlantStage.seedling: '🌿',
                    PlantStage.adult: '🌳',
                    PlantStage.flowering: '🌸',
                  }[stage]!;
                  return Text(emoji, style: const TextStyle(fontSize: 96));
                }),
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
                    child: Row(children: [
                      const Icon(Icons.favorite, size: 16, color: Colors.pink),
                      const SizedBox(width: 4),
                      Text(health.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            const Text('Giữ các chỉ số trong vùng vàng để cây khoẻ!',
                style: TextStyle(color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

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
        return 'Trưởng thành';
      case PlantStage.flowering:
        return '🌸 Ra hoa';
    }
  }
}

class _TopInfoBar extends StatelessWidget {
  final int dayIndex, totalDays;
  final String timeText;
  final PlantStage stage;
  final double health;
  final VoidCallback? onEndDayPressed;

  const _TopInfoBar({
    required this.dayIndex,
    required this.totalDays,
    required this.timeText,
    required this.stage,
    required this.health,
    this.onEndDayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(const Icon(Icons.calendar_month, size: 18),
                'Ngày ${dayIndex > totalDays ? totalDays : dayIndex}/$totalDays'),
            const SizedBox(width: 8),
            _chip(const Icon(Icons.timer, size: 18), timeText),
            const SizedBox(width: 8),
            _chip(const Icon(Icons.local_florist, size: 18), _stageName(stage)),
            const SizedBox(width: 16),
            FilledButton.tonalIcon(
              onPressed: onEndDayPressed,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Kết thúc ngày'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
          ],
        ),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          GaugeRing(label: 'Nước', icon: const Icon(Icons.opacity), value: stats.water, band: bands[statWater]!),
          GaugeRing(label: 'Ánh sáng', icon: const Icon(Icons.wb_sunny), value: stats.light, band: bands[statLight]!),
          GaugeRing(label: 'Dinh dưỡng', icon: const Icon(Icons.grass), value: stats.nutrient, band: bands[statNutrient]!),
          GaugeRing(label: 'Sạch/Bảo vệ', icon: const Icon(Icons.spa), value: stats.clean, band: bands[statClean]!),
        ],
      ),
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
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
      ]),
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
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
                (i) => Icon(i < stars ? Icons.star : Icons.star_border, size: 28, color: Colors.amber),
          ),
        ),
        const SizedBox(height: 12),
        Text('Giai đoạn hiện tại: ${_stageName(stage)}'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tiếp tục')),
      ],
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
