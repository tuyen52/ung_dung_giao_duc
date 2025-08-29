import 'package:flutter/material.dart';

// Game runtime
import 'package:mobileapp/game/game.dart';
import 'package:mobileapp/game/traffic_safety_game.dart';
import 'package:mobileapp/game/traffic_safety_play_screen.dart'; 
import 'package:mobileapp/game/types.dart';

// Models & Services
import '../game/game_progress.dart';
import '../services/game_progress_service.dart';
import '../services/game_session_service.dart';

// UI sau khi hoàn thành ván
import 'game_result_screen.dart';

class TrafficSafetyGameLauncher extends StatefulWidget {
  final String treId;
  final String treName;
  final GameDifficulty difficulty;

  const TrafficSafetyGameLauncher({
    super.key,
    required this.treId,
    required this.treName,
    required this.difficulty,
  });

  @override
  State<TrafficSafetyGameLauncher> createState() => _TrafficSafetyGameLauncherState();
}

class _TrafficSafetyGameLauncherState extends State<TrafficSafetyGameLauncher> {
  static const String _gameId = 'traffic_safety';
  static const String _gameName = 'An Toàn Giao Thông';

  bool _loading = true;
  GameProgress? _progress;

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int difficultyInt =
        _progress?.difficulty ?? _mapDifficulty(widget.difficulty);
    final Game game = TrafficSafetyGame(difficulty: difficultyInt);

    return Scaffold(
      appBar: AppBar(title: Text('$_gameName • ${widget.treName}')),
      body: TrafficSafetyPlayScreen(
        game: game,
        onFinish: (c, w) =>
            WidgetsBinding.instance.addPostFrameCallback((_) => _finishAndSave(c, w)),
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
      ),
    );
  }
}