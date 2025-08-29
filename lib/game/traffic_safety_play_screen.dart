import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'game.dart';
import 'types.dart';

// Định nghĩa loại câu hỏi
enum QuestionType { multipleChoice, sorting, imageSelection }

// Định nghĩa cấu trúc cho một câu hỏi
class Question {
  final String id;
  final String situation; // Tình huống câu hỏi
  final String? icon; // Icon hoặc emoji cho tình huống
  final String? imagePath; // Đường dẫn hình ảnh (cho câu hỏi hình ảnh)
  final List<String> options; // Danh sách các lựa chọn hoặc bước
  final List<int> correctAnswerIndices; // Danh sách các chỉ số đáp án đúng (hỗ trợ sắp xếp)
  final QuestionType type; // Loại câu hỏi

  Question({
    required this.id,
    required this.situation,
    this.icon,
    this.imagePath,
    required this.options,
    required this.correctAnswerIndices,
    required this.type,
  });
}

class TrafficSafetyPlayScreen extends StatefulWidget {
  final Game game;
  final FinishCallback onFinish;
  final Future<void> Function({
  required List<String> deck,
  required int index,
  required int correct,
  required int wrong,
  required int timeLeft,
  }) onSaveProgress;
  final Future<void> Function() onClearProgress;
  final List<String>? initialDeck;
  final int? initialIndex;
  final int? initialCorrect;
  final int? initialWrong;
  final int? initialTimeLeft;

  const TrafficSafetyPlayScreen({
    super.key,
    required this.game,
    required this.onFinish,
    required this.onSaveProgress,
    required this.onClearProgress,
    this.initialDeck,
    this.initialIndex,
    this.initialCorrect,
    this.initialWrong,
    this.initialTimeLeft,
  });

  @override
  State<TrafficSafetyPlayScreen> createState() => _TrafficSafetyPlayScreenState();
}

class _TrafficSafetyPlayScreenState extends State<TrafficSafetyPlayScreen> {
  static const int _totalRounds = 10;
  late List<Question> _pool;
  late List<Question> _deck;
  int _index = 0;
  int _correct = 0;
  int _wrong = 0;
  int? _selectedOption; // Dùng cho câu hỏi trắc nghiệm
  List<int> _sortedOptions = []; // Dùng cho câu hỏi sắp xếp
  List<int> _selectedImages = []; // Dùng cho câu hỏi hình ảnh
  int _timeLeft = 0;
  Timer? _ticker;
  bool _paused = false;
  bool _flashCorrect = false;
  bool _flashWrong = false;

  @override
  void initState() {
    super.initState();
    _buildPool();
    _setupDeckAndState();
    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _buildPool() {
    _pool = [
      // Câu hỏi trắc nghiệm (tình huống thực tế)
      Question(
        id: 'q1',
        situation: 'Khi đèn tín hiệu giao thông chuyển sang màu đỏ, em phải làm gì?',
        icon: '🚦',
        options: ['Đi tiếp', 'Dừng lại', 'Đi chậm lại'],
        correctAnswerIndices: [1],
        type: QuestionType.multipleChoice,
      ),
      Question(
        id: 'q2',
        situation: 'Khi gặp đám đông trên vỉa hè, em nên làm gì để an toàn?',
        icon: '👥',
        options: ['Đi ra lòng đường', 'Đi chậm và cẩn thận trên vỉa hè', 'Chạy nhanh qua đám đông'],
        correctAnswerIndices: [1],
        type: QuestionType.multipleChoice,
      ),
      Question(
        id: 'q3',
        situation: 'Khi đi xe buýt, em cần làm gì để an toàn?',
        icon: '🚌',
        options: ['Đứng gần cửa ra vào', 'Ngồi xuống và nắm tay vịn', 'Chạy quanh trong xe'],
        correctAnswerIndices: [1],
        type: QuestionType.multipleChoice,
      ),
      Question(
        id: 'q4',
        situation: 'Trong cơn mưa bão, em nên làm gì khi đi bộ qua đường?',
        icon: '🌧️',
        options: ['Chạy thật nhanh', 'Dùng ô và quan sát kỹ', 'Đi dưới lòng đường'],
        correctAnswerIndices: [1],
        type: QuestionType.multipleChoice,
      ),
      // Câu hỏi sắp xếp thứ tự
      Question(
        id: 'q5',
        situation: 'Sắp xếp các bước để qua đường an toàn theo thứ tự đúng:',
        icon: '🚸',
        options: [
          'Nhìn trái và phải',
          'Dừng lại ở lề đường',
          'Đi qua khi đường an toàn',
          'Giơ tay ra hiệu'
        ],
        correctAnswerIndices: [1, 0, 3, 2], // Thứ tự đúng: 2 -> 1 -> 4 -> 3
        type: QuestionType.sorting,
      ),
      // Câu hỏi chọn hình ảnh
      Question(
        id: 'q6',
        situation: 'Chọn biển báo cấm đỗ xe:',
        imagePath: 'assets/images/traffic_signs.png',
        options: [
          'assets/images/no_parking.png',
          'assets/images/no_entry.png',
          'assets/images/speed_limit.png',
          'assets/images/pedestrian.png'
        ],
        correctAnswerIndices: [0],
        type: QuestionType.imageSelection,
      ),
    ];
  }

  int _durationByDifficulty() {
    final d = widget.game.difficulty;
    if (d == 1) return 90;
    if (d == 2) return 75;
    return 60;
  }

  void _setupDeckAndState() {
    if (widget.initialDeck != null && widget.initialIndex != null) {
      _deck = widget.initialDeck!.map((id) => _pool.firstWhere((e) => e.id == id)).toList();
      _index = widget.initialIndex!.clamp(0, _deck.isEmpty ? 0 : _deck.length - 1);
      _correct = widget.initialCorrect ?? 0;
      _wrong = widget.initialWrong ?? 0;
      _timeLeft = max(0, widget.initialTimeLeft ?? 0);
      if (_timeLeft <= 0 || widget.initialIndex! >= _deck.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      }
    } else {
      final all = List<Question>.from(_pool);
      all.shuffle();
      _deck = all.take(_totalRounds).toList();
      _index = 0;
      _correct = 0;
      _wrong = 0;
      _timeLeft = _durationByDifficulty();
    }
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _paused) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _finish();
    });
  }

  void _togglePause() => setState(() => _paused = !_paused);

  Future<void> _outToHome() async {
    await widget.onSaveProgress(
      deck: _deck.map((e) => e.id).toList(),
      index: _index.clamp(0, _deck.isEmpty ? 0 : _deck.length - 1),
      correct: _correct,
      wrong: _wrong,
      timeLeft: _timeLeft,
    );
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/shell', (_) => false);
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    await widget.onClearProgress();
    if (!mounted) return;
    widget.onFinish(_correct, _wrong);
  }

  void _handleAnswer(int selectedIndex) {
    if (_selectedOption != null) return;
    final question = _deck[_index];
    final isRight = question.correctAnswerIndices.contains(selectedIndex);

    setState(() {
      _selectedOption = selectedIndex;
      if (isRight) {
        _correct++;
        _flashCorrect = true;
      } else {
        _wrong++;
        _flashWrong = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _flashCorrect = false;
        _flashWrong = false;
      });
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _nextRound();
    });
  }

  void _handleSortingAnswer(List<int> sortedIndices) {
    final question = _deck[_index];
    final isRight = sortedIndices.asMap().entries.every(
            (entry) => entry.value == question.correctAnswerIndices[entry.key]);

    setState(() {
      _sortedOptions = sortedIndices;
      if (isRight) {
        _correct++;
        _flashCorrect = true;
      } else {
        _wrong++;
        _flashWrong = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _flashCorrect = false;
        _flashWrong = false;
      });
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _nextRound();
    });
  }

  void _handleImageSelection(int selectedIndex) {
    if (_selectedOption != null) return;
    final question = _deck[_index];
    final isRight = question.correctAnswerIndices.contains(selectedIndex);

    setState(() {
      _selectedOption = selectedIndex;
      if (isRight) {
        _correct++;
        _flashCorrect = true;
      } else {
        _wrong++;
        _flashWrong = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _flashCorrect = false;
        _flashWrong = false;
      });
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _nextRound();
    });
  }

  void _nextRound() {
    if (_index + 1 >= _deck.length) {
      _finish();
    } else {
      setState(() {
        _index++;
        _selectedOption = null;
        _sortedOptions = [];
        _selectedImages = [];
      });
    }
  }

  void _skip() => _nextRound();

  @override
  Widget build(BuildContext context) {
    if (_index >= _deck.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = _deck[_index];
    final score = _correct * 20 - _wrong * 10;
    final difficultyLabel = switch (widget.game.difficulty) {
      1 => 'Dễ',
      2 => 'Vừa',
      _ => 'Khó'
    };
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('An Toàn Giao Thông'),
        actions: [
          IconButton(
            tooltip: _paused ? 'Tiếp tục' : 'Tạm dừng',
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
          ),
          IconButton(
            tooltip: 'Thoát & lưu tiến độ',
            icon: const Icon(Icons.logout),
            onPressed: _outToHome,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: IgnorePointer(
            ignoring: _paused,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  color: _flashCorrect
                      ? Colors.green.withOpacity(.1)
                      : _flashWrong
                      ? Colors.red.withOpacity(.1)
                      : Colors.transparent,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _chip(
                          icon: Icons.timer,
                          label: _paused ? 'TẠM DỪNG' : '$_timeLeft giây',
                          color: _paused
                              ? Colors.orange
                              : (_timeLeft <= 10 ? Colors.red : Colors.blue),
                        ),
                        _chip(icon: Icons.public, label: 'Xã hội', color: Colors.green),
                        _chip(icon: Icons.school, label: difficultyLabel, color: Colors.purple),
                        _chip(icon: Icons.flag, label: 'Câu: ${_index + 1}/$_totalRounds', color: Colors.teal),
                        _chip(icon: Icons.stars, label: 'Điểm: $score', color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            if (question.imagePath != null)
                              Image.asset(
                                question.imagePath!,
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (question.icon != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      question.icon!,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    question.situation,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _buildQuestionWidget(question, screenSize),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: (_paused || _selectedOption != null) ? null : _skip,
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(screenSize.width, screenSize.height * 0.06),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Câu mới', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.flag, size: 16),
                              label: const Text('Kết thúc', style: TextStyle(fontSize: 14)),
                              onPressed: _finish,
                              style: FilledButton.styleFrom(
                                minimumSize: Size(screenSize.width, screenSize.height * 0.06),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_flashCorrect || _flashWrong)
                  Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: 1.0,
                      child: Icon(
                        _flashCorrect ? Icons.check_circle : Icons.cancel,
                        size: 80,
                        color: _flashCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Question question, Size screenSize) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceQuestion(question, screenSize);
      case QuestionType.sorting:
        return _buildSortingQuestion(question, screenSize);
      case QuestionType.imageSelection:
        return _buildImageSelectionQuestion(question, screenSize);
    }
  }

  Widget _buildMultipleChoiceQuestion(Question question, Size screenSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(question.options.length, (i) {
        final isSelected = _selectedOption == i;
        final isCorrect = question.correctAnswerIndices.contains(i);
        Color? buttonColor;
        Color? foregroundColor;

        if (_selectedOption != null) {
          if (isCorrect) {
            buttonColor = Colors.green;
            foregroundColor = Colors.white;
          } else if (isSelected) {
            buttonColor = Colors.red;
            foregroundColor = Colors.white;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: FilledButton(
            onPressed: _selectedOption != null ? null : () => _handleAnswer(i),
            style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: foregroundColor,
              minimumSize: Size(screenSize.width, screenSize.height * 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              question.options[i],
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSortingQuestion(Question question, Size screenSize) {
    return DragTarget<int>(
      onAccept: (index) {
        setState(() {
          _sortedOptions.add(index);
        });
        if (_sortedOptions.length == question.options.length) {
          _handleSortingAnswer(_sortedOptions);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Kéo và thả các lựa chọn theo thứ tự đúng:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortedOptions
                  .asMap()
                  .entries
                  .map((entry) => Chip(
                label: Text(question.options[entry.value]),
                backgroundColor: Colors.blue[100],
              ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(question.options.length, (i) {
                if (_sortedOptions.contains(i)) return const SizedBox.shrink();
                return Draggable<int>(
                  data: i,
                  feedback: Material(
                    child: Chip(
                      label: Text(question.options[i]),
                      backgroundColor: Colors.blue[300],
                    ),
                  ),
                  childWhenDragging: const SizedBox.shrink(),
                  child: Chip(
                    label: Text(question.options[i]),
                    backgroundColor: Colors.blue[200],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageSelectionQuestion(Question question, Size screenSize) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.0,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(question.options.length, (i) {
        final isSelected = _selectedOption == i;
        final isCorrect = question.correctAnswerIndices.contains(i);
        Color? borderColor;

        if (_selectedOption != null) {
          if (isCorrect) {
            borderColor = Colors.green;
          } else if (isSelected) {
            borderColor = Colors.red;
          }
        }

        return GestureDetector(
          onTap: _selectedOption != null ? null : () => _handleImageSelection(i),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor ?? Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              question.options[i],
              fit: BoxFit.cover,
            ),
          ),
        );
      }),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withOpacity(.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}