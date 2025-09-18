// lib/game/recycle_sort/recycle_sort_launcher.dart
import 'package:flutter/material.dart';

// Game runtime
import 'package:mobileapp/game/core/game.dart';
import 'package:mobileapp/game/recycle_sort/recycle_sort_game.dart';
import 'package:mobileapp/game/recycle_sort/recycle_sort_play_screen.dart';
import 'package:mobileapp/game/core/types.dart';
import 'package:mobileapp/game/widgets/game_screen_wrapper.dart';

// Models & Services
import '../core/game_progress.dart';
import '../../services/game_progress_service.dart';
import '../../services/game_session_service.dart';

// UI sau khi hoàn thành ván
import '../../screens/game_result_screen.dart';

class RecycleSortGameLauncher extends StatefulWidget {
  final String treId;
  final String treName;
  final GameDifficulty difficulty;

  const RecycleSortGameLauncher({
    super.key,
    required this.treId,
    required this.treName,
    required this.difficulty,
  });

  @override
  State<RecycleSortGameLauncher> createState() =>
      _RecycleSortGameLauncherState();
}

class _RecycleSortGameLauncherState extends State<RecycleSortGameLauncher> {
  static const String _gameId = 'recycle_sort';
  static const String _gameName = 'Phân Loại Rác';

  bool _loading = true;
  GameProgress? _progress;

  final GlobalKey<RecycleSortPlayScreenState> _playScreenKey =
  GlobalKey<RecycleSortPlayScreenState>();

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
        builder: (context) => RecycleSortGameLauncher(
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
    final Game game = RecycleSortGame(difficulty: difficultyInt);

    return GameScreenWrapper(
      gameName: _gameName,
      onFinishAndExit: () {
        _playScreenKey.currentState?.finishGame();
      },
      onSaveAndExit: () {
        _playScreenKey.currentState?.outToHome();
      },
      onRestart: _restartGame,
      // CẬP NHẬT: Truyền nội dung Sổ tay
      handbookContent: const Text(
        'Kéo và thả các vật phẩm vào đúng thùng rác tương ứng:\n\n'
            '• Thùng Hữu cơ: Dành cho rác dễ phân hủy như thức ăn thừa, vỏ trái cây, lá cây...\n\n'
            '• Thùng Vô cơ: Dành cho các loại rác khó phân hủy như chai nhựa, túi nylon, kim loại, pin...',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 16.0),
      ),
      builder: (context, isPaused) {
        return RecycleSortPlayScreen(
          key: _playScreenKey,
          isPaused: isPaused,
          game: game,
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