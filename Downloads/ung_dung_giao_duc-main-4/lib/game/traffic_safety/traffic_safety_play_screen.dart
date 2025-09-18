// lib/game/traffic_safety/traffic_safety_play_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobileapp/game/core/game.dart';
import 'package:mobileapp/game/core/types.dart';
import 'package:mobileapp/game/traffic_safety/data/traffic_safety_questions.dart';

enum QuestionType { multipleChoice, sorting, imageSelection }

class Question {
  final String id;
  final String situation;
  final String? icon;
  final String? imagePath;
  final List<String> options;
  final List<int> correctAnswerIndices;
  final QuestionType type;

  const Question({
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
  final bool isPaused;

  const TrafficSafetyPlayScreen({
    super.key,
    required this.game,
    required this.onFinish,
    required this.onSaveProgress,
    required this.onClearProgress,
    required this.isPaused,
    this.initialDeck,
    this.initialIndex,
    this.initialCorrect,
    this.initialWrong,
    this.initialTimeLeft,
  });

  @override
  State<TrafficSafetyPlayScreen> createState() => TrafficSafetyPlayScreenState();
}

class TrafficSafetyPlayScreenState extends State<TrafficSafetyPlayScreen> {
  static const int _totalRounds = 10;
  late List<Question> _deck;
  int _index = 0;
  int _correct = 0;
  int _wrong = 0;
  int? _selectedOption;
  List<int> _sortedOptions = [];
  List<int> _selectedImages = [];
  int _timeLeft = 0;
  Timer? _ticker;
  bool _flashCorrect = false;
  bool _flashWrong = false;

  @override
  void initState() {
    super.initState();
    _setupDeckAndState();
    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> finishGame() async {
    await _finish();
  }

  int _durationByDifficulty() {
    final d = widget.game.difficulty;
    if (d == 1) return 90;
    if (d == 2) return 75;
    return 60;
  }

  void _setupDeckAndState() {
    if (widget.initialDeck != null && widget.initialIndex != null) {
      _deck = widget.initialDeck!
          .map((id) => trafficSafetyQuestionsPool.firstWhere((e) => e.id == id))
          .toList();
      _index = widget.initialIndex!.clamp(0, _deck.isEmpty ? 0 : _deck.length - 1);
      _correct = widget.initialCorrect ?? 0;
      _wrong = widget.initialWrong ?? 0;
      _timeLeft = max(0, widget.initialTimeLeft ?? 0);
      if (_timeLeft <= 0 || widget.initialIndex! >= _deck.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      }
    } else {
      final all = List<Question>.from(trafficSafetyQuestionsPool);
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
      if (!mounted || widget.isPaused) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _finish();
    });
  }

  Future<void> outToHome() async {
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
    final isRight = sortedIndices.asMap().entries.every((entry) => entry.value == question.correctAnswerIndices[entry.key]);

    setState(() {
      _selectedOption = 1; // Đánh dấu là đã trả lời để khóa tương tác
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
    final difficultyLabel = switch (widget.game.difficulty) { 1 => 'Dễ', 2 => 'Vừa', _ => 'Khó' };
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/traffic_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IgnorePointer(
                ignoring: widget.isPaused,
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      color: _flashCorrect ? Colors.green.withOpacity(.1) : _flashWrong ? Colors.red.withOpacity(.1) : Colors.transparent,
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
                              label: widget.isPaused ? 'TẠM DỪNG' : '$_timeLeft giây',
                              color: widget.isPaused ? Colors.orange : (_timeLeft <= 10 ? Colors.red : Colors.blue),
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
                                  onPressed: (widget.isPaused || _selectedOption != null) ? null : _skip,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white70),
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
        ],
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

  // === CẬP NHẬT BẮT ĐẦU TỪ ĐÂY ===
  Widget _buildMultipleChoiceQuestion(Question question, Size screenSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(question.options.length, (i) {
        final isSelected = _selectedOption == i;
        final isCorrect = question.correctAnswerIndices.contains(i);
        Color? cardColor;
        Color? textColor;

        if (_selectedOption != null) {
          // Nếu câu hỏi đã được trả lời
          if (isCorrect) {
            cardColor = Colors.green; // Đáp án đúng màu xanh
            textColor = Colors.white;
          } else if (isSelected) {
            cardColor = Colors.red; // Lựa chọn sai màu đỏ
            textColor = Colors.white;
          } else {
            cardColor = Colors.grey.shade300; // Các lựa chọn khác bị làm mờ
            textColor = Colors.grey.shade600;
          }
        } else {
          // Trạng thái mặc định
          cardColor = Colors.white;
          textColor = Colors.black87;
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cardColor,
          child: InkWell(
            onTap: _selectedOption != null ? null : () => _handleAnswer(i),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
              child: Text(
                question.options[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
  // === KẾT THÚC CẬP NHẬT ===

  Widget _buildSortingQuestion(Question question, Size screenSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Kéo lựa chọn phù hợp vào hộp',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 16),
        DragTarget<int>(
          builder: (context, candidateData, rejectedData) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: candidateData.isNotEmpty ? Colors.lightBlueAccent : Colors.white60,
                  width: 2,
                ),
              ),
              constraints: BoxConstraints(minHeight: screenSize.height * 0.15),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _sortedOptions.map((optionIndex) {
                  return Draggable<int>(
                    data: optionIndex,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Chip(label: Text(question.options[optionIndex]), backgroundColor: Colors.green[200]),
                    ),
                    childWhenDragging: const SizedBox.shrink(),
                    child: Chip(
                      label: Text(question.options[optionIndex]),
                      backgroundColor: Colors.green[100],
                    ),
                  );
                }).toList(),
              ),
            );
          },
          onAccept: (index) {
            if (_selectedOption != null) return;
            setState(() {
              _sortedOptions.add(index);
              if (_sortedOptions.length == question.options.length) {
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) _handleSortingAnswer(_sortedOptions);
                });
              }
            });
          },
        ),

        const SizedBox(height: 10),
        const Text('↓ Kéo từ đây ↓', style: TextStyle(color: Colors.white70)),

        Expanded(
          child: SingleChildScrollView(
            child: DragTarget<int>(
              builder: (context, candidateData, rejectedData) {
                final availableOptions = List.generate(question.options.length, (i) => i)
                    .where((i) => !_sortedOptions.contains(i))
                    .toList();
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: availableOptions.map((i) {
                      return Draggable<int>(
                        data: i,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Chip(label: Text(question.options[i]), backgroundColor: Colors.blue[300]),
                        ),
                        childWhenDragging: Chip(label: Text(question.options[i]), backgroundColor: Colors.grey),
                        child: Chip(label: Text(question.options[i]), backgroundColor: Colors.blue[200]),
                      );
                    }).toList(),
                  ),
                );
              },
              onAccept: (index) {
                if (_selectedOption != null) return;
                setState(() {
                  _sortedOptions.remove(index);
                });
              },
            ),
          ),
        ),
      ],
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
          color: color.withOpacity(.25),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withOpacity(.5)),
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