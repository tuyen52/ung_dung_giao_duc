import 'dart:convert';
import 'package:flutter/material.dart';

// Độ khó hệ thống
import 'package:mobileapp/game/core/types.dart' show GameDifficulty;

// Lõi & màn chơi
import 'core/plant_core.dart';
import 'plant_care_play_screen.dart';

// Dịch vụ hệ thống
import 'package:mobileapp/services/game_progress_service.dart';
import 'package:mobileapp/services/game_session_service.dart';
import 'package:mobileapp/game/core/game_progress.dart';

// Wrapper của bạn
import 'package:mobileapp/game/widgets/game_screen_wrapper.dart';

// Kết quả tổng hệ thống
import 'package:mobileapp/screens/game_result_screen.dart';

const String _kPlantCareGameId = 'plant_care';

DifficultyLevel _mapGameDifficulty(GameDifficulty d) {
  switch (d) {
    case GameDifficulty.easy:
      return DifficultyLevel.easy;
    case GameDifficulty.medium:
      return DifficultyLevel.normal;
    case GameDifficulty.hard:
      return DifficultyLevel.hard;
  }
}

int _difficultyToInt(DifficultyLevel d) {
  if (d == DifficultyLevel.easy) return 1;
  if (d == DifficultyLevel.hard) return 3;
  return 2; // normal
}

String _encodeState(Map<String, dynamic> m) => json.encode(m);
Map<String, dynamic>? _decodeState(String s) {
  try {
    return json.decode(s) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

class PlantCareGameLauncher extends StatefulWidget {
  final String treId;
  final String treName;
  final GameDifficulty difficulty;
  final int totalDays;
  final int dayLengthSec;

  const PlantCareGameLauncher({
    super.key,
    required this.treId,
    required this.treName,
    required this.difficulty,
    this.totalDays = 5,
    this.dayLengthSec = 90,
  });

  @override
  State<PlantCareGameLauncher> createState() => _PlantCareGameLauncherState();
}

class _PlantCareGameLauncherState extends State<PlantCareGameLauncher> {
  final _progress = GameProgressService();
  final GlobalKey _playKey = GlobalKey();

  bool _loading = true;
  GameProgress? _gp;
  Map<String, dynamic>? _initialStateMap;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    _gp = await _progress.load(widget.treId, _kPlantCareGameId);
    if (_gp != null && _gp!.deck.isNotEmpty) {
      _initialStateMap = _decodeState(_gp!.deck.first);
    }
    setState(() => _loading = false);
  }

  Future<void> _saveSnapshot({
    required Map<String, dynamic> state,
    required int dayIndex,
    required int timeLeftSec,
    int stars = 0,
  }) async {
    final diffInt =
        _gp?.difficulty ?? _difficultyToInt(_mapGameDifficulty(widget.difficulty));
    final gp = GameProgress(
      treId: widget.treId,
      gameId: _kPlantCareGameId,
      difficulty: diffInt,
      deck: <String>[_encodeState(state)], // lưu state JSON
      index: dayIndex,
      correct: stars, // tổng sao tham khảo
      wrong: 0,
      timeLeft: timeLeftSec,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _progress.save(gp);
  }

  Future<void> _clearProgress() async {
    await _progress.clear(widget.treId, _kPlantCareGameId);
  }

  int _computeScore(int correct, int wrong) {
    // Nếu game khác dùng công thức khác, copy đúng công thức đó vào đây.
    final score = correct * 20 - wrong * 10;
    return score < 0 ? 0 : score;
  }

  Future<void> _finishAndShowResult(int correct, int wrong) async {
    // Lưu phiên & thưởng giống hệ thống chung
    await GameSessionService().saveAndReward(
      treId: widget.treId,
      gameId: _kPlantCareGameId,
      gameName: 'Chăm Sóc Cây Trồng', // ✅ THÊM THAM SỐ BẮT BUỘC
      difficulty: (_gp?.difficulty ??
          _difficultyToInt(_mapGameDifficulty(widget.difficulty)))
          .toString(),
      correct: correct,
      wrong: wrong,
    );

    final score = _computeScore(correct, wrong);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          treId: widget.treId,
          treName: widget.treName,
          correct: correct,
          wrong: wrong,
          score: score,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return GameScreenWrapper(
      gameName: 'Chăm sóc cây',
      handbookContent: const _PlantHelpSheet(),
      showHandbookOnStart: false,

      // Gọi public method của PlayScreen qua key (đúng khung của bạn)
      onFinishAndExit: () => (_playKey.currentState as dynamic?)?.finishGame(),
      onSaveAndExit: () => (_playKey.currentState as dynamic?)?.outToHome(),

      builder: (context, bool isPaused) {
        return PlantCarePlayScreen(
          key: _playKey,
          isPaused: isPaused,
          difficulty: _mapGameDifficulty(widget.difficulty),
          totalDays: widget.totalDays,
          dayLengthSec: widget.dayLengthSec,
          initialStateMap: _initialStateMap,

          // Khi người chơi KẾT THÚC (hoặc game kết thúc tự nhiên)
          onFinish: (int correct, int wrong) =>
              WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _finishAndShowResult(correct, wrong)),

          // Lưu tiến độ (hết ngày hoặc Save & Exit)
          onSaveProgress: ({
            required Map<String, dynamic> state,
            required int dayIndex,
            required int stars,
            required int timeLeftSec,
          }) =>
              _saveSnapshot(
                state: state,
                dayIndex: dayIndex,
                stars: stars,
                timeLeftSec: timeLeftSec,
              ),

          // Xoá tiến độ khi hoàn tất ván
          onClearProgress: _clearProgress,
        );
      },
    );
  }
}

class _PlantHelpSheet extends StatelessWidget {
  const _PlantHelpSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Hướng dẫn chơi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text(
              '• Giữ 4 chỉ số Nước – Ánh sáng – Dinh dưỡng – Sạch/Bảo vệ trong vùng vàng.\n'
                  '• Mỗi ngày ~1–2 phút. Mở menu/hướng dẫn thì thời gian đứng lại.\n'
                  '• Cây lớn dần: Hạt → Cây con → Trưởng thành → Ra hoa.',
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
