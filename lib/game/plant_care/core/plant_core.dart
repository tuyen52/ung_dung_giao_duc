// lib/game/plant_care/core/plant_core.dart
// Step 1: Lõi mô hình, cân bằng, và helper áp dụng công cụ (tiệm cận/hysteresis)
// Thuần Dart, không phụ thuộc Flutter để dễ test unit.

// =============================== ENUMS ===============================

enum PlantStage { seed, seedling, adult, flowering }
enum ToolType { water, light, nutrient, pest, prune }
enum DifficultyLevel { easy, normal, hard }

// ========================== CẤU HÌNH KHÓ/DỄ ==========================

class DifficultyConfig {
  final double bandPadding; // mở rộng dải vàng (đơn vị điểm)
  final double decayMul;    // nhân tốc độ xuống chỉ số
  final double toolMul;     // nhân lực của công cụ
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
    return Band((low - p).clamp(0, 100).toDouble(), (high + p).clamp(0, 100).toDouble());
  }

  bool contains(double v) => v >= low && v <= high;
}

// ========================= CẤU HÌNH THEO STAGE =======================

class StageConfig {
  /// Các band cho 4 chỉ số chính.
  final Map<String, Band> bands; // water/light/nutrient/clean
  /// Mức giảm mỗi ngày (điểm/ngày); sẽ quy đổi theo độ dài 1 ngày.
  final Map<String, double> decayPerDay; // key như trên
  /// Công cụ được mở ở stage này
  final List<ToolType> tools;
  /// Tốc độ tăng trưởng cơ bản (điểm/giây ở health=100)
  final double growthPerSecAtFullHealth;

  const StageConfig({
    required this.bands,
    required this.decayPerDay,
    required this.tools,
    required this.growthPerSecAtFullHealth,
  });
}

const statWater = 'water';
const statLight = 'light';
const statNutrient = 'nutrient';
const statClean = 'clean';

class StageConfigs {
  static final Map<PlantStage, StageConfig> base = {
    PlantStage.seed: StageConfig(
      bands: const {
        statWater: Band(60, 80),
        statLight: Band(20, 40),
        statNutrient: Band(0, 10),
        statClean: Band(60, 100),
      },
      decayPerDay: const {
        statWater: 12,
        statLight: 10,
        statNutrient: 8,
        statClean: 6,
      },
      tools: const [ToolType.water, ToolType.light, ToolType.pest],
      growthPerSecAtFullHealth: 0.55, // ~50s đạt 100 nếu luôn khỏe
    ),
    PlantStage.seedling: StageConfig(
      bands: const {
        statWater: Band(55, 75),
        statLight: Band(50, 70),
        statNutrient: Band(20, 40),
        statClean: Band(70, 100),
      },
      decayPerDay: const {
        statWater: 13,
        statLight: 10,
        statNutrient: 9,
        statClean: 6,
      },
      tools: const [ToolType.water, ToolType.light, ToolType.pest],
      growthPerSecAtFullHealth: 0.6,
    ),
    PlantStage.adult: StageConfig(
      bands: const {
        statWater: Band(50, 70),
        statLight: Band(60, 80),
        statNutrient: Band(40, 60),
        statClean: Band(75, 100),
      },
      decayPerDay: const {
        statWater: 14,
        statLight: 12,
        statNutrient: 10,
        statClean: 7,
      },
      tools: const [ToolType.water, ToolType.light, ToolType.nutrient, ToolType.pest, ToolType.prune],
      growthPerSecAtFullHealth: 0.55,
    ),
    PlantStage.flowering: StageConfig(
      bands: const {
        statWater: Band(50, 65),
        statLight: Band(70, 85),
        statNutrient: Band(50, 70),
        statClean: Band(80, 100),
      },
      decayPerDay: const {
        statWater: 14,
        statLight: 12,
        statNutrient: 10,
        statClean: 8,
      },
      tools: const [ToolType.water, ToolType.light, ToolType.nutrient, ToolType.pest, ToolType.prune],
      growthPerSecAtFullHealth: 0.5,
    ),
  };

  static StageConfig of(PlantStage stage, DifficultyConfig diff) {
    final cfg = base[stage]!;
    // Áp padding cho band theo mức khó/dễ
    final padded = cfg.bands.map((k, v) => MapEntry(k, v.pad(diff.bandPadding)));
    // Điều chỉnh decay theo mức khó/dễ
    final decay = cfg.decayPerDay.map((k, v) => MapEntry(k, v * diff.decayMul));
    return StageConfig(
      bands: padded,
      decayPerDay: decay,
      tools: cfg.tools,
      growthPerSecAtFullHealth: cfg.growthPerSecAtFullHealth,
    );
  }
}

// ============================== STATS ===============================

class Stats {
  double water;
  double light;
  double nutrient;
  double clean;
  double health; // 0..100 (tính từ bốn chỉ số)
  double growth; // 0..100 (đạt 100 để lên stage)

  Stats({
    required this.water,
    required this.light,
    required this.nutrient,
    required this.clean,
    this.health = 50,
    this.growth = 0,
  });

  Stats.initial()
      : water = 50,
        light = 50,
        nutrient = 20,
        clean = 70,
        health = 50,
        growth = 0;

  Stats copy() => Stats(
    water: water,
    light: light,
    nutrient: nutrient,
    clean: clean,
    health: health,
    growth: growth,
  );

  Map<String, double> asMap() => {
    statWater: water,
    statLight: light,
    statNutrient: nutrient,
    statClean: clean,
  };

  void setFromMap(Map<String, double> m) {
    water = (m[statWater] ?? water).clamp(0, 100).toDouble();
    light = (m[statLight] ?? light).clamp(0, 100).toDouble();
    nutrient = (m[statNutrient] ?? nutrient).clamp(0, 100).toDouble();
    clean = (m[statClean] ?? clean).clamp(0, 100).toDouble();
  }
}

// ===================== HÀM TÍNH HEALTH & GROWTH =====================

double _scoreFromBand(double v, Band band) {
  // 100 nếu nằm trong band, giảm dần khi lệch.
  if (band.contains(v)) return 100.0;
  final d = v < band.low ? (band.low - v) : (v - band.high);
  // mỗi 1 điểm lệch giảm 4 điểm (tối thiểu 0)
  final s = (100.0 - d * 4.0).clamp(0.0, 100.0);
  return s;
}

/// Health tổng hợp từ 4 chỉ số, có trọng số nhẹ cho Clean.
double computeHealth(Stats s, Map<String, Band> bands) {
  final sw = _scoreFromBand(s.water, bands[statWater]!);
  final sl = _scoreFromBand(s.light, bands[statLight]!);
  final sn = _scoreFromBand(s.nutrient, bands[statNutrient]!);
  final sc = _scoreFromBand(s.clean, bands[statClean]!);
  return (sw * 0.28 + sl * 0.28 + sn * 0.22 + sc * 0.22).clamp(0.0, 100.0);
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

/// Áp dụng hiệu ứng công cụ với cơ chế "tiệm cận" để tránh vượt đỏ.
/// [baseDelta] có thể âm hoặc dương (ví dụ kéo rèm giảm light => âm).
/// [nearDist] khoảng cách coi như "gần" band để giảm lực.
/// [kNear] hệ số lực khi gần band; [kInside] khi đã ở trong band.
double applyToolValue(
    double current,
    double baseDelta,
    Band band, {
      double nearDist = 12,
      double kNear = 0.4,
      double kInside = 0.25,
    }) {
  double factor;
  if (band.contains(current)) {
    factor = kInside; // trong band → lực nhỏ, tránh nhảy sang đỏ
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

  // Tiến độ & thời gian
  final int totalDays; // ví dụ 5
  final int dayLengthSec; // ví dụ 90s
  int dayIndex; // 1..totalDays
  int timeLeftSec; // đếm ngược trong ngày
  bool paused;

  // Cooldown mỗi stat để hạn chế spam công cụ
  final Map<String, double> _cooldownSec = {
    statWater: 0,
    statLight: 0,
    statNutrient: 0,
    statClean: 0,
  };

  // Tham số cơ bản cho công cụ (trước khi nhân toolMul & tiệm cận)
  double baseWaterPerUse = 18; // điểm
  double baseLightPerUse = 15; // điểm (có thể dùng âm để giảm)
  double baseNutrientPerUse = 12;
  double baseCleanPerUse = 10; // bắt sâu/tỉa đúng sẽ +clean
  double cooldownPerUseSec = 3.0;

  // Ngưỡng tăng stage (growth 0..100)
  final Map<PlantStage, double> growthForNext = const {
    PlantStage.seed: 100,
    PlantStage.seedling: 100,
    PlantStage.adult: 100,
    PlantStage.flowering: 100, // đạt 100 thì coi như hoàn tất vòng đời run
  };

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
        timeLeftSec = initialTimeLeftSec ?? 90;

  StageConfig get stageConfig => StageConfigs.of(stage, _diff);

  bool get isFinished => dayIndex > totalDays;

  /// Gọi mỗi khung thời gian (delta giây). Nếu đang pause thì chỉ giảm cooldown.
  void tick(double deltaSec) {
    // Giảm cooldown dù đang pause (để tránh tích quá nhiều), hoặc bạn có thể giữ nguyên.
    _cooldownSec.updateAll((key, value) => (value - deltaSec).clamp(0.0, 9999.0));

    if (paused || isFinished) return;

    // Quy đổi decay theo độ dài 1 ngày: decayPerDay / dayLengthSec mỗi giây
    final d = stageConfig.decayPerDay;
    stats.water = (stats.water - (d[statWater]! / dayLengthSec) * deltaSec).clamp(0.0, 100.0);
    stats.light = (stats.light - (d[statLight]! / dayLengthSec) * deltaSec).clamp(0.0, 100.0);
    stats.nutrient = (stats.nutrient - (d[statNutrient]! / dayLengthSec) * deltaSec).clamp(0.0, 100.0);
    stats.clean = (stats.clean - (d[statClean]! / dayLengthSec) * deltaSec).clamp(0.0, 100.0);

    // Cập nhật health theo band hiện tại
    stats.health = computeHealth(stats, stageConfig.bands);

    // Tăng trưởng dựa trên health
    final gRate = stageConfig.growthPerSecAtFullHealth; // tại 100 health
    final inc = gRate * (stats.health / 100.0) * deltaSec;
    stats.growth = (stats.growth + inc).clamp(0.0, 100.0);

    // Chuyển stage nếu đủ growth
    _maybeAdvanceStage();

    // Thời gian ngày
    timeLeftSec -= deltaSec.toInt();
    if (timeLeftSec < 0) timeLeftSec = 0;
  }

  void _maybeAdvanceStage() {
    final need = growthForNext[stage]!;
    if (stats.growth >= need) {
      // Reset growth khi lên stage mới (cảm giác "chinh phục")
      stats.growth = 0;
      switch (stage) {
        case PlantStage.seed:
          stage = PlantStage.seedling;
          break;
        case PlantStage.seedling:
          stage = PlantStage.adult;
          break;
        case PlantStage.adult:
          stage = PlantStage.flowering;
          break;
        case PlantStage.flowering:
        // đã max; không tăng nữa.
          break;
      }
    }
  }

  /// Kết thúc một ngày chơi (hết thời gian hoặc người chơi bấm), trả về điểm sao 0..3.
  int endDayAndScore() {
    // Đánh giá theo health trung bình cuối ngày + số chỉ số trong band.
    final bands = stageConfig.bands;
    final inBandCount = [
      bands[statWater]!.contains(stats.water),
      bands[statLight]!.contains(stats.light),
      bands[statNutrient]!.contains(stats.nutrient),
      bands[statClean]!.contains(stats.clean),
    ].where((e) => e).length;

    final h = stats.health; // 0..100
    int stars = 0;
    if (h >= 80 && inBandCount >= 3) stars = 3;
    else if (h >= 60 && inBandCount >= 2) stars = 2;
    else if (h >= 40 && inBandCount >= 1) stars = 1;
    else stars = 0;

    // ✅ PHẦN ĐÃ SỬA
    // Tăng ngày lên trước
    dayIndex += 1;

    // Chỉ reset thời gian nếu game chưa thực sự kết thúc (chưa bước qua ngày cuối)
    if (!isFinished) {
      timeLeftSec = dayLengthSec;
    }
    // ✅ KẾT THÚC PHẦN SỬA

    return stars;
  }

  /// Bật/tắt tạm dừng (mở hướng dẫn, menu, ...)
  void setPaused(bool v) {
    paused = v;
  }

  bool _onCooldown(String stat) => (_cooldownSec[stat] ?? 0) > 0.0;

  ToolEffectResult? _applyToStat({
    required String stat,
    required double baseDelta,
  }) {
    if (_onCooldown(stat)) return null;

    final band = stageConfig.bands[stat]!;
    final current = stats.asMap()[stat]!;

    final applied = applyToolValue(
      current,
      baseDelta * _diff.toolMul,
      band,
    );

    final result = ToolEffectResult(
      stat: stat,
      before: current,
      appliedDelta: (applied - current),
      after: applied,
    );

    // Ghi lại
    switch (stat) {
      case statWater:
        stats.water = applied;
        break;
      case statLight:
        stats.light = applied;
        break;
      case statNutrient:
        stats.nutrient = applied;
        break;
      case statClean:
        stats.clean = applied;
        break;
    }

    // Sau khi thay đổi, cập nhật health ngay để UI phản hồi nhanh
    stats.health = computeHealth(stats, stageConfig.bands);

    _cooldownSec[stat] = cooldownPerUseSec;
    return result;
  }

  /// Áp dụng công cụ. Với Light có thể truyền delta âm để giảm sáng (kéo rèm).
  ToolEffectResult? applyTool(ToolType t, {double delta = 1.0}) {
    if (isFinished || paused) return null;

    switch (t) {
      case ToolType.water:
        return _applyToStat(stat: statWater, baseDelta: baseWaterPerUse * delta);
      case ToolType.light:
        return _applyToStat(stat: statLight, baseDelta: baseLightPerUse * delta);
      case ToolType.nutrient:
        return _applyToStat(stat: statNutrient, baseDelta: baseNutrientPerUse * delta);
      case ToolType.pest:
      // Bắt sâu đúng → tăng Clean
        return _applyToStat(stat: statClean, baseDelta: baseCleanPerUse * delta);
      case ToolType.prune:
      // Tỉa đúng → tăng Clean nhẹ; có thể mở rộng logic giảm nếu tỉa quá tay trong mini-game.
        return _applyToStat(stat: statClean, baseDelta: (baseCleanPerUse * 0.8) * delta);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'stage': stage.index,
      'difficulty': difficultyLevel.index,
      'stats': {
        statWater: stats.water,
        statLight: stats.light,
        statNutrient: stats.nutrient,
        statClean: stats.clean,
        'health': stats.health,
        'growth': stats.growth,
      },
      'totalDays': totalDays,
      'dayLengthSec': dayLengthSec,
      'dayIndex': dayIndex,
      'timeLeftSec': timeLeftSec,
    };
  }

  factory PlantState.fromMap(Map<String, dynamic> map) {
    final stage = PlantStage.values[(map['stage'] as num).toInt()];
    final diff = DifficultyLevel.values[(map['difficulty'] as num).toInt()];
    final s = map['stats'] as Map<String, dynamic>;

    return PlantState(
      stage: stage,
      initialStats: Stats(
        water: (s[statWater] as num).toDouble(),
        light: (s[statLight] as num).toDouble(),
        nutrient: (s[statNutrient] as num).toDouble(),
        clean: (s[statClean] as num).toDouble(),
        health: (s['health'] as num).toDouble(),
        growth: (s['growth'] as num).toDouble(),
      ),
      difficultyLevel: diff,
      totalDays: (map['totalDays'] as num).toInt(),
      dayLengthSec: (map['dayLengthSec'] as num).toInt(),
      dayIndex: (map['dayIndex'] as num).toInt(),
      initialTimeLeftSec: (map['timeLeftSec'] as num).toInt(),
    );
  }
}