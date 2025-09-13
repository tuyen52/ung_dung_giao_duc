import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobileapp/game/core/game.dart';
import 'package:mobileapp/game/core/types.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'data/plant_care_data.dart';

// --- Game Balance Constants (Hằng số cân bằng game) ---
const double initialStatLevel = 50.0;
const double toolEffectAmount = 30.0;
const double healthPenaltyAmount = 30.0;
const double eventHealthEffect = 20.0;
const double baseDailyDecay = 20.0;
const double nutrientDailyDecay = 15.0;
const double growthHealthThreshold = 80.0;
const double unhealthyHealthThreshold = 30.0;
const int totalDays = 3;

enum AnimationTrigger { idle, healthy, unhealthy }

enum PlantStage {
  hatGiong(0.4),
  cayCon(0.3),
  truongThanh(0.25),
  raHoa(0.2);

  final double eventProbability;
  const PlantStage(this.eventProbability);
}

enum PlantIssue { datKho, thieuAnhSang, sauBenh, quaTai, thieuChatDinhDuong }

enum CareToolType { nuoc, anhSang, thuocTruSau, catTia, phanBon }

class CareTool {
  final String label;
  final IconData icon;
  final CareToolType type;
  final PlantIssue fixes;
  final String explanation;
  const CareTool(this.label, this.icon, this.type, this.fixes, this.explanation);
}

class Plant {
  final PlantType type;
  String speciesName;
  String label;
  PlantStage stage;
  double waterLevel;
  double lightLevel;
  double nutrientLevel;
  double health;
  bool isCompleted;
  AnimationTrigger animationTrigger = AnimationTrigger.idle;
  int animationCounter = 0;

  Plant({
    required this.type,
    required this.speciesName,
    required this.label,
    required this.stage,
    required this.waterLevel,
    required this.lightLevel,
    required this.nutrientLevel,
    required this.health,
    required this.isCompleted,
  });
}

class PlantCarePlayScreen extends StatefulWidget {
  final Game game;
  final FinishCallback onFinish;

  const PlantCarePlayScreen({super.key, required this.game, required this.onFinish});

  @override
  State<PlantCarePlayScreen> createState() => PlantCarePlayScreenState();
}

class PlantCarePlayScreenState extends State<PlantCarePlayScreen> {
  // Game State
  final _rnd = Random();
  final List<Plant> _plants = [];
  late Map<CareToolType, int> _resources;
  int correctActions = 0;
  int wrongActions = 0;
  int _currentDay = 1;
  int? _selectedPlantIndex;

  // --- 1. Game Lifecycle Methods ---

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.setLanguageCode('en');
    _initializeGame();
  }

  void _initializeGame() {
    _plants.clear();
    final stages = PlantStage.values;
    final plantTypesToSpawn = [PlantType.normal, PlantType.cactus, PlantType.fern, PlantType.normal];
    plantTypesToSpawn.shuffle(_rnd);

    for (final type in plantTypesToSpawn) {
      final species = plantSpeciesData[type]!;
      final stage = stages[0];

      final newPlant = Plant(
        type: type,
        speciesName: species.name,
        label: plantStageCreativeNames[stage]!,
        stage: stage,
        waterLevel: initialStatLevel,
        lightLevel: initialStatLevel,
        nutrientLevel: initialStatLevel,
        health: 0,
        isCompleted: false,
      );
      newPlant.health = _calculateHealth(newPlant);
      _plants.add(newPlant);
    }

    _resources = {
      CareToolType.nuoc: 20 + widget.game.difficulty * 2,
      CareToolType.anhSang: 15 + widget.game.difficulty,
      CareToolType.phanBon: 12 + widget.game.difficulty,
      CareToolType.thuocTruSau: 10 + widget.game.difficulty,
      CareToolType.catTia: 10 + widget.game.difficulty,
    };
    _selectedPlantIndex = null;
    if (mounted) {
      setState(() {});
    }
  }

  // --- 2. Player Action Methods ---

  // ==================== HÀM MỚI ĐỂ HIỂN THỊ THÔNG BÁO Ở TRÊN ====================
  void _showTopSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final snackBar = SnackBar(
      content: Text(message, textAlign: TextAlign.center),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating, // Quan trọng: để SnackBar nổi lên
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 150, // Đẩy SnackBar lên trên
        left: 20,
        right: 20,
      ),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  // ===========================================================================


  void _selectPlant(int index) {
    setState(() {
      _selectedPlantIndex = index;
    });
    // ĐÃ CẬP NHẬT: Sử dụng hàm mới
    _showTopSnackBar('Đã chọn cây "${_plants[index].speciesName}"!', Colors.blue);
  }

  void _endDay() {
    setState(() {
      for (var plant in _plants) {
        if (plant.isCompleted) continue;

        final species = plantSpeciesData[plant.type]!;

        plant.waterLevel = (plant.waterLevel - (baseDailyDecay * species.waterNeed)).clamp(0, 100);
        plant.lightLevel = (plant.lightLevel - (baseDailyDecay * species.lightNeed)).clamp(0, 100);
        plant.nutrientLevel = (plant.nutrientLevel - nutrientDailyDecay).clamp(0, 100);

        _updatePlantStatus(plant);
      }

      _currentDay++;
      _selectedPlantIndex = null;

      if (_currentDay > totalDays) {
        widget.onFinish(correctActions, wrongActions);
      } else {
        _showDaySummary();
      }
    });
  }

  // --- 3. Core Game Logic ---

  double _calculateHealth(Plant plant) {
    final average = (plant.waterLevel + plant.lightLevel + plant.nutrientLevel) / 3;
    return average.clamp(0.0, 100.0);
  }

  void _updatePlantStatus(Plant plant, {bool recalculateHealth = true}) {
    if (recalculateHealth) {
      plant.health = _calculateHealth(plant);
    }

    if (plant.health >= growthHealthThreshold && plant.stage != PlantStage.raHoa) {
      plant.stage = PlantStage.values[plant.stage.index + 1];
      plant.label = plantStageCreativeNames[plant.stage]!;
      plant.animationTrigger = AnimationTrigger.healthy;
      plant.animationCounter++;
    } else if (plant.health < unhealthyHealthThreshold) {
      plant.animationTrigger = AnimationTrigger.unhealthy;
      plant.animationCounter++;
    }

    if (plant.stage == PlantStage.raHoa && plant.health >= growthHealthThreshold) {
      plant.isCompleted = true;
    }
  }

  void _applyTool(Plant plant, CareToolType toolType) {
    if (_resources[toolType]! <= 0) {
      // ĐÃ CẬP NHẬT: Sử dụng hàm mới
      _showTopSnackBar('Hết ${plantCareTools.firstWhere((t) => t.type == toolType).label}!', Colors.orange);
      return;
    }

    final tool = plantCareTools.firstWhere((t) => t.type == toolType);
    final species = plantSpeciesData[plant.type]!;

    setState(() {
      _resources[toolType] = _resources[toolType]! - 1;

      bool actionWasCorrect = true;

      switch (toolType) {
        case CareToolType.nuoc:
          if (plant.waterLevel > species.waterTolerance) {
            plant.health = (plant.health - healthPenaltyAmount).clamp(0, 100);
            wrongActions++;
            actionWasCorrect = false;
            // ĐÃ CẬP NHẬT: Sử dụng hàm mới
            _showTopSnackBar('${species.name} không ưa nhiều nước! Cây bị úng.', Colors.red);
          } else {
            plant.waterLevel = (plant.waterLevel + toolEffectAmount).clamp(0, 100);
          }
          break;
        case CareToolType.anhSang:
          if (plant.lightLevel > species.lightTolerance) {
            plant.health = (plant.health - healthPenaltyAmount).clamp(0, 100);
            wrongActions++;
            actionWasCorrect = false;
            // ĐÃ CẬP NHẬT: Sử dụng hàm mới
            _showTopSnackBar('${species.name} không thích nắng gắt! Cây bị cháy nắng.', Colors.red);
          } else {
            plant.lightLevel = (plant.lightLevel + toolEffectAmount).clamp(0, 100);
          }
          break;
        case CareToolType.phanBon:
          plant.nutrientLevel = (plant.nutrientLevel + toolEffectAmount).clamp(0, 100);
          break;
        case CareToolType.thuocTruSau:
        case CareToolType.catTia:
          break;
      }

      if (actionWasCorrect) {
        correctActions++;
        // ĐÃ CẬP NHẬT: Sử dụng hàm mới
        _showTopSnackBar('Đã dùng ${tool.label} cho ${plant.speciesName}! ${tool.explanation}', Colors.green);
      }

      if (actionWasCorrect) {
        _updatePlantStatus(plant, recalculateHealth: true);
      } else {
        _updatePlantStatus(plant, recalculateHealth: false);
      }

      _triggerRandomEvent(plant);
    });
  }

  void _triggerRandomEvent(Plant plant) {
    if (_rnd.nextDouble() > plant.stage.eventProbability) return;

    final possibleIssues = plantStageRules[plant.stage];
    if (possibleIssues == null || possibleIssues.isEmpty) return;

    final issue = possibleIssues[_rnd.nextInt(possibleIssues.length)];
    _showPlantIssueEvent(plant, issue);
  }

  // --- 4. UI and Dialog Methods ---

  void _showPlantIssueEvent(Plant plant, PlantIssue issue) {
    final issueLabel = plantIssueLabels[issue] ?? "Vấn đề không xác định";
    final correctTool = plantCareTools.firstWhere((tool) => tool.fixes == issue);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Sự kiện: $issueLabel'),
        content: Text('Cây ${plant.speciesName} đang gặp vấn đề. Chọn công cụ phù hợp để cứu cây.'),
        actions: plantCareTools.map((tool) => TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (tool.type == correctTool.type && _resources[tool.type]! > 0) {
              setState(() {
                plant.health = (plant.health + eventHealthEffect).clamp(0, 100);
                correctActions += 5;
                _resources[tool.type] = _resources[tool.type]! - 1;
              });
              // ĐÃ CẬP NHẬT: Sử dụng hàm mới
              _showTopSnackBar('Tuyệt vời! Cây đã được cứu khỏi $issueLabel!', Colors.green);
            } else {
              setState(() {
                plant.health = (plant.health - eventHealthEffect).clamp(0, 100);
                wrongActions++;
              });
              // ĐÃ CẬP NHẬT: Sử dụng hàm mới
              _showTopSnackBar('Sai công cụ! Cây bị ảnh hưởng bởi $issueLabel.', Colors.red);
            }
          },
          child: Text(tool.label),
        )).toList(),
      ),
    );
  }

  void _showDaySummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kết thúc ngày ${_currentDay - 1}'),
        content: const Text('Bắt đầu ngày mới! Tiếp tục chăm sóc để cây ra hoa!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  // --- GHI CHÚ: ĐÃ XÓA HÀM _showHandbook() KHÔNG CÒN ĐƯỢC SỬ DỤNG ---

  // --- 5. Build Method ---
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = screenHeight * 0.04;

    return Scaffold(
      // --- GHI CHÚ: ĐÃ XÓA floatingActionButton TẠI ĐÂY ---
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/garden_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      avatar: const Icon(Icons.star),
                      label: Text('Ngày: $_currentDay/$totalDays'),
                    ),
                    FilledButton(
                      onPressed: _endDay,
                      child: const Text('Kết thúc ngày'),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                ),
              ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: _plants.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _selectPlant(i),
                  child: PlantCard(
                    plant: _plants[i],
                    fontSize: fontSize,
                    isSelected: _selectedPlantIndex == i,
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: plantCareTools.map((tool) {
                    final isEnabled = _resources[tool.type]! > 0 && _selectedPlantIndex != null;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: isEnabled ? () => _applyTool(_plants[_selectedPlantIndex!], tool.type) : null,
                          icon: Icon(tool.icon, size: 32, color: isEnabled ? Colors.white : Colors.grey.shade600),
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
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Lớp PlantCard không thay đổi
class PlantCard extends StatelessWidget {
  final Plant plant;
  final double fontSize;
  final bool isSelected;

  const PlantCard({super.key, required this.plant, required this.fontSize, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: isSelected ? Border.all(color: Colors.yellow.shade600, width: 4) : null,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: plant.isCompleted ? const Color(0xFFE8F5E9) : (plant.health < unhealthyHealthThreshold ? const Color(0xFFFFF3E0) : Colors.white),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.asset(
                  plantImagePaths[plant.type]![plant.stage]!,
                  height: fontSize * 2,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                ),
                const SizedBox(height: 4),
                Text(
                  plant.speciesName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown),
                ),
                Text(
                  plantStageDescriptiveNames[plant.stage]!,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    _buildProgressBar('Nước', plant.waterLevel, Colors.blue),
                    _buildProgressBar('Ánh sáng', plant.lightLevel, Colors.orange),
                    _buildProgressBar('Dinh dưỡng', plant.nutrientLevel, Colors.green),
                    _buildProgressBar('Sức khỏe', plant.health, plant.health > 50 ? Colors.teal : Colors.redAccent),
                  ],
                ),
                if (plant.isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade400,
                      size: 36,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate(
      key: ValueKey('${plant.animationCounter}-${plant.animationTrigger}'),
      onComplete: (controller) {
        plant.animationTrigger = AnimationTrigger.idle;
      },
      effects: plant.animationTrigger == AnimationTrigger.healthy
          ? [
        ScaleEffect(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOut),
        ThenEffect(delay: 50.ms),
        ScaleEffect(end: const Offset(1, 1), duration: 250.ms, curve: Curves.easeIn),
      ]
          : plant.animationTrigger == AnimationTrigger.unhealthy
          ? [
        ShakeEffect(hz: 8, duration: 500.ms, curve: Curves.easeInOut),
        TintEffect(color: Colors.red, duration: 300.ms, end: 0.2),
      ]
          : [],
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text('$label:', style: const TextStyle(fontSize: 12))),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 100,
              color: color,
              backgroundColor: Colors.grey.shade300,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 40, child: Text('${value.toInt()}%', textAlign: TextAlign.right,)),
        ],
      ),
    );
  }
}