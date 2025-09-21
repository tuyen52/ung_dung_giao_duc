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
    // Sử dụng Media query để lấy kích thước màn hình
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Điều chỉnh kích thước phông chữ dựa trên kích thước màn hình
    // Đây là các giá trị tương đối, bạn có thể điều chỉnh thêm để phù hợp nhất
    final baseFontSize = screenWidth * 0.04; // Ví dụ: 4% chiều rộng màn hình cho văn bản thường
    final headingFontSize = screenWidth * 0.05; // 5% chiều rộng màn hình cho tiêu đề nhỏ
    final titleFontSize = screenWidth * 0.06; // 6% chiều rộng màn hình cho tiêu đề chính

    // Định nghĩa các kiểu chữ với kích thước mới
    final titleStyle = TextStyle(
      fontSize: titleFontSize,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF2E7D32), // Màu xanh lá cây đậm
    );
    final headingStyle = TextStyle(
      fontSize: headingFontSize,
      fontWeight: FontWeight.bold,
    );
    final bodyStyle = TextStyle(
      fontSize: baseFontSize,
      height: 1.5, // Giữ khoảng cách dòng để dễ đọc hơn
    );
    final boldBodyStyle = bodyStyle.copyWith(fontWeight: FontWeight.bold);
    final italicBodyStyle = bodyStyle.copyWith(fontStyle: FontStyle.italic);


    // Widget trợ giúp để tạo văn bản có chữ đậm/thường
    Widget buildRichText(List<TextSpan> spans) {
      return RichText(
        text: TextSpan(
          style: bodyStyle,
          children: spans,
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text('Bí kíp Chăm Cây Vui Vẻ', style: titleStyle),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Chào mừng bạn nhỏ! Cùng giúp một hạt mầm lớn thật nhanh và ra hoa rực rỡ nhé!',
                  style: italicBodyStyle, // Sử dụng kiểu italicBodyStyle
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // --- Mục 1 ---
              Text('1. Làm sao để cây luôn VUI VẺ? ❤️', style: headingStyle),
              const SizedBox(height: 8),
              buildRichText([
                const TextSpan(text: '• Cây của bạn có 4 nhu cầu quan trọng: '),
                TextSpan(
                    text: 'Nước 💧, Ánh sáng ☀️, Phân bón 🌿, và được Sạch sẽ 🐞.\n',
                    style: boldBodyStyle),
                const TextSpan(
                    text:
                    '• Hãy để ý các thanh nhu cầu này. Cố gắng giữ chúng luôn nằm trong '),
                TextSpan(text: '"Vùng Vàng" ', style: boldBodyStyle),
                const TextSpan(text: 'nhé.\n'),
                const TextSpan(
                    text:
                    '• Khi đó, cây sẽ rất vui, khỏe mạnh và lớn rất nhanh!'),
              ]),
              const SizedBox(height: 24),

              // --- Mục 2 ---
              Text('2. Phải làm gì để chăm cây?', style: headingStyle),
              const SizedBox(height: 8),
              buildRichText([
                const TextSpan(
                    text:
                    '• Rất đơn giản! Hãy bấm vào các nút công cụ ở phía dưới màn hình.\n'),
                const TextSpan(text: '• Mỗi nút bấm sẽ mở ra một '),
                TextSpan(
                    text: 'trò chơi nhỏ (mini-game) ', style: boldBodyStyle),
                const TextSpan(text: 'thú vị.\n'),
                const TextSpan(
                    text:
                    '• Chơi thật giỏi sẽ giúp cây được đáp ứng nhu cầu ngay lập tức!'),
              ]),
              const SizedBox(height: 24),

              // --- Mục 3 ---
              Text('3. Phần thưởng lấp lánh!', style: headingStyle),
              const SizedBox(height: 8),
              buildRichText([
                const TextSpan(
                    text:
                    '• Cuối mỗi ngày, nếu bạn chăm cây tốt, bạn sẽ được thưởng những ngôi '),
                TextSpan(text: 'Sao ★ ', style: boldBodyStyle),
                const TextSpan(text: 'lấp lánh.\n'),
                const TextSpan(text: '• Càng nhiều sao, điểm của bạn sẽ càng cao!'),
              ]),
              const SizedBox(height: 24), // Thêm khoảng trống dưới cùng cho nút "Đã hiểu" (nếu có)
            ],
          ),
        ),
      ),
    );
  }
}