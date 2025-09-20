// lib/game/swimming_safety/swimming_safety_launcher.dart
import 'package:flutter/material.dart';
import 'package:mobileapp/game/core/game.dart';
import 'package:mobileapp/game/core/types.dart';
import 'package:mobileapp/game/widgets/game_screen_wrapper.dart';
import '../core/game_progress.dart';
import '../../services/game_progress_service.dart';
import '../../services/game_session_service.dart';
import '../../screens/game_result_screen.dart';

// ĐÃ CẬP NHẬT ĐƯỜNG DẪN IMPORT
import 'swimming_safety_game.dart';
import 'swimming_safety_play_screen.dart';

class SwimmingSafetyGameLauncher extends StatefulWidget {
  // ... (Nội dung StatefulWidget không đổi)
  final String treId;
  final String treName;
  final GameDifficulty difficulty;

  const SwimmingSafetyGameLauncher({
    super.key,
    required this.treId,
    required this.treName,
    required this.difficulty,
  });

  @override
  State<SwimmingSafetyGameLauncher> createState() =>
      _SwimmingSafetyGameLauncherState();
}

class _SwimmingSafetyGameLauncherState extends State<SwimmingSafetyGameLauncher> {
  // ĐÃ CẬP NHẬT METADATA
  static const String _gameId = 'swimming_safety';
  static const String _gameName = 'An Toàn Bơi Lội';

  bool _loading = true;
  GameProgress? _progress;

  final GlobalKey<SwimmingSafetyPlayScreenState> _playScreenKey = // ĐÃ CẬP NHẬT
  GlobalKey<SwimmingSafetyPlayScreenState>();

  // ... (initState, _loadProgress, _mapDifficulty, _finishAndSave, _restartGame không đổi)
  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    GameProgress? p = await GameProgressService().load(widget.treId, _gameId);

    if (p != null && p.index >= p.deck.length) {
      await GameProgressService().clear(widget.treId, _gameId);
      p = null;
    }

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
    final raw = correct * 20 - wrong * 10;
    final score = raw < 0 ? 0 : raw;

    await GameSessionService().saveAndReward(
      treId: widget.treId,
      gameId: _gameId,
      gameName: _gameName,
      difficulty:
      (_progress?.difficulty ?? _mapDifficulty(widget.difficulty)).toString(),
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

  void _restartGame() async {
    await GameProgressService().clear(widget.treId, _gameId);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SwimmingSafetyGameLauncher(
          treId: widget.treId,
          treName: widget.treName,
          difficulty: widget.difficulty,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int difficultyInt =
        _progress?.difficulty ?? _mapDifficulty(widget.difficulty);
    final Game game = SwimmingSafetyGame(difficulty: difficultyInt); // ĐÃ CẬP NHẬT

    return GameScreenWrapper(
      gameName: _gameName,
      onFinishAndExit: () {
        _playScreenKey.currentState?.finishGame();
      },
      onSaveAndExit: () {
        _playScreenKey.currentState?.outToHome();
      },
      onRestart: _restartGame,
      // ĐÃ CẬP NHẬT NỘI DUNG SỔ TAY
      handbookContent: const Text(
        'Đọc kỹ tình huống và chọn câu trả lời đúng nhất.\n\n'
            '• Luôn khởi động kỹ trước khi xuống nước.\n'
            '• Không bơi ở khu vực nguy hiểm hoặc khi không có người lớn.\n'
            '• Bình tĩnh xử lý khi gặp sự cố và gọi trợ giúp.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 16.0),
      ),
      builder: (context, isPaused) {
        return SwimmingSafetyPlayScreen( // ĐÃ CẬP NHẬT
          key: _playScreenKey,
          isPaused: isPaused,
          game: game,
          // ... (Phần còn lại không đổi)
          onFinish: (c, w) => WidgetsBinding.instance
              .addPostFrameCallback((_) => _finishAndSave(c, w)),
          onSaveProgress: ({
            required List<String> deck,
            required int index,
            required int correct,
            required int wrong,
            required int timeLeft,
          }) async {
            final gp = GameProgress(
              treId: widget.treId,
              gameId: _gameId,
              difficulty: difficultyInt,
              deck: deck,
              index: index.clamp(0, deck.isEmpty ? 0 : deck.length - 1),
              correct: correct,
              wrong: wrong,
              timeLeft: timeLeft,
              updatedAt: DateTime.now().toIso8601String(),
            );
            await GameProgressService().save(gp);
          },
          onClearProgress: () async {
            await GameProgressService().clear(widget.treId, _gameId);
          },
          initialDeck: _progress?.deck,
          initialIndex: _progress?.index,
          initialCorrect: _progress?.correct,
          initialWrong: _progress?.wrong,
          initialTimeLeft: _progress?.timeLeft,
        );
      },
    );
  }
}