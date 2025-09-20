// lib/game/traffic_safety/traffic_safety_play_screen.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class TrafficSafetyPlayScreenState extends State<TrafficSafetyPlayScreen>
    with TickerProviderStateMixin {
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

  // Animation controllers
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Custom colors
  static const Color primaryBlue = Color(0xFF2E7CD6);
  static const Color secondaryPurple = Color(0xFF8B5CF6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color surfaceColor = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupDeckAndState();
    _startTimer();
  }

  void _initAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
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

    HapticFeedback.lightImpact();

    setState(() {
      _selectedOption = selectedIndex;
      if (isRight) {
        _correct++;
        _flashCorrect = true;
        HapticFeedback.heavyImpact();
      } else {
        _wrong++;
        _flashWrong = true;
        HapticFeedback.mediumImpact();
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
    final isRight = sortedIndices.asMap().entries.every((entry) =>
    entry.value == question.correctAnswerIndices[entry.key]);

    HapticFeedback.lightImpact();

    setState(() {
      _selectedOption = 1;
      if (isRight) {
        _correct++;
        _flashCorrect = true;
        HapticFeedback.heavyImpact();
      } else {
        _wrong++;
        _flashWrong = true;
        HapticFeedback.mediumImpact();
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

    HapticFeedback.lightImpact();

    setState(() {
      _selectedOption = selectedIndex;
      if (isRight) {
        _correct++;
        _flashCorrect = true;
        HapticFeedback.heavyImpact();
      } else {
        _wrong++;
        _flashWrong = true;
        HapticFeedback.mediumImpact();
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
      _slideController.reset();
      _slideController.forward();
      _scaleController.reset();
      _scaleController.forward();
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    _nextRound();
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _deck.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      body: Stack(
        children: [
          // ===== NỀN ẢNH THAY CHO GRADIENT =====
          Positioned.fill(
            child: Image.asset(
              'assets/images/traffic/traffic_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Lớp tối nhẹ để tăng độ tương phản chữ
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.08)),
          ),
          // Pattern nhẹ (giữ hoặc bỏ tùy thích)
          Positioned.fill(
            child: CustomPaint(painter: PatternPainter()),
          ),
          // Hiệu ứng kính mờ mịn toàn màn
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: Colors.black.withOpacity(0.08)),
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
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _flashCorrect
                            ? accentGreen.withOpacity(.15)
                            : _flashWrong
                            ? dangerRed.withOpacity(.15)
                            : Colors.transparent,
                      ),
                    ),
                    orientation == Orientation.portrait
                        ? _buildPortraitLayout()
                        : _buildLandscapeLayout(),
                    if (_flashCorrect || _flashWrong)
                      Center(
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 300),
                          tween: Tween(begin: 0, end: 1),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (_flashCorrect ? accentGreen : dangerRed)
                                      .withOpacity(0.2),
                                  border: Border.all(
                                    color:
                                    _flashCorrect ? accentGreen : dangerRed,
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  _flashCorrect
                                      ? Icons.check_rounded
                                      : Icons.close_rounded,
                                  size: 60,
                                  color: _flashCorrect
                                      ? accentGreen
                                      : dangerRed,
                                ),
                              ),
                            );
                          },
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

  Widget _buildPortraitLayout() {
    final question = _deck[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoChips(),
        const SizedBox(height: 16),
        SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildQuestionCard(question),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 3,
          child: _buildQuestionWidget(question),
        ),
        _buildControlButtons(),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    final question = _deck[_index];
    return Column(
      children: [
        _buildInfoChips(),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildQuestionCard(question),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: _buildQuestionWidget(question),
              ),
            ],
          ),
        ),
        _buildControlButtons(),
      ],
    );
  }

  Widget _buildInfoChips() {
    final score = _correct * 20 - _wrong * 10;
    final difficultyLabel = switch (widget.game.difficulty) {
      1 => 'Dễ',
      2 => 'Vừa',
      _ => 'Khó'
    };

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _buildModernChip(
          icon: Icons.timer_rounded,
          label: widget.isPaused ? 'TẠM DỪNG' : '$_timeLeft giây',
          color: widget.isPaused
              ? warningOrange
              : (_timeLeft <= 10 ? dangerRed : primaryBlue),
          isAnimated: !widget.isPaused && _timeLeft <= 10,
        ),
        _buildModernChip(
          icon: Icons.public_rounded,
          label: 'Xã hội',
          color: accentGreen,
        ),
        _buildModernChip(
          icon: Icons.school_rounded,
          label: difficultyLabel,
          color: secondaryPurple,
        ),
        _buildModernChip(
          icon: Icons.flag_rounded,
          label: 'Câu ${_index + 1}/$_totalRounds',
          color: const Color(0xFF06B6D4),
        ),
        _buildModernChip(
          icon: Icons.star_rounded,
          label: '$score điểm',
          color: warningOrange,
        ),
      ],
    );
  }

  Widget _buildModernChip({
    required IconData icon,
    required String label,
    required Color color,
    bool isAnimated = false,
  }) {
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (isAnimated) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: chip,
          );
        },
      );
    }
    return chip;
  }

  Widget _buildQuestionCard(Question question) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (question.imagePath != null)
                  Container(
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        question.imagePath!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (question.icon != null)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              primaryBlue.withOpacity(0.2),
                              secondaryPurple.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Text(
                          question.icon!,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        question.situation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        children: [
          Expanded(
            child: _buildGlassButton(
              onPressed: (widget.isPaused || _selectedOption != null) ? null : _skip,
              icon: Icons.skip_next_rounded,
              label: 'Bỏ qua',
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildGlassButton(
              onPressed: _finish,
              icon: Icons.flag_rounded,
              label: 'Kết thúc',
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isPrimary
            ? const LinearGradient(
          colors: [primaryBlue, secondaryPurple],
        )
            : null,
        border: isPrimary
            ? null
            : Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: isPrimary
            ? [
          BoxShadow(
            color: primaryBlue.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: isPrimary
                ? Colors.transparent
                : Colors.white.withOpacity(0.1),
            child: InkWell(
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: onPressed == null
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onPressed == null
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Question question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceQuestion(question);
      case QuestionType.sorting:
        return _buildSortingQuestion(question);
      case QuestionType.imageSelection:
        return _buildImageSelectionQuestion(question);
    }
  }

  Widget _buildMultipleChoiceQuestion(Question question) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    if (isPortrait) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(question.options.length, (i) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (i * 100)),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildModernChoiceCard(question, i),
                ),
              );
            },
          );
        }),
      );
    } else {
      return Center(
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: List.generate(question.options.length, (i) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (i * 100)),
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: _buildModernChoiceCard(question, i, isVertical: false),
                );
              },
            );
          }),
        ),
      );
    }
  }

  Widget _buildModernChoiceCard(Question question, int index, {bool isVertical = true}) {
    final isSelected = _selectedOption == index;
    final isCorrect = question.correctAnswerIndices.contains(index);

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? icon;

    if (_selectedOption != null) {
      if (isCorrect) {
        bgColor = accentGreen;
        borderColor = accentGreen;
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
      } else if (isSelected) {
        bgColor = dangerRed;
        borderColor = dangerRed;
        textColor = Colors.white;
        icon = Icons.cancel_rounded;
      } else {
        bgColor = Colors.white.withOpacity(0.3);
        borderColor = Colors.white.withOpacity(0.2);
        textColor = Colors.white.withOpacity(0.6);
      }
    } else {
      bgColor = Colors.white.withOpacity(0.9);
      borderColor = Colors.white;
      textColor = surfaceColor;
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: isVertical ? 8.0 : 0),
      height: isVertical ? 72 : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectedOption != null ? null : () => _handleAnswer(index),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: textColor, size: 24),
                          const SizedBox(width: 12),
                        ],
                        Flexible(
                          child: Text(
                            question.options[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSortingQuestion(Question question) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    final availableOptions = List.generate(question.options.length, (i) => i)
        .where((i) => !_sortedOptions.contains(i))
        .toList();

    final sourceArea = DragTarget<int>(
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: availableOptions.map((i) {
              return Draggable<int>(
                data: i,
                feedback: Material(
                  color: Colors.transparent,
                  child: _buildDraggableChip(
                      question.options[i], primaryBlue, isFeedback: true),
                ),
                childWhenDragging: _buildDraggableChip(
                    question.options[i], Colors.grey, isDragging: true),
                child: _buildDraggableChip(question.options[i], primaryBlue),
              );
            }).toList(),
          ),
        );
      },
      onAccept: (index) {
        if (_selectedOption != null) return;
        setState(() => _sortedOptions.remove(index));
      },
    );

    final targetArea = DragTarget<int>(
      builder: (context, candidateData, rejectedData) {
        bool isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isHovering
                ? accentGreen.withOpacity(0.2)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovering
                  ? accentGreen.withOpacity(0.8)
                  : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _sortedOptions.asMap().entries.map((entry) {
              int idx = entry.key;
              int optionIndex = entry.value;

              Widget chip = _buildDraggableChip(
                  '${idx + 1}. ${question.options[optionIndex]}', accentGreen);

              return Draggable<int>(
                data: optionIndex,
                feedback: Material(
                  color: Colors.transparent,
                  child: _buildDraggableChip(
                    '${idx + 1}. ${question.options[optionIndex]}',
                    accentGreen,
                    isFeedback: true,
                  ),
                ),
                childWhenDragging: const SizedBox.shrink(),
                child: chip,
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
    );

    if (isPortrait) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Kéo và thả vào hộp theo đúng thứ tự',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 12),
          targetArea,
          const SizedBox(height: 16),
          const Text('↓ Kéo từ đây ↓',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Expanded(child: SingleChildScrollView(child: sourceArea)),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Kéo từ đây',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Flexible(child: SingleChildScrollView(child: sourceArea)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Thả vào đây',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Flexible(child: SingleChildScrollView(child: targetArea)),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDraggableChip(String label, Color color,
      {bool isFeedback = false, bool isDragging = false}) {
    return Transform.scale(
      scale: isFeedback ? 1.1 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDragging ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(16),
          border: isDragging ? Border.all(color: Colors.white54, width: 2) : null,
          boxShadow: isFeedback
              ? [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2)
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDragging ? Colors.white54 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelectionQuestion(Question question) {
    return Center(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        itemCount: question.options.length,
        itemBuilder: (context, i) {
          final isSelected = _selectedOption == i;
          final isCorrect = question.correctAnswerIndices.contains(i);
          Color borderColor = Colors.transparent;
          double borderWidth = 4.0;
          Color? overlayColor;
          IconData? icon;

          if (_selectedOption != null) {
            if (isCorrect) {
              borderColor = accentGreen;
              overlayColor = accentGreen.withOpacity(0.4);
              icon = Icons.check_circle_rounded;
            } else if (isSelected) {
              borderColor = dangerRed;
              overlayColor = dangerRed.withOpacity(0.4);
              icon = Icons.cancel_rounded;
            } else {
              borderWidth = 0;
              overlayColor = Colors.black.withOpacity(0.5);
            }
          }

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (i * 100)),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: GestureDetector(
                    onTap: _selectedOption != null ? null : () => _handleImageSelection(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: borderWidth),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: GridTile(
                          footer: icon != null
                              ? Container(
                            height: 40,
                            color: Colors.black54,
                            child: Icon(icon,
                                color: isCorrect ? accentGreen : dangerRed,
                                size: 28),
                          )
                              : null,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                question.options[i],
                                fit: BoxFit.cover,
                              ),
                              if (overlayColor != null)
                                Container(color: overlayColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Custom Painter for the subtle background pattern
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const double radius = 1.5;
    const double spacing = 30.0;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
