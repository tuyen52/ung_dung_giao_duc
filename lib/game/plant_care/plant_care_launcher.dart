import 'package:flutter/material.dart';

// Game runtime
import 'package:mobileapp/game/core/game.dart';
import 'package:mobileapp/game/plant_care/plant_care_game.dart';
import 'package:mobileapp/game/plant_care/plant_care_play_screen.dart';
import 'package:mobileapp/game/core/types.dart';
import 'package:mobileapp/game/widgets/game_screen_wrapper.dart';
import 'package:mobileapp/game/plant_care/data/plant_care_data.dart';

// Models & Services
import '../core/game_progress.dart';
import '../../services/game_progress_service.dart';
import '../../services/game_session_service.dart';

// UI sau khi hoàn thành ván
import '../../screens/game_result_screen.dart';

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

  final GlobalKey<PlantCarePlayScreenState> _playScreenKey = GlobalKey();

  int _mapDifficulty(GameDifficulty d) => switch (d) {
    GameDifficulty.easy => 1,
    GameDifficulty.medium => 2,
    GameDifficulty.hard => 3,
  };

  Future<void> _finishAndSave(int correct, int wrong) async {
    final raw = correct * 5 - wrong * 5;
    final score = raw < 0 ? 0 : raw;

    await GameSessionService().saveAndReward(
      treId: widget.treId,
      gameId: _gameId,
      gameName: _gameName,
      difficulty: _mapDifficulty(widget.difficulty).toString(),
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

  void _restartGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PlantCareGameLauncher(
          treId: widget.treId,
          treName: widget.treName,
          difficulty: widget.difficulty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Game game = PlantCareGame(difficulty: _mapDifficulty(widget.difficulty));

    return GameScreenWrapper(
      gameName: _gameName,
      onFinishAndExit: () {
        final state = _playScreenKey.currentState;
        if (state != null) {
          _finishAndSave(state.correctActions, state.wrongActions); // Sử dụng correctActions/wrongActions
        } else {
          Navigator.of(context).pop();
        }
      },
      onRestart: _restartGame,
      handbookContent: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Mục tiêu chính:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            SizedBox(height: 8),
            Text(
              '• Giữ các thanh trạng thái (Nước, Ánh sáng, Dinh dưỡng) của cây luôn ở mức cao để cây khỏe mạnh và phát triển qua các giai đoạn.',
              style: TextStyle(color: Colors.white70, fontSize: 16.0),
            ),
            SizedBox(height: 16),
            Text(
              'Lưu ý đặc biệt:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            SizedBox(height: 8),
            Text(
              '• 🌵 Xương rồng: Cần RẤT NHIỀU ánh sáng nhưng không ưa nhiều nước.',
              style: TextStyle(color: Colors.white70, fontSize: 16.0),
            ),
            SizedBox(height: 8),
            Text(
              '• 🌿 Dương xỉ: Cần RẤT NHIỀU nước nhưng không thích ánh sáng gắt.',
              style: TextStyle(color: Colors.white70, fontSize: 16.0),
            ),
            SizedBox(height: 16),
            Text(
              'Sự kiện ngẫu nhiên:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            SizedBox(height: 8),
            Text(
              '• Đôi khi cây sẽ gặp các vấn đề đột xuất (sâu bệnh, đất khô...). Hãy chọn đúng công cụ để khắc phục.',
              style: TextStyle(color: Colors.white70, fontSize: 16.0),
            ),
          ],
        ),
      ),
      builder: (context, isPaused) {
        return PlantCarePlayScreen(
          key: _playScreenKey,
          game: game,
          onFinish: (c, w) => WidgetsBinding.instance.addPostFrameCallback((_) => _finishAndSave(c, w)),
        );
      },
    );
  }
}