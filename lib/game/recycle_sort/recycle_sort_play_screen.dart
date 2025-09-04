// lib/game/recycle_sort/recycle_sort_play_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobileapp/game/core/game.dart';
import 'package:mobileapp/game/core/types.dart';
import 'package:mobileapp/game/recycle_sort/data/trash_data.dart';

// ... (Các enum và class TrashItem giữ nguyên)
enum TrashType { organic, inorganic }

class TrashItem {
  final String id;
  final String name;
  final String emoji;
  final TrashType type;

  const TrashItem(this.id, this.name, this.emoji, this.type);
}


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

  // THÊM: Hàm này để launcher có thể gọi khi người dùng muốn "Thoát & Tổng kết"
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

      _index = widget.initialIndex!.clamp(0, _deck.isEmpty ? 0 : _deck.length - 1);
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
    // ... (Toàn bộ hàm build giữ nguyên, không cần thay đổi)
    if (_index >= _deck.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final item = _deck[_index];
    final difficultyLabel =
    switch (widget.game.difficulty) { 1 => 'Dễ', 2 => 'Vừa', _ => 'Khó' };
    final score = _correct * 20 - _wrong * 10;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/game_background.gif',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
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
                      _chip(
                          icon: Icons.eco,
                          label: 'Môi trường',
                          color: Colors.green),
                      _chip(
                          icon: Icons.school,
                          label: difficultyLabel,
                          color: Colors.purple),
                      _chip(
                          icon: Icons.flag,
                          label: 'Vòng: ${_index + 1}/$_totalRounds',
                          color: Colors.teal),
                      _chip(
                          icon: Icons.stars,
                          label: 'Điểm: $score',
                          color: Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Kéo vật phẩm vào thùng phù hợp',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 2.0, color: Colors.black)])),
                ),
                Expanded(
                  child: Center(
                    child: IgnorePointer(
                      ignoring: widget.isPaused || _ignoreActions,
                      child: Draggable<TrashItem>(
                        data: item,
                        feedback: Transform.scale(
                          scale: 1.15,
                          child: _trashCard(item, dragging: true),
                        ),
                        childWhenDragging:
                        Opacity(opacity: .35, child: _trashCard(item)),
                        child: _trashCard(item),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                          child: _BinTarget(
                            key: _organicBinKey,
                            type: TrashType.organic,
                            label: 'Hữu cơ',
                            color: const Color(0xFF66BB6A),
                            onAccept: () => !widget.isPaused
                                ? _handleAnswer(TrashType.organic)
                                : null,
                          )),
                      Expanded(
                          child: _BinTarget(
                            key: _inorganicBinKey,
                            type: TrashType.inorganic,
                            label: 'Vô cơ',
                            color: const Color(0xFFBDBDBD),
                            onAccept: () => !widget.isPaused
                                ? _handleAnswer(TrashType.inorganic)
                                : null,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed:
                              widget.isPaused || _ignoreActions ? null : _skip,
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70)
                              ),
                              child: const Text('Câu mới'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FilledButton.icon(
                              icon: const Icon(Icons.flag),
                              label: const Text('Kết thúc'),
                              onPressed: _finish)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showCorrectOverlay)
            const Center(child: _FeedbackOverlay(isCorrect: true)),
          if (_showWrongOverlay)
            const Center(child: _FeedbackOverlay(isCorrect: false)),
        ],
      ),
    );
  }

  Widget _chip(
      {required IconData icon,
        required String label,
        required Color color}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(.25),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withOpacity(.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _trashCard(TrashItem item, {bool dragging = false}) => Card(
    color: dragging ? Colors.amber[50] : Colors.white,
    elevation: dragging ? 12 : 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(item.emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text(item.name,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ... (Các widget _BinTarget, _FeedbackOverlay giữ nguyên)
class _BinTarget extends StatefulWidget {
  final TrashType type;
  final String label;
  final Color color;
  final VoidCallback? onAccept;

  const _BinTarget(
      {super.key,
        required this.type,
        required this.label,
        required this.color,
        this.onAccept});

  @override
  State<_BinTarget> createState() => _BinTargetState();
}

class _BinTargetState extends State<_BinTarget> with TickerProviderStateMixin {
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
            double successRotation =
                sin(_successController.value * pi * 2) * 0.1;
            double failRotation = sin(_failController.value * pi * 3) * 0.2;

            return Transform.rotate(
              angle: _successController.isAnimating
                  ? successRotation
                  : failRotation,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(16),
            height: 160,
            decoration: BoxDecoration(
              color: _hovering
                  ? widget.color.withOpacity(.25)
                  : widget.color.withOpacity(.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color:
                  _hovering ? widget.color : widget.color.withOpacity(.5),
                  width: _hovering ? 3 : 2),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _hovering
                        ? Icons.delete_sweep_outlined
                        : Icons.delete_outline,
                    size: 48,
                    color: widget.color,
                  ),
                  const SizedBox(height: 6),
                  Text(widget.label,
                      style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ]),
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

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
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