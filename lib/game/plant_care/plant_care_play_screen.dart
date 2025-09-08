import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobileapp/game/core/game.dart';
import 'package:mobileapp/game/core/types.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:audioplayers/audioplayers.dart'; // ĐÃ XÓA
import 'data/plant_care_data.dart';

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

// MODIFIED: Plant class now includes type and species name
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
  final _rnd = Random();
  final _plants = <Plant>[];
  late Map<CareToolType, int> _resources;
  int correctActions = 0;
  int wrongActions = 0;
  int _currentDay = 1;
  final int _totalDays = 3;
  // final AudioPlayer _audioPlayer = AudioPlayer(); // ĐÃ XÓA
  int? _selectedPlantIndex;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.setLanguageCode('en');
    _initializeGame();
  }

  // void _playSound(String soundFile) { // ĐÃ XÓA
  //   _audioPlayer.play(AssetSource('sfx/$soundFile'));
  // }

  @override
  void dispose() {
    // _audioPlayer.dispose(); // ĐÃ XÓA
    super.dispose();
  }

  // MODIFIED: Initialize a diverse garden of plants
  void _initializeGame() {
    _plants.clear();
    final stages = PlantStage.values;
    // Create a list of different plant types to spawn
    final plantTypesToSpawn = [PlantType.normal, PlantType.cactus, PlantType.fern, PlantType.normal];
    plantTypesToSpawn.shuffle(_rnd); // Randomize plant positions

    for (final type in plantTypesToSpawn) {
      final species = plantSpeciesData[type]!;
      final stage = stages[0];
      _plants.add(Plant(
        type: type,
        speciesName: species.name,
        label: plantStageCreativeNames[stage]!,
        stage: stage,
        waterLevel: 50.0,
        lightLevel: 50.0,
        nutrientLevel: 50.0,
        health: 100.0,
        isCompleted: false,
      ));
    }

    _resources = {
      CareToolType.nuoc: 20 + widget.game.difficulty * 2,
      CareToolType.anhSang: 15 + widget.game.difficulty,
      CareToolType.phanBon: 12 + widget.game.difficulty,
      CareToolType.thuocTruSau: 10 + widget.game.difficulty,
      CareToolType.catTia: 10 + widget.game.difficulty,
    };
    _selectedPlantIndex = null;
    setState(() {});
  }

  void _selectPlant(int index) {
    setState(() {
      _selectedPlantIndex = index;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chọn cây "${_plants[index].speciesName}"!'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _triggerRandomEvent(Plant plant) {
    if (_rnd.nextDouble() > plant.stage.eventProbability) return;

    final possibleIssues = plantStageRules[plant.stage];
    if (possibleIssues == null || possibleIssues.isEmpty) return;

    final issue = possibleIssues[_rnd.nextInt(possibleIssues.length)];

    _showPlantIssueEvent(plant, issue);
  }

  void _showPlantIssueEvent(Plant plant, PlantIssue issue) {
    final issueLabel = plantIssueLabels[issue] ?? "Vấn đề không xác định";
    final correctTool = plantCareTools.firstWhere((tool) => tool.fixes == issue);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Sự kiện: $issueLabel'),
        content: Text('Cây ${plant.speciesName} đang gặp vấn đề "$issueLabel". Chọn công cụ phù hợp để cứu cây. (Gợi ý: ${correctTool.label})'),
        actions: plantCareTools.map((tool) => TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (tool.type == correctTool.type && _resources[tool.type]! > 0) {
              setState(() {
                plant.health = (plant.health + 20).clamp(0, 100);
                correctActions += 5;
                _resources[tool.type] = (_resources[tool.type]! - 1).clamp(0, 100);
              });
              // _playSound('correct.mp3'); // ĐÃ XÓA
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tuyệt vời! Cây đã được cứu khỏi $issueLabel! (+5 điểm)'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              setState(() {
                plant.health = (plant.health - 20).clamp(0, 100);
                wrongActions++;
              });
              // _playSound('incorrect.mp3'); // ĐÃ XÓA
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sai công cụ! Cây bị ảnh hưởng bởi $issueLabel.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text(tool.label),
        )).toList(),
      ),
    );
  }

  // MODIFIED: Apply tool logic now considers the plant's species
  void _applyTool(Plant plant, CareToolType toolType) {
    if (_resources[toolType]! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hết ${plantCareTools.firstWhere((t) => t.type == toolType).label}!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final tool = plantCareTools.firstWhere((t) => t.type == toolType);
    final species = plantSpeciesData[plant.type]!;

    setState(() {
      _resources[toolType] = (_resources[toolType]! - 1).clamp(0, 100);

      // Handle special cases for different species
      switch (toolType) {
        case CareToolType.nuoc:
          if (plant.waterLevel > species.waterTolerance) {
            plant.health = (plant.health - 30).clamp(0, 100);
            wrongActions++;
            // _playSound('incorrect.mp3'); // ĐÃ XÓA
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${species.name} không ưa nhiều nước! Cây bị úng nước.'),
              backgroundColor: Colors.red,
            ));
            return; // Exit without adding more water
          }
          plant.waterLevel = (plant.waterLevel + 30).clamp(0, 100);
          break;
        case CareToolType.anhSang:
          if (plant.lightLevel > species.lightTolerance) {
            plant.health = (plant.health - 30).clamp(0, 100);
            wrongActions++;
            // _playSound('incorrect.mp3'); // ĐÃ XÓA
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${species.name} không thích nắng gắt! Cây bị cháy nắng.'),
              backgroundColor: Colors.red,
            ));
            return; // Exit without adding more light
          }
          plant.lightLevel = (plant.lightLevel + 30).clamp(0, 100);
          break;
        case CareToolType.phanBon:
          plant.nutrientLevel = (plant.nutrientLevel + 30).clamp(0, 100);
          break;
        case CareToolType.thuocTruSau:
          plant.health = (plant.health + 20).clamp(0, 100);
          break;
        case CareToolType.catTia:
          if (plant.stage == PlantStage.truongThanh || plant.stage == PlantStage.raHoa) {
            plant.health = (plant.health + 20).clamp(0, 100);
          } else {
            plant.health = (plant.health - 20).clamp(0, 100);
            wrongActions++;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tỉa cành không phù hợp với ${plantStageDescriptiveNames[plant.stage]}!'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          break;
      }

      plant.health = ((plant.waterLevel + plant.lightLevel + plant.nutrientLevel) / 3).clamp(0, 100);
      correctActions++;
      // _playSound('correct.mp3'); // ĐÃ XÓA
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã sử dụng ${tool.label} cho ${plant.speciesName}! ${tool.explanation}'),
          backgroundColor: Colors.green,
        ),
      );

      if (plant.health >= 80 && plant.stage != PlantStage.raHoa) {
        plant.stage = PlantStage.values[plant.stage.index + 1];
        plant.label = plantStageCreativeNames[plant.stage]!;
        plant.animationTrigger = AnimationTrigger.healthy;
        plant.animationCounter++;
      } else if (plant.health < 30) {
        plant.animationTrigger = AnimationTrigger.unhealthy;
        plant.animationCounter++;
      }
    });

    _triggerRandomEvent(plant);
  }

  // MODIFIED: Resource decay at the end of the day is now based on species needs
  void _endDay() {
    setState(() {
      for (int i = 0; i < _plants.length; i++) {
        var plant = _plants[i];
        final species = plantSpeciesData[plant.type]!;

        if (!plant.isCompleted) {
          // Apply species-specific needs multipliers
          plant.waterLevel = (plant.waterLevel - (20 * species.waterNeed)).clamp(0, 100);
          plant.lightLevel = (plant.lightLevel - (20 * species.lightNeed)).clamp(0, 100);
          plant.nutrientLevel = (plant.nutrientLevel - 15).clamp(0, 100); // Nutrient need is same for all for now

          plant.health = ((plant.waterLevel + plant.lightLevel + plant.nutrientLevel) / 3).clamp(0, 100);

          if (plant.health >= 80 && plant.stage != PlantStage.raHoa) {
            plant.stage = PlantStage.values[plant.stage.index + 1];
            plant.label = plantStageCreativeNames[plant.stage]!;
            plant.animationTrigger = AnimationTrigger.healthy;
            plant.animationCounter++;
          } else if (plant.health < 30) {
            plant.animationTrigger = AnimationTrigger.unhealthy;
            plant.animationCounter++;
          }
          if (plant.stage == PlantStage.raHoa && plant.health >= 80) {
            plant.isCompleted = true;
          }
        }
      }
      _currentDay++;
      _selectedPlantIndex = null;
      if (_currentDay > _totalDays) {
        widget.onFinish(correctActions, wrongActions);
      } else {
        _showDaySummary();
      }
    });
  }

  void _showDaySummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kết thúc ngày ${_currentDay -1}'),
        content: Text('Bắt đầu ngày mới! Tiếp tục chăm sóc để cây ra hoa!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  void _showHandbook() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sổ Tay Chăm Sóc'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hướng dẫn chăm sóc cây:'),
              ...plantCareTools.map(
                    (tool) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('• ${tool.label}: ${tool.explanation}'),
                ),
              ),
              const Text('\nLưu ý đặc biệt:'),
              const Text('• Xương rồng cần nhiều sáng, không ưa nhiều nước.'),
              const Text('• Dương xỉ cần nhiều nước, không thích nắng gắt.'),
              const Text('\nLưu ý chung:'),
              const Text('• Giữ nước, ánh sáng, dinh dưỡng trên 50 để cây khỏe.'),
              const Text('• Cây đạt sức khỏe 80 sẽ phát triển lên giai đoạn tiếp theo.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = screenHeight * 0.04;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showHandbook,
        tooltip: 'Sổ tay',
        child: const Icon(Icons.menu_book),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/garden_background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: plantCareTools.map((tool) {
                    return Column(
                      children: [
                        IconButton(
                          onPressed: _resources[tool.type]! > 0 && _selectedPlantIndex != null
                              ? () {
                            setState(() {
                              _applyTool(_plants[_selectedPlantIndex!], tool.type);
                            });
                          }
                              : null,
                          icon: Icon(tool.icon, size: 32, color: _resources[tool.type]! > 0 ? Colors.white : Colors.grey.shade600),
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
            Chip(
              backgroundColor: Colors.white.withOpacity(0.8),
              avatar: const Icon(Icons.star),
              label: Text('Ngày: $_currentDay/$_totalDays'),
            ),
            if (_selectedPlantIndex != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Đang chăm sóc: ${_plants[_selectedPlantIndex!].speciesName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
                padding: const EdgeInsets.all(8.0),
                child: FilledButton(
                  onPressed: _endDay,
                  child: const Text('Kết thúc ngày'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MODIFIED: PlantCard now displays the species name
class PlantCard extends StatelessWidget {
  final Plant plant;
  final double fontSize;
  final bool isSelected;

  const PlantCard({super.key, required this.plant, required this.fontSize, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isHealthy = plant.health >= 80;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
        border: isSelected ? Border.all(color: Colors.yellow, width: 4) : null,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isHealthy ? Colors.green.shade400 : Colors.transparent, width: 4),
        ),
        color: plant.isCompleted ? const Color(0xFFE8F5E9) : (plant.health < 30 ? const Color(0xFFFFF3E0) : Colors.white),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.asset(
                  plantImagePaths[plant.stage]!,
                  height: fontSize * 2,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                ),
                const SizedBox(height: 4),
                // Display Species Name
                Text(
                  plant.speciesName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown),
                ),
                Text(
                  plantStageDescriptiveNames[plant.stage]!,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade400,
                    size: 36,
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
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontSize: 12))),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 100,
              color: color,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 8),
          Text('${value.toInt()}%'),
        ],
      ),
    );
  }
}