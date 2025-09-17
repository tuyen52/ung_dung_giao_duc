// lib/game/plant_care/plant_care_play_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mobileapp/game/core/game.dart';

import 'data/plant_care_data.dart';
import 'core/balance.dart';
import 'models/weather.dart';
import 'models/quests.dart';
import 'models/plant_entity.dart';
import 'widgets/plant_card.dart';
import 'widgets/day_summary_dialog.dart';

/// ================== Cấu hình độ khó (5 ngày cố định) ==================
class DifficultyConfig {
  final double toolMul, decayMulWater, decayMulLight, decayMulNutrient;
  final int growthMul, initStat;
  final int resNuoc, resSang, resPhan, resSau, resTia;
  final double pestChance, overgrownChance;
  final double wSunny, wCloudy, wRainy; // phân bố thời tiết

  const DifficultyConfig({
    required this.toolMul,
    required this.decayMulWater,
    required this.decayMulLight,
    required this.decayMulNutrient,
    required this.growthMul,
    required this.initStat,
    required this.resNuoc,
    required this.resSang,
    required this.resPhan,
    required this.resSau,
    required this.resTia,
    required this.pestChance,
    required this.overgrownChance,
    required this.wSunny,
    required this.wCloudy,
    required this.wRainy,
  });
}

DifficultyConfig _cfgFor(int d) {
  if (d <= 1) {
    // Dễ
    return const DifficultyConfig(
      toolMul: 1.20, decayMulWater: 0.90, decayMulLight: 0.90, decayMulNutrient: 0.90,
      growthMul: 7, initStat: 60,
      resNuoc: 24, resSang: 18, resPhan: 15, resSau: 12, resTia: 12,
      pestChance: 0.10, overgrownChance: 0.08,
      wSunny: 0.33, wCloudy: 0.34, wRainy: 0.33,
    );
  } else if (d == 2) {
    // Vừa (mặc định)
    return const DifficultyConfig(
      toolMul: 1.00, decayMulWater: 1.00, decayMulLight: 1.00, decayMulNutrient: 1.00,
      growthMul: 6, initStat: 50,
      resNuoc: 22, resSang: 16, resPhan: 13, resSau: 11, resTia: 11,
      pestChance: 0.18, overgrownChance: 0.15,
      wSunny: 0.40, wCloudy: 0.30, wRainy: 0.30,
    );
  } else {
    // Khó
    return const DifficultyConfig(
      toolMul: 0.85, decayMulWater: 1.10, decayMulLight: 1.10, decayMulNutrient: 1.10,
      growthMul: 5, initStat: 45,
      resNuoc: 20, resSang: 14, resPhan: 12, resSau: 10, resTia: 10,
      pestChance: 0.25, overgrownChance: 0.22,
      wSunny: 0.45, wCloudy: 0.30, wRainy: 0.25,
    );
  }
}

Weather _rollWeatherWeighted(Random rnd, DifficultyConfig c) {
  final r = rnd.nextDouble();
  if (r < c.wSunny) return Weather.sunny;
  if (r < c.wSunny + c.wCloudy) return Weather.cloudy;
  return Weather.rainy;
}

/// ================== Màn chơi ==================
class PlantCarePlayScreen extends StatefulWidget {
  final Game game;
  final void Function(int correct, int wrong) onFinish;

  const PlantCarePlayScreen({
    super.key,
    required this.game,
    required this.onFinish,
  });

  @override
  State<PlantCarePlayScreen> createState() => PlantCarePlayScreenState();
}

class PlantCarePlayScreenState extends State<PlantCarePlayScreen> {
  final _rnd = Random();
  final List<Plant> _plants = [];
  late Map<CareToolType, int> _resources;

  int correctActions = 0;
  int wrongActions = 0;
  int _currentDay = 1;
  int? _selectedPlantIndex;

  // tổng sticker theo ngày
  final Map<Sticker, int> _stickerBag = {
    Sticker.gold: 0, Sticker.silver: 0, Sticker.bronze: 0, Sticker.none: 0,
  };

  // thời tiết ngày hiện tại
  Weather _todayWeather = Weather.sunny;

  DifficultyConfig get _cfg => _cfgFor(widget.game.difficulty);

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.setLanguageCode('en');
    _initializeGame();
  }

  /// Kiểm tra dữ liệu loài: tolerance phải >= optimal.high (tránh cấu hình "không bao giờ vào xanh")
  void _validateSpeciesData() {
    for (final e in plantSpeciesData.entries) {
      final sp = e.value;
      assert(sp.optimalWater.low <= sp.optimalWater.high,
      'Invalid optimal water range for ${sp.name}');
      assert(sp.optimalLight.low <= sp.optimalLight.high,
      'Invalid optimal light range for ${sp.name}');
      assert(sp.optimalNutrient.low <= sp.optimalNutrient.high,
      'Invalid optimal nutrient range for ${sp.name}');

      assert(sp.waterTolerance >= sp.optimalWater.high,
      'Water tolerance of ${sp.name} < optimal.high');
      assert(sp.lightTolerance >= sp.optimalLight.high,
      'Light tolerance of ${sp.name} < optimal.high');
      assert(sp.nutrientTolerance >= sp.optimalNutrient.high,
      'Nutrient tolerance of ${sp.name} < optimal.high');
    }
  }

  void _initializeGame() {
    _plants.clear();
    final cfg = _cfg;

    // Kiểm tra cấu hình loài (chạy ở debug)
    assert(() {
      _validateSpeciesData();
      return true;
    }());

    final plantTypesToSpawn = [
      PlantType.normal, PlantType.cactus, PlantType.fern, PlantType.normal
    ]..shuffle(_rnd);

    for (final type in plantTypesToSpawn) {
      final species = plantSpeciesData[type]!;
      final stage = PlantStage.hatGiong;

      final p = Plant(
        type: type,
        speciesName: species.name,
        label: plantStageCreativeNames[stage]!,
        stage: stage,
        waterLevel: cfg.initStat.toDouble(),
        lightLevel: cfg.initStat.toDouble(),
        nutrientLevel: cfg.initStat.toDouble(),
      );
      p.quests = generateQuestsForStage(stage);
      _plants.add(p);
    }

    _resources = {
      CareToolType.nuoc: cfg.resNuoc,
      CareToolType.anhSang: cfg.resSang,
      CareToolType.phanBon: cfg.resPhan,
      CareToolType.thuocTruSau: cfg.resSau,
      CareToolType.catTia: cfg.resTia,
    };

    _selectedPlantIndex = null;
    _todayWeather = _rollWeatherWeighted(_rnd, cfg);

    setState(() {});
  }

  // ===== UI helper: snack ở trên =====
  void _showTopSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final snackBar = SnackBar(
      content: Text(message, textAlign: TextAlign.center),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 150,
        left: 20, right: 20,
      ),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _selectPlant(int index) {
    setState(() => _selectedPlantIndex = index);
    _showTopSnackBar('Đã chọn cây "${_plants[index].speciesName}"!', Colors.blue);
  }

  // ===== Helper: tăng hướng về vùng OK, tránh nhảy sang Đỏ =====
  double _applyIncrementTowardsOk({
    required double current,
    required Range optimal,
    required double effect,
    required double tolerance,
  }) {
    // Ranh trên vẫn còn "Xanh"
    final double maxOk = optimal.high + tolHi;

    // Nếu đang Low -> nhắm tới giữa vùng tối ưu
    if (current < optimal.low) {
      final double targetMid = (optimal.low + optimal.high) / 2.0;
      final double needed = targetMid - current; // cần bù để lên giữa vùng
      final double delta = needed <= 0 ? 0 : min(effect, needed);
      final double projected = current + delta;
      return projected.clamp(0.0, min(maxOk, tolerance));
    }

    // Nếu đang OK/High -> tăng nhưng kẹp ở ranh Xanh tối đa
    final double projected = current + effect;
    final double cappedOk = min(projected, maxOk);
    return min(cappedOk, tolerance).clamp(0.0, 100.0);
  }

  /// ===== NEW: Áp tiến độ + lên stage CÓ GIỮ PHẦN TRÀN =====
  void _applyGrowthAndStage(Plant plant, int dayScore, DifficultyConfig cfg) {
    var gp = plant.growthProgress + dayScore * cfg.growthMul;

    // Có thể lên nhiều stage trong cùng 1 ngày nếu đủ điểm
    while (gp >= 100 && plant.stage != PlantStage.raHoa) {
      gp -= 100; // GIỮ phần tràn qua stage mới
      plant.stage = PlantStage.values[plant.stage.index + 1];
      plant.label = plantStageCreativeNames[plant.stage]!;
      plant.animationTrigger = AnimationTrigger.healthy;
      plant.animationCounter++;
      plant.quests = generateQuestsForStage(plant.stage);
    }

    plant.growthProgress = clampInt(gp, 0, 100);

    if (plant.stage == PlantStage.raHoa && plant.growthProgress >= 100) {
      plant.isCompleted = true;
    }
  }

  // ===== Kết thúc ngày: decay (theo thời tiết & độ khó) + chấm điểm + quest + stage =====
  void _endDay() {
    setState(() {
      final cfg = _cfg;
      _stickerBag.updateAll((_, __) => 0);

      final wx = kWeather[_todayWeather]!;
      for (var plant in _plants) {
        if (plant.isCompleted) continue;
        final species = plantSpeciesData[plant.type]!;

        // 1) Decay có nhân thời tiết + độ khó
        plant.waterLevel = clamp100(
          plant.waterLevel - (baseDailyDecay * species.waterNeed * wx.waterMul * cfg.decayMulWater),
        );
        plant.lightLevel = clamp100(
          plant.lightLevel - (baseDailyDecay * species.lightNeed * wx.lightMul * cfg.decayMulLight),
        );
        plant.nutrientLevel = clamp100(
          plant.nutrientLevel - (nutrientDailyDecay * cfg.decayMulNutrient),
        );

        // 2) Zone & điểm
        final wz = zoneOf(plant.waterLevel, species.optimalWater);
        final lz = zoneOf(plant.lightLevel, species.optimalLight);
        final nz = zoneOf(plant.nutrientLevel, species.optimalNutrient);

        var dayScore = dailyGrowthScore(wz, lz, nz, pests: plant.pests, overgrown: plant.overgrown);

        // 3) Quest
        final greens = [wz, lz, nz].where((z) => z == Zone.ok).length;
        for (final q in plant.quests) {
          if (q.completed) continue;
          switch (q.type) {
            case QuestType.okZonesDays:
              if (greens >= q.requiredOkCount) {
                q.progressDays++;
                dayScore += 3; // bonus nhẹ khi đạt điều kiện ngày
                if (q.progressDays >= q.targetDays) {
                  q.completed = true;
                  dayScore += 2; // bonus khi hoàn thành
                }
              }
              break;
            case QuestType.handlePestsOnce:
            case QuestType.pruneOnce:
            // đánh dấu ở _applyTool
              break;
          }
        }

        plant.lastDailyScore = dayScore;

        // 4) NEW: quy đổi điểm → tiến độ + lên stage GIỮ PHẦN TRÀN
        _applyGrowthAndStage(plant, dayScore, cfg);

        // 5) Sticker
        final s = stickerFromScore(dayScore);
        plant.lastSticker = s;
        _stickerBag[s] = (_stickerBag[s] ?? 0) + 1;

        // 6) Animation feedback
        if (dayScore >= 10) {
          plant.animationTrigger = AnimationTrigger.healthy;
          plant.animationCounter++;
        } else if (dayScore == 0) {
          plant.animationTrigger = AnimationTrigger.unhealthy;
          plant.animationCounter++;
        }

        // 7) Sự kiện nhỏ theo độ khó
        if (!plant.pests && _rnd.nextDouble() < _cfg.pestChance) {
          plant.pests = true;
        }
        if (!plant.overgrown && _rnd.nextDouble() < _cfg.overgrownChance) {
          plant.overgrown = true;
        }
      }

      // Thời tiết ngày tới + summary
      final nextWeather = _rollWeatherWeighted(_rnd, _cfg);
      final endedDay = _currentDay;
      _currentDay++;
      _selectedPlantIndex = null;

      if (_currentDay > totalDays) {
        widget.onFinish(correctActions, wrongActions);
      } else {
        showDaySummaryDialog(
          context: context,
          dayIndex: endedDay,
          plants: _plants,
          stickerBag: _stickerBag,
          nextWeather: nextWeather,
        );
        _todayWeather = nextWeather;
      }
    });
  }

  // ===== Áp dụng công cụ (có nhân hiệu lực theo độ khó + kiểm tra projected & vùng OK) =====
  void _applyTool(Plant plant, CareToolType toolType) {
    final cfg = _cfg;

    if (_resources[toolType]! <= 0) {
      _showTopSnackBar('Hết ${plantCareTools.firstWhere((t) => t.type == toolType).label}!', Colors.orange);
      return;
    }

    final tool = plantCareTools.firstWhere((t) => t.type == toolType);
    final species = plantSpeciesData[plant.type]!;

    setState(() {
      _resources[toolType] = _resources[toolType]! - 1;
      bool actionWasCorrect = true;

      switch (toolType) {
        case CareToolType.nuoc: {
          final double step = toolEffectAmount * cfg.toolMul;
          final double projected = clamp100(plant.waterLevel + step);

          // Chặn tolerance trước
          if (projected > species.waterTolerance) {
            wrongActions++; actionWasCorrect = false;
            _showTopSnackBar('${species.name} không ưa nhiều nước! Dễ úng.', Colors.red);
          } else {
            final after = _applyIncrementTowardsOk(
              current: plant.waterLevel,
              optimal: species.optimalWater,
              effect: step,
              tolerance: species.waterTolerance,
            );
            if ((after - plant.waterLevel).abs() < 0.001) {
              wrongActions++; actionWasCorrect = false;
              _showTopSnackBar('Đã đủ nước cho hôm nay. Đừng “quá tay” nhé!', Colors.orange);
            } else {
              plant.waterLevel = after;
            }
          }
          break;
        }

        case CareToolType.anhSang: {
          final double step = toolEffectAmount * cfg.toolMul;
          final double projected = clamp100(plant.lightLevel + step);
          if (projected > species.lightTolerance) {
            wrongActions++; actionWasCorrect = false;
            _showTopSnackBar('${species.name} không thích nắng gắt! Cháy lá.', Colors.red);
          } else {
            final after = _applyIncrementTowardsOk(
              current: plant.lightLevel,
              optimal: species.optimalLight,
              effect: step,
              tolerance: species.lightTolerance,
            );
            if ((after - plant.lightLevel).abs() < 0.001) {
              wrongActions++; actionWasCorrect = false;
              _showTopSnackBar('Ánh sáng đã đủ. Đừng đẩy quá nhé!', Colors.orange);
            } else {
              plant.lightLevel = after;
            }
          }
          break;
        }

        case CareToolType.phanBon: {
          final double step = toolEffectAmount * cfg.toolMul;
          final double projected = clamp100(plant.nutrientLevel + step);
          if (projected > species.nutrientTolerance) {
            wrongActions++; actionWasCorrect = false;
            _showTopSnackBar('Bón quá tay dễ “cháy rễ”.', Colors.red);
          } else {
            final after = _applyIncrementTowardsOk(
              current: plant.nutrientLevel,
              optimal: species.optimalNutrient,
              effect: step,
              tolerance: species.nutrientTolerance,
            );
            if ((after - plant.nutrientLevel).abs() < 0.001) {
              wrongActions++; actionWasCorrect = false;
              _showTopSnackBar('Dinh dưỡng đã đủ rồi.', Colors.orange);
            } else {
              plant.nutrientLevel = after;
            }
          }
          break;
        }

        case CareToolType.thuocTruSau:
          if (plant.pests) {
            plant.pests = false;
            for (final q in plant.quests) {
              if (q.type == QuestType.handlePestsOnce && !q.completed) { q.completed = true; break; }
            }
            correctActions++;
            _showTopSnackBar('Tuyệt! Cây đã hết sâu bệnh.', Colors.green);
            return;
          } else {
            wrongActions++; actionWasCorrect = false;
            _showTopSnackBar('Hôm nay chưa có sâu để bắt.', Colors.orange);
          }
          break;

        case CareToolType.catTia:
          if (plant.overgrown) {
            plant.overgrown = false;
            for (final q in plant.quests) {
              if (q.type == QuestType.pruneOnce && !q.completed) { q.completed = true; break; }
            }
            correctActions++;
            _showTopSnackBar('Đã tỉa gọn gàng! Cây dễ thở hơn.', Colors.green);
            return;
          } else {
            wrongActions++; actionWasCorrect = false;
            _showTopSnackBar('Cây chưa rậm rạp để tỉa.', Colors.orange);
          }
          break;
      }

      if (actionWasCorrect) {
        correctActions++;
        _showTopSnackBar('Đã dùng ${tool.label} cho ${plant.speciesName}! ${tool.explanation}', Colors.green);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = screenHeight * 0.04;
    final wx = kWeather[_todayWeather]!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/garden_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // ===== Header (đã fix overflow bằng Expanded/Flexible) =====
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8, runSpacing: 4,
                        children: [
                          Chip(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            avatar: const Icon(Icons.star),
                            label: Text('Ngày: $_currentDay/$totalDays'),
                          ),
                          Chip(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            avatar: Icon(wx.icon, color: Colors.orange),
                            label: Text('Thời tiết: ${wx.name}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: FilledButton(
                        onPressed: _endDay,
                        child: const Text('Kết thúc ngày'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_selectedPlantIndex != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Đang chăm sóc: ${_plants[_selectedPlantIndex!].speciesName}',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                  ),
                ),
              ),

            // ===== Lưới thẻ cây =====
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.7,
                ),
                itemCount: _plants.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _selectPlant(i),
                  child: PlantCard(plant: _plants[i], fontSize: fontSize, isSelected: _selectedPlantIndex == i),
                ),
              ),
            ),

            // ===== Thanh công cụ (cuộn ngang để chống tràn) =====
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: plantCareTools.map((tool) {
                      final isEnabled =
                          _resources[tool.type]! > 0 && _selectedPlantIndex != null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: isEnabled
                                  ? () => _applyTool(_plants[_selectedPlantIndex!], tool.type)
                                  : null,
                              icon: Icon(
                                tool.icon,
                                size: 32,
                                color: isEnabled ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _resources[tool.type].toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _resources[tool.type]! > 0 ? Colors.white : Colors.grey.shade600,
                                shadows: [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.5))],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
