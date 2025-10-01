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

  int _computeScore(int correct, int wrong) {
    final score = correct * 8 - wrong * 5;
    return score < 0 ? 0 : score;
  }

  Future<void> _finishAndShowResult(int correct, int wrong) async {
    await GameSessionService().saveAndReward(
      treId: widget.treId,
      gameId: _kPlantCareGameId,
      gameName: 'Chăm Sóc Cây Trồng',
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

      onFinishAndExit: () => (_playKey.currentState as dynamic?)?.finishGame(),
      onSaveAndExit: () => (_playKey.currentState as dynamic?)?.outToHome(),

      onRestart: () => (_playKey.currentState as dynamic?)?.restartGame(),

      builder: (context, bool isPaused) {
        return PlantCarePlayScreen(
          key: _playKey,
          isPaused: isPaused,
          difficulty: _mapGameDifficulty(widget.difficulty),
          totalDays: widget.totalDays,
          dayLengthSec: widget.dayLengthSec,
          initialStateMap: _initialStateMap,

          onFinish: (int correct, int wrong) =>
              WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _finishAndShowResult(correct, wrong),
              ),

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

          onClearProgress: _clearProgress,
        );
      },
    );
  }
}

// ===== BẢN HƯỚNG DẪN ĐÃ ĐƯỢC CHỈNH SỬA MÀU SẮC CHO DỄ ĐỌC =====
class _PlantHelpSheet extends StatelessWidget {
  const _PlantHelpSheet();

  @override
  Widget build(BuildContext context) {
    const double baseFontSize = 16.0;
    const double headingFontSize = 18.0;

    // --- THAY ĐỔI: Sử dụng màu sáng, tương phản cao ---
    final headingStyle = TextStyle(
      fontSize: headingFontSize,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFF59D), // Màu vàng nhạt cho đề mục
      height: 1.5,
    );
    final bodyStyle = const TextStyle(
      fontSize: baseFontSize,
      height: 1.6,
      color: Colors.white, // Màu trắng cho nội dung
    );
    final boldBodyStyle = bodyStyle.copyWith(fontWeight: FontWeight.bold);

    Widget buildRichText(List<TextSpan> spans) {
      return RichText(text: TextSpan(style: bodyStyle, children: spans));
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Bí Kíp Trồng Cây Thần Kỳ ✨',
                  // --- THAY ĐỔI: Tiêu đề màu trắng, to rõ ---
                  style: headingStyle.copyWith(fontSize: 22, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Chào bạn nhỏ! Hãy cùng biến một hạt mầm bé xíu thành một cây hoa rực rỡ nhé!',
                  // --- THAY ĐỔI: Chữ trắng dễ đọc hơn ---
                  style: bodyStyle.copyWith(fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.9)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              Text('1. Mục Tiêu Của Con Là Gì? 🏆', style: headingStyle),
              const SizedBox(height: 8),
              buildRichText([
                const TextSpan(text: 'Nhiệm vụ của con là chăm sóc cho cây lớn lên qua các giai đoạn: '),
                TextSpan(text: 'Hạt mầm 🌱 ➔ Cây con 🌿 ➔ Cây trưởng thành 🌳 ➔ Cây ra hoa 🌸.', style: boldBodyStyle),
              ]),
              const SizedBox(height: 24),

              Text('2. Làm Sao Để Cây Luôn Khỏe Mạnh? ❤️', style: headingStyle),
              const SizedBox(height: 8),
              buildRichText([
                const TextSpan(text: 'Cây cần 4 thứ để vui vẻ:\n'),
                TextSpan(text: '     💧 Nước\n', style: boldBodyStyle),
                TextSpan(text: '     ☀️ Ánh Sáng\n', style: boldBodyStyle),
                TextSpan(text: '     🌿 Dinh Dưỡng\n', style: boldBodyStyle),
                TextSpan(text: '     🐞 Sạch Sẽ (không có sâu)\n\n', style: boldBodyStyle),
                const TextSpan(text: 'Hãy nhìn các thanh đo ở bên phải, mỗi thanh có một '),
                TextSpan(text: 'VÙNG MÀU VÀNG. ', style: boldBodyStyle),
                const TextSpan(text: 'Con hãy cố gắng giữ cho các chỉ số luôn nằm '),
                TextSpan(text: 'BÊN TRONG', style: boldBodyStyle),
                const TextSpan(text: ' vùng vàng đó nhé!\n\nKhi con làm tốt, '),
                TextSpan(text: 'Thanh Sức Khỏe (có hình ❤️) ', style: boldBodyStyle),
                const TextSpan(text: 'của cây sẽ đầy lên!'),
              ]),
              const SizedBox(height: 24),

              Text('3. Cách Chăm Sóc Cây 🎮', style: headingStyle),
              const SizedBox(height: 8),
              buildRichText([
                const TextSpan(text: 'Ở phía dưới màn hình có các nút công cụ. Mỗi nút sẽ mở ra một '),
                TextSpan(text: 'trò chơi nhỏ (mini-game) ', style: boldBodyStyle),
                const TextSpan(text: 'rất vui! Chơi giỏi sẽ giúp cây được đáp ứng nhu cầu ngay lập tức!'),
              ]),
              const SizedBox(height: 24),

              Text('4. Bí Mật Để Cây Lớn Nhanh & Nhận Sao ✨', style: headingStyle),
              const SizedBox(height: 8),
              buildRichText([
                const TextSpan(text: 'Cây có Sức Khỏe (❤️) càng cao thì '),
                TextSpan(text: 'Thanh Tăng Trưởng ', style: boldBodyStyle),
                const TextSpan(text: '(thanh tiến độ ở dưới cây) sẽ đầy càng nhanh. Khi thanh này đầy, cây sẽ lớn lên!\n\n'),
                const TextSpan(text: 'Vào cuối mỗi ngày, con sẽ được thưởng sao nếu chăm sóc cây thật tốt!'),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}