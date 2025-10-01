// lib/game/plant_care/plant_care_game_launcher.dart
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
    if (mounted) setState(() => _loading = false);
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
      correct: stars, // tổng sao tích luỹ
      wrong: 0,
      timeLeft: timeLeftSec,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _progress.save(gp);
  }

  Future<void> _clearProgress() async {
    await _progress.clear(widget.treId, _kPlantCareGameId);
  }

  /// Kid-friendly: mỗi sao +8 điểm, mỗi “ngày kết thúc sớm/không chơi” trừ 5.
  /// Không để điểm âm.
  int _computeScore(int correct, int wrong) {
    final score = correct * 8 - wrong * 5;
    return score < 0 ? 0 : score;
  }

  Future<void> _finishAndShowResult(int correct, int wrong) async {
    // Lưu phiên & thưởng theo hệ thống chung
    await GameSessionService().saveAndReward(
      treId: widget.treId,
      gameId: _kPlantCareGameId,
      gameName: 'Chăm Sóc Cây Trồng',
      difficulty: (_gp?.difficulty ??
          _difficultyToInt(_mapGameDifficulty(widget.difficulty)))
          .toString(),
      correct: correct, // tổng sao
      wrong: wrong,     // số “ngày spam/kết thúc sớm”
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

      // Gọi public method của PlayScreen qua key
      onFinishAndExit: () => (_playKey.currentState as dynamic?)?.finishGame(),
      onSaveAndExit: () => (_playKey.currentState as dynamic?)?.outToHome(),

      // Kết nối onRestart
      onRestart: () => (_playKey.currentState as dynamic?)?.restartGame(),

      builder: (context, bool isPaused) {
        return PlantCarePlayScreen(
          key: _playKey,
          isPaused: isPaused,
          difficulty: _mapGameDifficulty(widget.difficulty),
          totalDays: widget.totalDays,
          dayLengthSec: widget.dayLengthSec,
          initialStateMap: _initialStateMap,

          // Khi người chơi kết thúc ván (PlayScreen sẽ truyền tổng sao & tổng ngày spam)
          onFinish: (int correct, int wrong) =>
              WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _finishAndShowResult(correct, wrong),
              ),

          // Lưu tiến độ (mỗi khi hết ngày hoặc Save & Exit)
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
    // Kiểu chữ cố định, thân thiện với trẻ
    const double baseFontSize = 15.0;
    const double headingFontSize = 17.0;
    const double titleFontSize = 19.0;

    final titleStyle = TextStyle(
      fontSize: titleFontSize,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF2E7D32),
    );
    final headingStyle = TextStyle(
      fontSize: headingFontSize,
      fontWeight: FontWeight.bold,
    );
    final bodyStyle = const TextStyle(
      fontSize: baseFontSize,
      height: 1.5,
    );
    final boldBodyStyle = bodyStyle.copyWith(fontWeight: FontWeight.bold);
    final italicBodyStyle = bodyStyle.copyWith(fontStyle: FontStyle.italic);

    Widget buildRichText(List<TextSpan> spans) {
      return RichText(text: TextSpan(style: bodyStyle, children: spans));
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text('Bí kíp Chăm Cây Vui Vẻ', style: titleStyle)),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Chào mừng bạn nhỏ! Cùng giúp hạt mầm lớn nhanh và ra hoa rực rỡ nhé!',
                  style: italicBodyStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              Text('1. Làm sao để cây luôn VUI VẺ? ❤️', style: headingStyle),
              const SizedBox(height: 8),
              buildRichText([
                const TextSpan(text: '• Cây có 4 nhu cầu quan trọng: '),
                TextSpan(
                    text: 'Nước 💧, Ánh sáng ☀️, Phân bón 🌿, và Sạch sẽ 🐞.\n',
                    style: boldBodyStyle),
                const TextSpan(text: '• Cố gắng giữ chúng trong '),
                TextSpan(text: '"Vùng Xanh" ', style: boldBodyStyle),
                const TextSpan(text: 'nhé! Khi đó cây sẽ vui và lớn nhanh!'),
              ]),
              const SizedBox(height: 24),

              Text('2. Chăm cây bằng cách nào?', style: headingStyle),
              const SizedBox(height: 8),
              buildRichText([
                const TextSpan(text: '• Chạm các nút công cụ phía dưới màn hình.\n'),
                TextSpan(
                    text: '• Mỗi nút mở một trò chơi nhỏ ', style: boldBodyStyle),
                const TextSpan(text: 'vui lắm đó!\n'),
                const TextSpan(text: '• Chơi giỏi sẽ giúp cây được đáp ứng ngay!'),
              ]),
              const SizedBox(height: 24),

              Text('3. Mẹo để nhận SAO ✨', style: headingStyle),
              const SizedBox(height: 8),
              buildRichText([
                const TextSpan(text: '• Hãy chơi ít nhất một lúc (khoảng 1/4 thời gian).\n'),
                const TextSpan(text: '• Dùng công cụ giúp cây và nhìn cây lớn hơn nhé!\n'),
                const TextSpan(text: '• Càng giữ “Vùng xanh” tốt, sao càng nhiều!'),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
