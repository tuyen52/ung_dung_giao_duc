import 'package:flutter/material.dart';
import 'package:mobileapp/game/plant_care_play_screen.dart'; // Sẽ tạo file này ở bước sau
import 'package:mobileapp/game/game.dart';
import 'package:mobileapp/game/plant_care_game.dart';
import 'package:mobileapp/game/types.dart';
import '../game/game_progress.dart';
import '../services/game_progress_service.dart';
import '../services/game_session_service.dart';
import 'game_result_screen.dart';

class PlantCareGameLauncher extends StatefulWidget {
  final String treId;
  final String treName;
  final GameDifficulty difficulty;

  const PlantCareGameLauncher({
    super.key,
    required this.treId,
    required this.treName,
    required this.difficulty,
  });

  @override
  State<PlantCareGameLauncher> createState() => _PlantCareGameLauncherState();
}

class _PlantCareGameLauncherState extends State<PlantCareGameLauncher> {
  static const String _gameId = 'plant_care';
  static const String _gameName = 'Chăm Sóc Cây Trồng';

  bool _loading = true;
  GameProgress? _progress;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    // Game này phức tạp, không hỗ trợ resume. Luôn bắt đầu mới.
    // Bạn có thể phát triển thêm logic lưu/tải chi tiết (cây, tài nguyên) sau này.
    GameProgress? p = null;
    await GameProgressService().clear(widget.treId, _gameId);

    if (!mounted) return;
    setState(() {
      _progress = p;
      _loading = false;
    });
  }

  int _mapDifficulty(GameDifficulty d) => switch (d) {
    GameDifficulty.easy => 1,
    GameDifficulty.medium => 2,
    GameDifficulty.hard => 3,
  };

  Future<void> _finishAndSave(int correct, int wrong) async {
    final raw = correct * 10 - wrong * 5; // Game này điểm khác một chút
    final score = raw < 0 ? 0 : raw;

    await GameSessionService().saveAndReward(
      treId: widget.treId,
      gameId: _gameId,
      gameName: _gameName,
      difficulty: (_progress?.difficulty ?? _mapDifficulty(widget.difficulty)).toString(),
      correct: correct,
      wrong: wrong,
    );

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int difficultyInt = _mapDifficulty(widget.difficulty);
    final Game game = PlantCareGame(difficulty: difficultyInt);

    return Scaffold(
      appBar: AppBar(title: Text('$_gameName • ${widget.treName}')),
      // Game này có AppBar riêng nên chúng ta không cần AppBar chung nữa
      body: PlantCarePlayScreen(
        game: game,
        onFinish: (c, w) => WidgetsBinding.instance.addPostFrameCallback((_) => _finishAndSave(c, w)),
      ),
    );
  }
}