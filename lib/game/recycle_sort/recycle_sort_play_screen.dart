// lib/game/recycle_sort/recycle_sort_play_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobileapp/game/core/game.dart';
import 'package:mobileapp/game/core/types.dart';
import 'package:mobileapp/game/recycle_sort/data/trash_data.dart';

// ENUMS and CLASSES for TrashData
enum TrashType { organic, inorganic }

class TrashItem {
  final String id;
  final String name;
  final String imagePath;
  final TrashType type;

  const TrashItem(this.id, this.name, this.imagePath, this.type);
}

// MAIN PLAY SCREEN WIDGET
class RecycleSortPlayScreen extends StatefulWidget {
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

  const RecycleSortPlayScreen({
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
  State<RecycleSortPlayScreen> createState() => RecycleSortPlayScreenState();
}

class RecycleSortPlayScreenState extends State<RecycleSortPlayScreen> {
  static const int _totalRounds = 10;
  late List<TrashItem> _deck;
  int _index = 0;
  int _correct = 0;
  int _wrong = 0;
  int _timeLeft = 0;
  Timer? _ticker;
  bool _ignoreActions = false;
  bool _showCorrectOverlay = false;
  bool _showWrongOverlay = false;

  final GlobalKey<_BinTargetState> _organicBinKey = GlobalKey();
  final GlobalKey<_BinTargetState> _inorganicBinKey = GlobalKey();

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
    if (d == 1) return 60;
    if (d == 2) return 45;
    return 30;
  }

  void _setupDeckAndState() {
    if (widget.initialDeck != null && widget.initialIndex != null) {
      _deck = widget.initialDeck!
          .map((id) => recycleSortTrashPool.firstWhere((e) => e.id == id))
          .toList();
      _index =
          widget.initialIndex!.clamp(0, _deck.isEmpty ? 0 : _deck.length - 1);
      _correct = widget.initialCorrect ?? 0;
      _wrong = widget.initialWrong ?? 0;
      _timeLeft = max(0, widget.initialTimeLeft ?? 0);

      if (_timeLeft <= 0 || widget.initialIndex! >= _deck.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      }
    } else {
      final all = List<TrashItem>.from(recycleSortTrashPool)..shuffle(Random());
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

  void _handleAnswer(TrashType dropTo) {
    if (_ignoreActions) return;
    final item = _deck[_index];
    final isRight = (item.type == dropTo);

    setState(() {
      _ignoreActions = true;
      if (isRight) {
        _correct++;
        _showCorrectOverlay = true;
        if (dropTo == TrashType.organic) {
          _organicBinKey.currentState?.playSuccessAnimation();
        } else {
          _inorganicBinKey.currentState?.playSuccessAnimation();
        }
      } else {
        _wrong++;
        _showWrongOverlay = true;
        if (dropTo == TrashType.organic) {
          _organicBinKey.currentState?.playFailAnimation();
        } else {
          _inorganicBinKey.currentState?.playFailAnimation();
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _showCorrectOverlay = false;
        _showWrongOverlay = false;
        _ignoreActions = false;
      });
      _nextRound();
    });
  }

  void _nextRound() {
    if (_index + 1 >= _deck.length) {
      _finish();
    } else {
      setState(() => _index++);
    }
  }

  void _skip() => _nextRound();

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
          Positioned.fill(
            child: Image.asset(
              'assets/images/environment/environment_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.08),
            ),
          ),
          SafeArea(
            child: orientation == Orientation.portrait
                ? _buildPortraitLayout()
                : _buildLandscapeLayout(),
          ),
          if (_showCorrectOverlay)
            const Center(child: _FeedbackOverlay(isCorrect: true)),
          if (_showWrongOverlay)
            const Center(child: _FeedbackOverlay(isCorrect: false)),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final binSize = screenWidth * 0.3;
    final itemImageSize = screenWidth * 0.2;

    // CẬP NHẬT: Bọc toàn bộ Column trong SingleChildScrollView
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // Đảm bảo Column cao ít nhất bằng chiều cao màn hình
          minHeight: screenHeight - MediaQuery.of(context).padding.top,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nhóm các widget không co giãn vào một Column
            Column(
              children: [
                _buildInfoChips(),
                const SizedBox(height: 12),
                _instructionLabel(),
              ],
            ),
            // Widget co giãn ở giữa
            SizedBox(
              height: itemImageSize * 2, // Dành không gian đủ lớn cho item
              child: _buildDraggableTrashItem(itemImageSize),
            ),
            // Nhóm các widget dưới cùng
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _BinTarget(
                        key: _organicBinKey,
                        type: TrashType.organic,
                        label: 'Hữu cơ',
                        onAccept: () => !widget.isPaused ? _handleAnswer(TrashType.organic) : null,
                        size: binSize,
                      ),
                      _BinTarget(
                        key: _inorganicBinKey,
                        type: TrashType.inorganic,
                        label: 'Vô cơ',
                        onAccept: () => !widget.isPaused ? _handleAnswer(TrashType.inorganic) : null,
                        size: binSize,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildControlButtons(),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLandscapeLayout() {
    final screenHeight = MediaQuery.of(context).size.height;
    final binSize = screenHeight * 0.45;
    final itemImageSize = screenHeight * 0.25;

    return Column(
      children: [
        _buildInfoChips(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BinTarget(
                key: _organicBinKey,
                type: TrashType.organic,
                label: 'Hữu cơ',
                onAccept: () =>
                !widget.isPaused ? _handleAnswer(TrashType.organic) : null,
                size: binSize,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _instructionLabel(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildDraggableTrashItem(itemImageSize)),
                  ],
                ),
              ),
              _BinTarget(
                key: _inorganicBinKey,
                type: TrashType.inorganic,
                label: 'Vô cơ',
                onAccept: () => !widget.isPaused
                    ? _handleAnswer(TrashType.inorganic)
                    : null,
                size: binSize,
              ),
            ],
          ),
        ),
        _buildControlButtons(),
      ],
    );
  }

  Widget _instructionLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.swipe, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Kéo vật phẩm vào thùng phù hợp',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        blurRadius: 3,
                        color: Colors.black87,
                        offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChips() {
    final difficultyLabel =
    switch (widget.game.difficulty) { 1 => 'Dễ', 2 => 'Vừa', _ => 'Khó' };
    final score = _correct * 20 - _wrong * 10;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _chip(
            icon: Icons.timer,
            label: widget.isPaused ? 'TẠM DỪNG' : '$_timeLeft giây',
            color: widget.isPaused
                ? Colors.orange
                : (_timeLeft <= 5 ? Colors.red : Colors.blue),
          ),
          _chip(icon: Icons.eco, label: 'Môi trường', color: Colors.green),
          _chip(icon: Icons.school, label: difficultyLabel, color: Colors.purple),
          _chip(
              icon: Icons.flag,
              label: 'Vòng: ${_index + 1}/$_totalRounds',
              color: Colors.teal),
          _chip(icon: Icons.stars, label: 'Điểm: $score', color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildDraggableTrashItem(double imageSize) {
    final item = _deck[_index];
    return Center(
      child: IgnorePointer(
        ignoring: widget.isPaused || _ignoreActions,
        child: Draggable<TrashItem>(
          data: item,
          feedback: Transform.scale(
            scale: 1.15,
            child: _trashCard(item, imageSize, dragging: true),
          ),
          childWhenDragging:
          Opacity(opacity: .35, child: _trashCard(item, imageSize)),
          child: _trashCard(item, imageSize),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.isPaused || _ignoreActions ? null : _skip,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              child: const Text('Câu mới'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.flag),
              label: const Text('Kết thúc'),
              onPressed: widget.isPaused ? null : _finish,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.circle, size: 0),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: .2,
              shadows: [
                Shadow(
                  blurRadius: 3,
                  color: Colors.black87,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ]),
      );

  Widget _trashCard(TrashItem item, double imageSize, {bool dragging = false}) =>
      Card(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(
              item.imagePath,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 3,
                      color: Colors.black87,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      );
}

class _BinTarget extends StatefulWidget {
  final TrashType type;
  final String label;
  final VoidCallback? onAccept;
  final double size;

  const _BinTarget(
      {super.key,
        required this.type,
        required this.label,
        this.onAccept,
        required this.size});

  @override
  State<_BinTarget> createState() => _BinTargetState();
}

class _BinTargetState extends State<_BinTarget>
    with TickerProviderStateMixin {
  bool _hovering = false;
  late final AnimationController _successController;
  late final AnimationController _failController;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _failController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _successController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _successController.reset();
        });
      }
    });
  }

  @override
  void dispose() {
    _successController.dispose();
    _failController.dispose();
    super.dispose();
  }

  void playSuccessAnimation() {
    _successController.forward(from: 0);
  }

  void playFailAnimation() {
    _failController.forward(from: 0);
  }

  String _getImagePath() {
    final binType =
    widget.type == TrashType.organic ? 'organic' : 'inorganic';
    if (_successController.isAnimating) {
      return 'assets/images/environment/bin_${binType}_full.png';
    }
    return 'assets/images/environment/bin_${binType}_idle.png';
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<TrashItem>(
      onWillAccept: (_) {
        setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAccept: (_) {
        setState(() => _hovering = false);
        widget.onAccept?.call();
      },
      builder: (_, __, ___) {
        return AnimatedBuilder(
          animation: Listenable.merge([_successController, _failController]),
          builder: (context, child) {
            double successScale = 1.0 + _successController.value * 0.1;
            double failRotation = sin(_failController.value * pi * 3) * 0.2;

            return Transform.rotate(
              angle: failRotation,
              child: Transform.scale(
                scale: successScale,
                child: child,
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(_hovering ? 4 : 8),
            decoration: BoxDecoration(
              color: _hovering
                  ? Colors.white.withOpacity(0.18)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  _getImagePath(),
                  height: widget.size,
                  width: widget.size,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: .2,
                      shadows: [
                        Shadow(
                          blurRadius: 3,
                          color: Colors.black87,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeedbackOverlay extends StatefulWidget {
  final bool isCorrect;
  const _FeedbackOverlay({required this.isCorrect});

  @override
  State<_FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends State<_FeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.7, 1.0, curve: Curves.easeIn)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.isCorrect
                ? const Icon(Icons.star_rounded,
                color: Colors.amber, size: 150)
                : const Icon(Icons.cancel_rounded,
                color: Colors.red, size: 150),
          ),
        ),
      ),
    );
  }
}