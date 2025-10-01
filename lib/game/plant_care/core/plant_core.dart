// Lõi mô hình: bands theo stage, tính health/growth, áp dụng công cụ.
// Thuần Dart để test unit.

enum PlantStage { seed, seedling, adult, flowering }
enum ToolType { water, light, nutrient, pest, prune }
enum DifficultyLevel { easy, normal, hard }

// ========================== CẤU HÌNH KHÓ/DỄ ==========================
class DifficultyConfig {
  final double bandPadding; // mở rộng dải vàng (điểm)
  final double decayMul;    // nhân tốc độ giảm chỉ số/ngày
  final double toolMul;     // nhân lực công cụ
  const DifficultyConfig({
    required this.bandPadding,
    required this.decayMul,
    required this.toolMul,
  });

  static DifficultyConfig of(DifficultyLevel lv) {
    switch (lv) {
      case DifficultyLevel.easy:
        return const DifficultyConfig(bandPadding: 8, decayMul: 0.8, toolMul: 1.1);
      case DifficultyLevel.hard:
        return const DifficultyConfig(bandPadding: 0, decayMul: 1.25, toolMul: 0.95);
      case DifficultyLevel.normal:
      default:
        return const DifficultyConfig(bandPadding: 4, decayMul: 1.0, toolMul: 1.0);
    }
  }
}

// ========================= DẢI VÀNG (BAND) ==========================
class Band {
  final double low;
  final double high;
  const Band(this.low, this.high);

  Band pad(double p) {
    return Band(
      (low - p).clamp(0, 100).toDouble(),
      (high + p).clamp(0, 100).toDouble(),
    );
  }

  bool contains(double v) => v >= low && v <= high;
}

// ========================= CẤU HÌNH THEO STAGE =======================
class StageConfig {
  final Map<String, Band> bands;          // water/light/nutrient/clean
  final Map<String, double> decayPerDay;  // điểm/ngày
  final List<ToolType> tools;             // công cụ mở ở stage
  final double growthPerSecAtFullHealth;  // điểm/giây khi health=100
  final Set<String> requiredStats;        // chỉ số đang YÊU CẦU ở stage

  const StageConfig({
    required this.bands,
    required this.decayPerDay,
    required this.tools,
    required this.growthPerSecAtFullHealth,
    required this.requiredStats,
  });
}

const statWater = 'water';
const statLight = 'light';
const statNutrient = 'nutrient';
const statClean = 'clean';

class StageConfigs {
  static final Map<PlantStage, StageConfig> base = {
    // HẠT: yêu cầu Nước + Ánh sáng
    PlantStage.seed: StageConfig(
      bands: const {
        statWater:    Band(60, 80),
        statLight:    Band(20, 40),
        statNutrient: Band(20, 40),  // để sẵn cho stage sau
        statClean:    Band(70, 100), // để sẵn cho stage sau
      },
      decayPerDay: const { statWater: 12, statLight: 10, statNutrient: 8, statClean: 6 },
      tools: const [ToolType.water, ToolType.light],
      growthPerSecAtFullHealth: 0.55,
      requiredStats: const { statWater, statLight },
    ),
    // CÂY CON: thêm Dinh dưỡng
    PlantStage.seedling: StageConfig(
      bands: const {
        statWater:    Band(55, 75),
        statLight:    Band(50, 70),
        statNutrient: Band(20, 40),
        statClean:    Band(70, 100),
      },
      decayPerDay: const { statWater: 13, statLight: 10, statNutrient: 9, statClean: 6 },
      tools: const [ToolType.water, ToolType.light, ToolType.nutrient],
      growthPerSecAtFullHealth: 0.6,
      requiredStats: const { statWater, statLight, statNutrient },
    ),
    // TRƯỞNG THÀNH: thêm Bảo vệ (mở Bắt sâu/Tỉa)
    PlantStage.adult: StageConfig(
      bands: const {
        statWater:    Band(50, 70),
        statLight:    Band(60, 80),
        statNutrient: Band(40, 60),
        statClean:    Band(75, 100),
      },
      decayPerDay: const { statWater: 14, statLight: 12, statNutrient: 10, statClean: 7 },
      tools: const [ToolType.water, ToolType.light, ToolType.nutrient, ToolType.pest, ToolType.prune],
      growthPerSecAtFullHealth: 0.55,
      requiredStats: const { statWater, statLight, statNutrient, statClean },
    ),
    // RA HOA: giữ đủ 4 chỉ số
    PlantStage.flowering: StageConfig(
      bands: const {
        statWater:    Band(50, 65),
        statLight:    Band(70, 85),
        statNutrient: Band(50, 70),
        statClean:    Band(80, 100),
      },
      decayPerDay: const { statWater: 14, statLight: 12, statNutrient: 10, statClean: 8 },
      tools: const [ToolType.water, ToolType.light, ToolType.nutrient, ToolType.pest, ToolType.prune],
      growthPerSecAtFullHealth: 0.5,
      requiredStats: const { statWater, statLight, statNutrient, statClean },
    ),
  };

  static StageConfig of(PlantStage stage, DifficultyConfig diff) {
    final cfg = base[stage]!;
    final padded = cfg.bands.map((k, v) => MapEntry(k, v.pad(diff.bandPadding)));
    final decay  = cfg.decayPerDay.map((k, v) => MapEntry(k, v * diff.decayMul));
    return StageConfig(
      bands: padded,
      decayPerDay: decay,
      tools: cfg.tools,
      growthPerSecAtFullHealth: cfg.growthPerSecAtFullHealth,
      requiredStats: cfg.requiredStats,
    );
  }
}

// ============================== STATS ===============================
class Stats {
  double water, light, nutrient, clean;
  double health; // 0..100
  double growth; // 0..100

  Stats({
    required this.water,
    required this.light,
    required this.nutrient,
    required this.clean,
    this.health = 50,
    this.growth = 0,
  });

  Stats.initial()
      : water = 50, light = 50, nutrient = 20, clean = 70, health = 50, growth = 0;

  Stats copy() => Stats(water: water, light: light, nutrient: nutrient, clean: clean, health: health, growth: growth);

  Map<String, double> asMap() => { statWater: water, statLight: light, statNutrient: nutrient, statClean: clean };

  void setFromMap(Map<String, double> m) {
    water    = (m[statWater]    ?? water).clamp(0, 100).toDouble();
    light    = (m[statLight]    ?? light).clamp(0, 100).toDouble();
    nutrient = (m[statNutrient] ?? nutrient).clamp(0, 100).toDouble();
    clean    = (m[statClean]    ?? clean).clamp(0, 100).toDouble();
  }
}

// ===================== HEALTH & GROWTH ===============================

double _scoreFromBand(double v, Band band) {
  if (band.contains(v)) return 100.0;
  final d = v < band.low ? (band.low - v) : (v - band.high);
  return (100.0 - d * 4.0).clamp(0.0, 100.0);
}

/// Health chỉ tính trên các stat đang yêu cầu (requiredStats) và chuẩn hoá trọng số.
/// Sửa null-safety: dùng Map non-nullable + `scores[key] ?? 0.0`.
double computeHealth(
    Stats s,
    Map<String, Band> bands, {
      Set<String>? requiredStats,
    }) {
  final Set<String> req =
      requiredStats ?? { statWater, statLight, statNutrient, statClean };

  final Map<String, double> scores = {
    statWater:    _scoreFromBand(s.water,    bands[statWater]!),
    statLight:    _scoreFromBand(s.light,    bands[statLight]!),
    statNutrient: _scoreFromBand(s.nutrient, bands[statNutrient]!),
    statClean:    _scoreFromBand(s.clean,    bands[statClean]!),
  };

  final Map<String, double> baseW = {
    statWater: 0.28, statLight: 0.28, statNutrient: 0.22, statClean: 0.22,
  };

  final active = baseW.entries.where((e) => req.contains(e.key)).toList();
  final double sumW = active.fold<double>(0.0, (p, e) => p + e.value);
  if (sumW <= 0.0) return 100.0;

  double health = 0.0;
  for (final entry in active) {
    final String key = entry.key;
    final double weight = entry.value / sumW;
    final double score = scores[key] ?? 0.0; // <- tránh lỗi operator []
    health += score * weight;
  }
  return health.clamp(0.0, 100.0);
}

// =============== ÁP DỤNG CÔNG CỤ (TIỆM CẬN/HYSTERESIS) ==============
class ToolEffectResult {
  final String stat; // water/light/nutrient/clean
  final double before;
  final double appliedDelta;
  final double after;
  const ToolEffectResult({
    required this.stat,
    required this.before,
    required this.appliedDelta,
    required this.after,
  });
}

double applyToolValue(
    double current,
    double baseDelta,
    Band band, {
      double nearDist = 12,
      double kNear   = 0.4,
      double kInside = 0.25,
    }) {
  double factor;
  if (band.contains(current)) {
    factor = kInside;
  } else {
    final dist = current < band.low ? (band.low - current) : (current - band.high);
    factor = dist < nearDist ? kNear : 1.0;
  }
  final next = (current + baseDelta * factor).clamp(0.0, 100.0);
  return next.toDouble();
}

// ============================ PLANT STATE ============================
class PlantState {
  final DifficultyLevel difficultyLevel;
  final DifficultyConfig _diff;
  PlantStage stage;
  Stats stats;

  final int totalDays;
  final int dayLengthSec;
  int dayIndex;
  int timeLeftSec;
  bool paused;

  final Map<String, double> _cooldownSec = {
    statWater: 0, statLight: 0, statNutrient: 0, statClean: 0,
  };

  double baseWaterPerUse = 18;
  double baseLightPerUse = 15;
  double baseNutrientPerUse = 12;
  double baseCleanPerUse  = 10;
  double cooldownPerUseSec = 3.0;

  final Map<PlantStage, double> growthForNext = const {
    PlantStage.seed: 100, PlantStage.seedling: 100, PlantStage.adult: 100, PlantStage.flowering: 100,
  };

  double _elapsedSecToday = 0, _healthSumToday = 0, _growthAtStartOfDay = 0;
  int _samplesToday = 0, _toolUsesToday = 0;
  bool lastDayFlaggedSpam = false;

  bool get hadToolUseToday => _toolUsesToday > 0;
  double get timeRatioToday =>
      dayLengthSec <= 0 ? 0.0 : (_elapsedSecToday / dayLengthSec).clamp(0.0, 1.0);
  double get growthDeltaToday => (stats.growth - _growthAtStartOfDay).clamp(0.0, 100.0);

  PlantState({
    this.stage = PlantStage.seed,
    Stats? initialStats,
    this.difficultyLevel = DifficultyLevel.normal,
    this.totalDays = 5,
    this.dayLengthSec = 90,
    this.dayIndex = 1,
    int? initialTimeLeftSec,
    this.paused = false,
  })  : stats = initialStats ?? Stats.initial(),
        _diff = DifficultyConfig.of(difficultyLevel),
        timeLeftSec = initialTimeLeftSec ?? 90 {
    _growthAtStartOfDay = stats.growth;
  }

  StageConfig get stageConfig => StageConfigs.of(stage, _diff);
  bool get isFinished => dayIndex > totalDays;

  void tick(double deltaSec) {
    _cooldownSec.updateAll((k, v) => (v - deltaSec).clamp(0.0, 9999.0));
    if (paused || isFinished) return;

    final d = stageConfig.decayPerDay;
    stats.water    = (stats.water    - (d[statWater]!    / dayLengthSec) * deltaSec).clamp(0.0, 100.0);
    stats.light    = (stats.light    - (d[statLight]!    / dayLengthSec) * deltaSec).clamp(0.0, 100.0);
    stats.nutrient = (stats.nutrient - (d[statNutrient]! / dayLengthSec) * deltaSec).clamp(0.0, 100.0);
    stats.clean    = (stats.clean    - (d[statClean]!    / dayLengthSec) * deltaSec).clamp(0.0, 100.0);

    // Health & growth chỉ dựa trên stat yêu cầu
    stats.health = computeHealth(stats, stageConfig.bands, requiredStats: stageConfig.requiredStats);
    final gRate = stageConfig.growthPerSecAtFullHealth;
    final inc = gRate * (stats.health / 100.0) * deltaSec;
    stats.growth = (stats.growth + inc).clamp(0.0, 100.0);

    _elapsedSecToday += deltaSec;
    _healthSumToday += stats.health;
    _samplesToday += 1;

    _maybeAdvanceStage();

    timeLeftSec -= deltaSec.toInt();
    if (timeLeftSec < 0) timeLeftSec = 0;
  }

  void _maybeAdvanceStage() {
    final need = growthForNext[stage]!;
    if (stats.growth >= need) {
      stats.growth = 0;
      switch (stage) {
        case PlantStage.seed:      stage = PlantStage.seedling;  break;
        case PlantStage.seedling:  stage = PlantStage.adult;     break;
        case PlantStage.adult:     stage = PlantStage.flowering; break;
        case PlantStage.flowering: break;
      }
    }
  }

  void _resetDayCounters() {
    _elapsedSecToday = 0; _healthSumToday = 0; _samplesToday = 0; _toolUsesToday = 0;
    _growthAtStartOfDay = stats.growth;
  }

  int endDayAndScore() {
    final bands = stageConfig.bands;
    final req = stageConfig.requiredStats;

    final inBandCount = <bool>[
      if (req.contains(statWater))    bands[statWater]!.contains(stats.water),
      if (req.contains(statLight))    bands[statLight]!.contains(stats.light),
      if (req.contains(statNutrient)) bands[statNutrient]!.contains(stats.nutrient),
      if (req.contains(statClean))    bands[statClean]!.contains(stats.clean),
    ].where((e) => e).length;

    final hLast = stats.health;
    final avgHealth = _samplesToday > 0 ? (_healthSumToday / _samplesToday) : hLast;
    final timeRatio = timeRatioToday;
    final growthDelta = growthDeltaToday;

    const minTimeRatio = 0.25;
    const minGrowth = 1.5;

    final early = timeRatio < minTimeRatio;
    final noTool = _toolUsesToday == 0;
    final noGrow = growthDelta < minGrowth;

    lastDayFlaggedSpam = early || noTool;

    int stars = 0;
    if (!(early || noTool || noGrow)) {
      final reqCount = req.length;
      if (avgHealth >= 78 && inBandCount >= (reqCount >= 3 ? 3 : reqCount) && growthDelta >= 14) {
        stars = 3;
      } else if (avgHealth >= 62 && inBandCount >= (reqCount >= 2 ? 2 : reqCount) && growthDelta >= 7) {
        stars = 2;
      } else if (avgHealth >= 48 && inBandCount >= 1 && growthDelta >= 1.5) {
        stars = 1;
      }
    }

    _maybeAdvanceStage();

    dayIndex += 1;
    if (!isFinished) {
      timeLeftSec = dayLengthSec;
      _resetDayCounters();
    }
    return stars;
  }

  void setPaused(bool v) { paused = v; }
  bool _onCooldown(String stat) => (_cooldownSec[stat] ?? 0) > 0.0;

  ToolEffectResult? _applyToStat({required String stat, required double baseDelta}) {
    if (_onCooldown(stat)) return null;

    final band = stageConfig.bands[stat]!;
    final current = asMapValue(stat);

    final applied = applyToolValue(current, baseDelta * _diff.toolMul, band);
    final result  = ToolEffectResult(stat: stat, before: current, appliedDelta: (applied - current), after: applied);

    switch (stat) {
      case statWater:    stats.water = applied;    break;
      case statLight:    stats.light = applied;    break;
      case statNutrient: stats.nutrient = applied; break;
      case statClean:    stats.clean  = applied;   break;
    }

    stats.health = computeHealth(stats, stageConfig.bands, requiredStats: stageConfig.requiredStats);
    _cooldownSec[stat] = cooldownPerUseSec;
    _toolUsesToday++;
    return result;
  }

  double asMapValue(String stat) {
    switch (stat) {
      case statWater: return stats.water;
      case statLight: return stats.light;
      case statNutrient: return stats.nutrient;
      case statClean: return stats.clean;
      default: return 0.0;
    }
  }

  ToolEffectResult? applyTool(ToolType t, {double delta = 1.0}) {
    if (isFinished || paused) return null;
    switch (t) {
      case ToolType.water:    return _applyToStat(stat: statWater,    baseDelta: baseWaterPerUse    * delta);
      case ToolType.light:    return _applyToStat(stat: statLight,    baseDelta: baseLightPerUse    * delta);
      case ToolType.nutrient: return _applyToStat(stat: statNutrient, baseDelta: baseNutrientPerUse * delta);
      case ToolType.pest:     return _applyToStat(stat: statClean,    baseDelta: baseCleanPerUse    * delta);
      case ToolType.prune:    return _applyToStat(stat: statClean,    baseDelta: (baseCleanPerUse * 0.8) * delta);
    }
  }

  Map<String, dynamic> toMap() => {
    'stage': stage.index,
    'difficulty': difficultyLevel.index,
    'stats': {
      statWater: stats.water, statLight: stats.light, statNutrient: stats.nutrient, statClean: stats.clean,
      'health': stats.health, 'growth': stats.growth,
    },
    'totalDays': totalDays, 'dayLengthSec': dayLengthSec, 'dayIndex': dayIndex, 'timeLeftSec': timeLeftSec,
  };

  factory PlantState.fromMap(Map<String, dynamic> map) {
    final stage = PlantStage.values[(map['stage'] as num).toInt()];
    final diff  = DifficultyLevel.values[(map['difficulty'] as num).toInt()];
    final s     = map['stats'] as Map<String, dynamic>;
    return PlantState(
      stage: stage,
      initialStats: Stats(
        water:    (s[statWater] as num).toDouble(),
        light:    (s[statLight] as num).toDouble(),
        nutrient: (s[statNutrient] as num).toDouble(),
        clean:    (s[statClean] as num).toDouble(),
        health:   (s['health'] as num).toDouble(),
        growth:   (s['growth'] as num).toDouble(),
      ),
      difficultyLevel: diff,
      totalDays: (map['totalDays'] as num).toInt(),
      dayLengthSec: (map['dayLengthSec'] as num).toInt(),
      dayIndex: (map['dayIndex'] as num).toInt(),
      initialTimeLeftSec: (map['timeLeftSec'] as num).toInt(),
    );
  }
}
