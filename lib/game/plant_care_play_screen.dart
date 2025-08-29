import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'game.dart';
import 'types.dart';

enum _PlantStage {
  hatGiong(0.4),
  cayCon(0.3),
  truongThanh(0.25),
  raHoa(0.2);

  final double eventProbability;
  const _PlantStage(this.eventProbability);
}

enum _PlantIssue { datKho, thieuAnhSang, sauBenh, quaTai, thieuChatDinhDuong }
enum _CareToolType { nuoc, anhSang, thuocTruSau, catTia, phanBon }

class _CareTool {
  final String label;
  final IconData icon;
  final _CareToolType type;
  final _PlantIssue fixes;
  final String explanation;
  const _CareTool(this.label, this.icon, this.type, this.fixes, this.explanation);
}

class _Plant {
  final String label;
  final _PlantStage stage;
  final _PlantIssue issue;
  double health;
  bool isCompleted;
  _Plant(this.label, this.stage, this.issue, this.health, this.isCompleted);
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
  final _tools = const <_CareTool>[
    _CareTool('Tưới Nước', Icons.water_drop, _CareToolType.nuoc, _PlantIssue.datKho, 'Chính xác! Nước rất cần thiết cho cây.'),
    _CareTool('Thêm Sáng', Icons.light_mode, _CareToolType.anhSang, _PlantIssue.thieuAnhSang, 'Đúng rồi! Ánh sáng cung cấp năng lượng cho cây.'),
    _CareTool('Bắt Sâu', Icons.bug_report, _CareToolType.thuocTruSau, _PlantIssue.sauBenh, 'Tuyệt vời! Cây đã được bảo vệ khỏi sâu bệnh.'),
    _CareTool('Tỉa Cành', Icons.cut, _CareToolType.catTia, _PlantIssue.quaTai, 'Chính xác! Tỉa cành giúp cây tập trung dinh dưỡng.'),
    _CareTool('Bón Phân', Icons.eco, _CareToolType.phanBon, _PlantIssue.thieuChatDinhDuong, 'Rất tốt! Phân bón cung cấp thêm dinh dưỡng cho cây.'),
  ];

  final _plants = <_Plant>[];
  late Map<_CareToolType, int> _resources;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _completedRounds = 0;
  final int _totalRounds = 3;

  @override
  void initState() {
    super.initState();
    // Set Firebase locale to suppress X-Firebase-Locale warning
    FirebaseAuth.instance.setLanguageCode('en');
    _newRound(isFirstTime: true);
  }

  void _newRound({bool isFirstTime = false}) {
    _plants.clear();
    final stageToIssues = {
      _PlantStage.hatGiong: [_PlantIssue.datKho, _PlantIssue.thieuAnhSang],
      _PlantStage.cayCon: [_PlantIssue.datKho, _PlantIssue.thieuAnhSang, _PlantIssue.sauBenh],
      _PlantStage.truongThanh: [_PlantIssue.quaTai, _PlantIssue.thieuChatDinhDuong, _PlantIssue.sauBenh],
      _PlantStage.raHoa: [_PlantIssue.sauBenh, _PlantIssue.quaTai, _PlantIssue.datKho],
    };

    final stages = _PlantStage.values;
    for (int i = 0; i < 4; i++) {
      final stage = stages[_rnd.nextInt(stages.length)];
      final issues = stageToIssues[stage]!;
      final issue = issues[_rnd.nextInt(issues.length)];
      _plants.add(_Plant(_stageToPlantName(stage), stage, issue, 100.0, false));
    }

    if (isFirstTime) {
      _resources = {
        _CareToolType.nuoc: 5 + widget.game.difficulty,
        _CareToolType.phanBon: 3 + widget.game.difficulty,
        _CareToolType.thuocTruSau: 2 + widget.game.difficulty,
        _CareToolType.catTia: 2 + widget.game.difficulty,
        _CareToolType.anhSang: 3 + widget.game.difficulty,
      };
    }

    setState(() {});
  }

  void _triggerSpecialEvent(_Plant plant) {
    if (_rnd.nextDouble() > plant.stage.eventProbability) return;

    switch (plant.stage) {
      case _PlantStage.hatGiong:
        _showWateringMiniGame(plant);
        break;
      case _PlantStage.cayCon:
        _showBirdChaseEvent(plant);
        break;
      case _PlantStage.truongThanh:
        _showPruningMiniGame(plant);
        break;
      case _PlantStage.raHoa:
        _showFlowerProtectionEvent(plant);
        break;
    }
  }

  void _showWateringMiniGame(_Plant plant) {
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
                    _resources[_CareToolType.nuoc] = (_resources[_CareToolType.nuoc]! - 1).clamp(0, 100);
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

  void _showBirdChaseEvent(_Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sự Kiện: Xua Đuổi Chim'),
        content: const Text('Cây con bị chim tấn công! Chọn công cụ để xua đuổi.'),
        actions: _tools.map((tool) => TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (tool.type == _CareToolType.thuocTruSau && _resources[tool.type]! > 0) {
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

  void _showPruningMiniGame(_Plant plant) {
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
              if (index == correctBranch && _resources[_CareToolType.catTia]! > 0) {
                setState(() {
                  plant.health = 100.0;
                  _correctAnswers += 20;
                  _resources[_CareToolType.catTia] = (_resources[_CareToolType.catTia]! - 1).clamp(0, 100);
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

  void _showFlowerProtectionEvent(_Plant plant) {
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
                    _resources[_CareToolType.thuocTruSau] = (_resources[_CareToolType.thuocTruSau]! - 1).clamp(0, 100);
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

  void _onCorrectAnswer(_CareTool correctTool, _CareToolType selectedTool) {
    _correctAnswers++;
    _resources[selectedTool] = (_resources[selectedTool]! - 1).clamp(0, 100);

    if (_plants.isEmpty) return;
    final currentPlant = _plants.firstWhere((p) => !p.isCompleted, orElse: () => _plants[0]);
    _triggerSpecialEvent(currentPlant);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correctTool.explanation),
        backgroundColor: Colors.green,
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

  void _checkAnswer(_Plant plant, _CareToolType selectedTool) {
    if (plant.isCompleted) return;

    final correctTool = _tools.firstWhere((t) => t.fixes == plant.issue);
    bool hasResources = _resources[selectedTool]! > 0;

    if (hasResources && selectedTool == correctTool.type) {
      setState(() {
        plant.health = 100.0;
        plant.isCompleted = true;
        _onCorrectAnswer(correctTool, selectedTool);
      });
    } else {
      setState(() {
        _wrongAnswers++;
        plant.health = (plant.health - 34).clamp(0, 100);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasResources ? 'Sai rồi! Cây không cần thứ này.' : 'Đã hết tài nguyên này!'),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  String _stageToPlantName(_PlantStage s) => switch (s) {
    _PlantStage.hatGiong => 'Mầm Xinh',
    _PlantStage.cayCon => 'Chồi Non',
    _PlantStage.truongThanh => 'Cây Trưởng Thành',
    _PlantStage.raHoa => 'Cây Sắp Nở Hoa',
  };

  String _issueLabel(_PlantIssue i) => switch (i) {
    _PlantIssue.datKho => 'Đất bị khô',
    _PlantIssue.thieuAnhSang => 'Thiếu nắng',
    _PlantIssue.sauBenh => 'Có sâu bệnh',
    _PlantIssue.quaTai => 'Cành lá um tùm',
    _PlantIssue.thieuChatDinhDuong => 'Thiếu dinh dưỡng',
  };

  void _showRoundSummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hoàn thành vòng ${_completedRounds}!'),
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

  void _showCareOptions(_Plant plant) {
    final correctTool = _tools.firstWhere((t) => t.fixes == plant.issue);
    final otherTools = _tools.where((t) => t.type != correctTool.type).toList()..shuffle(_rnd);
    final options = [correctTool, ...otherTools.take(2)]..shuffle(_rnd);

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cây "${plant.label}" đang ${_issueLabel(plant.issue).toLowerCase()}. Bạn sẽ làm gì?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...options.map(
                  (tool) => ElevatedButton.icon(
                icon: Icon(tool.icon),
                label: Text('${tool.label} (còn ${_resources[tool.type]})'),
                onPressed: _resources[tool.type]! > 0 && !plant.isCompleted
                    ? () {
                  Navigator.pop(context);
                  _checkAnswer(plant, tool.type);
                }
                    : null,
              ),
            ),
          ],
        ),
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
            children: _tools
                .map(
                  (tool) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('• Khi cây "${_issueLabel(tool.fixes)}", hãy dùng "${tool.label}".'),
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
      appBar: AppBar(
        title: const Text('Vườn Cây Vui Vẻ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Sổ tay',
            onPressed: _showHandbook,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _resources.entries
                  .map((e) {
                final tool = _tools.firstWhere((t) => t.type == e.key);
                return Chip(avatar: Icon(tool.icon), label: Text('${e.value}'));
              })
                  .toList()
                ..add(
                  Chip(
                    avatar: const Icon(Icons.star),
                    label: Text('Vòng: ${_completedRounds + 1}/$_totalRounds'),
                  ),
                ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _plants.length,
                itemBuilder: (_, i) => _PlantCard(
                  plant: _plants[i],
                  onTap: _showCareOptions,
                  issueLabel: _issueLabel,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton(
              onPressed: () => widget.onFinish(_correctAnswers, _wrongAnswers),
              child: const Text('Kết thúc lượt chơi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final _Plant plant;
  final Function(_Plant) onTap;
  final String Function(_PlantIssue) issueLabel;

  const _PlantCard({required this.plant, required this.onTap, required this.issueLabel});

  String _getPlantImage(_PlantStage stage) {
    return switch (stage) {
      _PlantStage.hatGiong => '🌱',
      _PlantStage.cayCon => '🌿',
      _PlantStage.truongThanh => '🌳',
      _PlantStage.raHoa => '🌸',
    };
  }

  String _getStageName(_PlantStage stage) {
    return switch (stage) {
      _PlantStage.hatGiong => 'Hạt giống',
      _PlantStage.cayCon => 'Cây con',
      _PlantStage.truongThanh => 'Trưởng thành',
      _PlantStage.raHoa => 'Ra hoa',
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = screenHeight * 0.05; // Dynamic font size
    final isSick = plant.health < 100 && !plant.isCompleted;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: plant.isCompleted
          ? Colors.green.shade50
          : (isSick ? Colors.brown.shade100 : Colors.white),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: plant.isCompleted ? null : () => onTap(plant),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(_getPlantImage(plant.stage), style: TextStyle(fontSize: fontSize)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    plant.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _getStageName(plant.stage),
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                if (!plant.isCompleted)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: plant.health / 100,
                        color: plant.health > 50 ? Colors.green : Colors.orange,
                        backgroundColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issueLabel(plant.issue),
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
      ),
    );
  }
}