import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobileapp/game/core/game.dart';
import 'package:mobileapp/game/core/types.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'data/plant_care_data.dart'; // THÊM: Import file dữ liệu mới

// Enum để theo dõi trạng thái animation
enum AnimationTrigger { idle, correct, incorrect }

// SỬA: Chuyển các enum/class thành public (bỏ dấu `_`)
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
  // THÊM: const constructor
  const CareTool(this.label, this.icon, this.type, this.fixes, this.explanation);
}

class Plant {
  final String label;
  final PlantStage stage;
  final PlantIssue issue;
  double health;
  bool isCompleted;
  AnimationTrigger animationTrigger = AnimationTrigger.idle;
  int animationCounter = 0;

  Plant(this.label, this.stage, this.issue, this.health, this.isCompleted);
}

class PlantCarePlayScreen extends StatefulWidget {
  final Game game;
  final FinishCallback onFinish;

  const PlantCarePlayScreen({super.key, required this.game, required this.onFinish});

  @override
  State<PlantCarePlayScreen> createState() => _PlantCarePlayScreenState();
}

class _PlantCarePlayScreenState extends State<PlantCarePlayScreen> {
  final _rnd = Random();
  // XÓA: Danh sách _tools đã được chuyển ra file data
  // final _tools = const <CareTool>[...];

  final _plants = <Plant>[];
  late Map<CareToolType, int> _resources;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _completedRounds = 0;
  final int _totalRounds = 3;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.setLanguageCode('en');
    _newRound(isFirstTime: true);
  }

  void _playSound(String soundFile) {
    _audioPlayer.play(AssetSource('sfx/$soundFile'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _newRound({bool isFirstTime = false}) {
    _plants.clear();
    // SỬA: Sử dụng quy tắc game từ file data
    final stageToIssues = plantStageRules;

    final stages = PlantStage.values;
    for (int i = 0; i < 4; i++) {
      final stage = stages[_rnd.nextInt(stages.length)];
      final issues = stageToIssues[stage]!;
      final issue = issues[_rnd.nextInt(issues.length)];
      // SỬA: Sử dụng map tên từ file data
      _plants.add(Plant(plantStageCreativeNames[stage]!, stage, issue, 100.0, false));
    }

    if (isFirstTime) {
      _resources = {
        CareToolType.nuoc: 5 + widget.game.difficulty,
        CareToolType.phanBon: 3 + widget.game.difficulty,
        CareToolType.thuocTruSau: 2 + widget.game.difficulty,
        CareToolType.catTia: 2 + widget.game.difficulty,
        CareToolType.anhSang: 3 + widget.game.difficulty,
      };
    }

    setState(() {});
  }

  void _triggerSpecialEvent(Plant plant) {
    if (_rnd.nextDouble() > plant.stage.eventProbability) return;

    switch (plant.stage) {
      case PlantStage.hatGiong:
        _showWateringMiniGame(plant);
        break;
      case PlantStage.cayCon:
        _showBirdChaseEvent(plant);
        break;
      case PlantStage.truongThanh:
        _showPruningMiniGame(plant);
        break;
      case PlantStage.raHoa:
        _showFlowerProtectionEvent(plant);
        break;
    }
  }

  // ... (Nội dung các hàm mini-game và event giữ nguyên, chỉ cần sửa các tên private thành public) ...
  // Ví dụ: _Plant -> Plant, _CareToolType -> CareToolType
  void _showWateringMiniGame(Plant plant) {
    int taps = 0;
    const requiredTaps = 5;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Mini-Game: Tưới Nước Liên Tục'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nhấn nhanh để tưới đủ nước cho hạt giống!'),
              const SizedBox(height: 10),
              Text('Tiến độ: $taps/$requiredTaps'),
              LinearProgressIndicator(value: taps / requiredTaps, color: Colors.blue),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setStateDialog(() {
                  taps++;
                });
                if (taps >= requiredTaps) {
                  Navigator.pop(context);
                  setState(() {
                    plant.health = 100.0;
                    _correctAnswers += 10;
                    _resources[CareToolType.nuoc] = (_resources[CareToolType.nuoc]! - 1).clamp(0, 100);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tuyệt! Hạt giống được tưới đủ nước! (+10 điểm)'),
                      backgroundColor: Colors.green,
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                }
              },
              child: const Text('Tưới'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  plant.health -= 20;
                  _wrongAnswers++;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không tưới đủ nước! Hạt giống bị tổn thương.'),
                    backgroundColor: Colors.red,
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              },
              child: const Text('Hủy'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBirdChaseEvent(Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sự Kiện: Xua Đuổi Chim'),
        content: const Text('Cây con bị chim tấn công! Chọn công cụ để xua đuổi.'),
        actions: plantCareTools.map((tool) => TextButton( // SỬA: dùng plantCareTools
          onPressed: () {
            Navigator.pop(context);
            if (tool.type == CareToolType.thuocTruSau && _resources[tool.type]! > 0) {
              setState(() {
                plant.health = 100.0;
                _correctAnswers += 15;
                _resources[tool.type] = (_resources[tool.type]! - 1).clamp(0, 100);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tuyệt! Cây con được bảo vệ! (+15 điểm)'),
                  backgroundColor: Colors.green,
                  duration: Duration(milliseconds: 1500),
                ),
              );
            } else {
              setState(() {
                plant.health -= 20;
                _wrongAnswers++;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sai công cụ! Cây con bị tổn thương.'),
                  backgroundColor: Colors.red,
                  duration: Duration(milliseconds: 1500),
                ),
              );
            }
          },
          child: Text(tool.label),
        )).toList(),
      ),
    );
  }

  void _showPruningMiniGame(Plant plant) {
    final correctBranch = _rnd.nextInt(3);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mini-Game: Tỉa Cành'),
        content: const Text('Chọn nhánh cần tỉa để cây phát triển tốt hơn.'),
        actions: List.generate(
          3,
              (index) => TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (index == correctBranch && _resources[CareToolType.catTia]! > 0) {
                setState(() {
                  plant.health = 100.0;
                  _correctAnswers += 20;
                  _resources[CareToolType.catTia] = (_resources[CareToolType.catTia]! - 1).clamp(0, 100);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tỉa đúng nhánh! Cây khỏe mạnh! (+20 điểm)'),
                    backgroundColor: Colors.green,
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              } else {
                setState(() {
                  plant.health -= 20;
                  _wrongAnswers++;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tỉa sai nhánh! Cây bị tổn thương.'),
                    backgroundColor: Colors.red,
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              }
            },
            child: Text('Nhánh ${index + 1}'),
          ),
        ),
      ),
    );
  }

  void _showFlowerProtectionEvent(Plant plant) {
    int taps = 0;
    const requiredTaps = 3;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Sự Kiện: Bảo Vệ Hoa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nhấn nhanh để đuổi côn trùng khỏi hoa!'),
              const SizedBox(height: 10),
              Text('Tiến độ: $taps/$requiredTaps'),
              LinearProgressIndicator(value: taps / requiredTaps, color: Colors.blue),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setStateDialog(() {
                  taps++;
                });
                if (taps >= requiredTaps) {
                  Navigator.pop(context);
                  setState(() {
                    plant.health = 100.0;
                    _correctAnswers += 30;
                    _resources[CareToolType.thuocTruSau] = (_resources[CareToolType.thuocTruSau]! - 1).clamp(0, 100);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tuyệt! Hoa được bảo vệ! (+30 điểm)'),
                      backgroundColor: Colors.green,
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                }
              },
              child: const Text('Đuổi Côn Trùng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  plant.health -= 20;
                  _wrongAnswers++;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không bảo vệ được hoa! Hoa bị tổn thương.'),
                    backgroundColor: Colors.red,
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              },
              child: const Text('Hủy'),
            ),
          ],
        ),
      ),
    );
  }


  void _onCorrectAnswer(CareTool correctTool, CareToolType selectedTool) {
    _correctAnswers++;
    _resources[selectedTool] = (_resources[selectedTool]! - 1).clamp(0, 100);

    if (_plants.isEmpty) return;
    final currentPlant = _plants.firstWhere((p) => !p.isCompleted, orElse: () => _plants[0]);
    _triggerSpecialEvent(currentPlant);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correctTool.explanation),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(milliseconds: 1500),
      ),
    );

    if (_plants.every((p) => p.isCompleted)) {
      _completedRounds++;
      if (_completedRounds >= _totalRounds) {
        widget.onFinish(_correctAnswers, _wrongAnswers);
      } else {
        _showRoundSummary();
      }
    }
  }

  void _checkAnswer(Plant plant, CareToolType selectedTool) {
    if (plant.isCompleted) return;

    final correctTool = plantCareTools.firstWhere((t) => t.fixes == plant.issue);
    bool hasResources = _resources[selectedTool]! > 0;

    if (hasResources && selectedTool == correctTool.type) {
      _playSound('correct.mp3');
      setState(() {
        plant.health = 100.0;
        plant.isCompleted = true;
        plant.animationTrigger = AnimationTrigger.correct;
        plant.animationCounter++;
        _onCorrectAnswer(correctTool, selectedTool);
      });
    } else {
      _playSound('incorrect.mp3');
      setState(() {
        _wrongAnswers++;
        plant.health = (plant.health - 34).clamp(0, 100);
        plant.animationTrigger = AnimationTrigger.incorrect;
        plant.animationCounter++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasResources ? 'Sai rồi! Cây không cần thứ này.' : 'Đã hết tài nguyên này!'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  // XÓA: Toàn bộ các hàm _stageToPlantName và _issueLabel

  void _showRoundSummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hoàn thành vòng $_completedRounds!'),
        content: const Text('Bạn đã chăm sóc thành công cả 4 cây. Hãy tiếp tục vòng tiếp theo nhé!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _newRound();
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
            children: plantCareTools // SỬA: Dùng plantCareTools
                .map(
                  (tool) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                // SỬA: Dùng map plantIssueLabels
                child: Text('• Khi cây "${plantIssueLabels[tool.fixes]}", hãy dùng "${tool.label}".'),
              ),
            )
                .toList(),
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
                  children: plantCareTools.map((tool) { // SỬA: Dùng plantCareTools
                    final bool hasResources = _resources[tool.type]! > 0;
                    return Draggable<CareToolType>(
                      data: tool.type,
                      feedback: Material(
                        elevation: 6,
                        color: Colors.transparent,
                        child: Icon(
                          tool.icon,
                          color: Colors.white,
                          size: 52,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 5.0,
                            )
                          ],
                        ),
                      ),
                      child: ToolWidget(tool: tool, count: _resources[tool.type]!),
                      childWhenDragging: ToolWidget(tool: tool, count: _resources[tool.type]!, isDragging: true),
                      onDragStarted: () {
                        if (!hasResources) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã hết ${tool.label}!'),
                              backgroundColor: Colors.orange,
                              duration: const Duration(milliseconds: 1000),
                            ),
                          );
                        }
                      },
                      dragAnchorStrategy: (draggable, context, position) {
                        if (!hasResources) {
                          return const Offset(0,0);
                        }
                        return pointerDragAnchorStrategy(draggable, context, position);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            Chip(
              backgroundColor: Colors.white.withOpacity(0.8),
              avatar: const Icon(Icons.star),
              label: Text('Vòng: ${_completedRounds + 1}/$_totalRounds'),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: _plants.length,
                itemBuilder: (_, i) => PlantCard(
                  plant: _plants[i],
                  onToolDropped: (plant, toolType) {
                    _playSound('drop.mp3');
                    _checkAnswer(plant, toolType);
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton(
                  onPressed: () => widget.onFinish(_correctAnswers, _wrongAnswers),
                  child: const Text('Kết thúc lượt chơi'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToolWidget extends StatelessWidget {
  const ToolWidget({
    super.key,
    required this.tool,
    required this.count,
    this.isDragging = false,
  });

  final CareTool tool;
  final int count;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDragging ? 0.3 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tool.icon, size: 32, color: count > 0 ? Colors.white : Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, color: count > 0 ? Colors.white : Colors.grey.shade600, shadows: [
                Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.5))
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class PlantCard extends StatelessWidget {
  final Plant plant;
  final Function(Plant, CareToolType) onToolDropped;

  const PlantCard({super.key, required this.plant, required this.onToolDropped});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = screenHeight * 0.05;
    final isSick = plant.health < 100 && !plant.isCompleted;

    return DragTarget<CareToolType>(
      builder: (context, candidateData, rejectedData) {
        final isBeingTargeted = candidateData.isNotEmpty;

        return Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isBeingTargeted ? 0.4 : 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  )
                ]
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isBeingTargeted ? Colors.yellow.shade600 : Colors.transparent,
                  width: 4,
                ),
              ),
              color: plant.isCompleted
                  ? const Color(0xFFE8F5E9)
                  : (isSick ? const Color(0xFFFFF3E0) : Colors.white),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Image.asset(
                        plantImagePaths[plant.stage]!, // SỬA
                        height: fontSize * 1.8,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error, color: Colors.red),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          plant.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Text(
                        plantStageDescriptiveNames[plant.stage]!, // SỬA
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      if (!plant.isCompleted)
                        Column(
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: plant.health / 100, end: plant.health / 100),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, value, child) => LinearProgressIndicator(
                                value: value,
                                color: plant.health > 50 ? Colors.green : Colors.orange,
                                backgroundColor: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plantIssueLabels[plant.issue]!, // SỬA
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade400,
                          size: 36,
                        ),
                    ],
                  ),
                ),
              ),
            )
        ).animate(
          key: ValueKey('${plant.animationCounter}-${plant.animationTrigger}'),
          onComplete: (controller) {
            plant.animationTrigger = AnimationTrigger.idle;
          },
          effects: plant.animationTrigger == AnimationTrigger.correct
              ? [
            ScaleEffect(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOut),
            ThenEffect(delay: 50.ms),
            ScaleEffect(end: const Offset(1,1), duration: 250.ms, curve: Curves.easeIn),
            ShakeEffect(hz: 4, duration: 400.ms, rotation: 0.05),
          ]
              : plant.animationTrigger == AnimationTrigger.incorrect
              ? [
            ShakeEffect(hz: 8, duration: 500.ms, curve: Curves.easeInOut),
            TintEffect(color: Colors.red, duration: 300.ms, end: 0.2),
          ]
              : [],
        );
      },
      onWillAcceptWithDetails: (details) {
        return !plant.isCompleted;
      },
      onAccept: (receivedToolType) {
        onToolDropped(plant, receivedToolType);
      },
    );
  }
}