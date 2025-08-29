import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'game.dart';
import 'types.dart';

// DI CHUYỂN VÀO ĐÂY: Các định nghĩa này chỉ dành riêng cho game phân loại rác
enum TrashType { organic, inorganic }

class TrashItem {
  final String id;
  final String name;
  final String emoji;
  final TrashType type;
  TrashItem(this.id, this.name, this.emoji, this.type);
}
// KẾT THÚC PHẦN DI CHUYỂN

// ĐỔI TÊN CLASS
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

  const RecycleSortPlayScreen({
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
  // ĐỔI TÊN STATE
  State<RecycleSortPlayScreen> createState() => _RecycleSortPlayScreenState();
}

// ĐỔI TÊN STATE
class _RecycleSortPlayScreenState extends State<RecycleSortPlayScreen> {
  static const int _totalRounds = 10;

  late List<TrashItem> _pool;
  late List<TrashItem> _deck;
  int _index = 0;
  int _correct = 0;
  int _wrong = 0;

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
      // Hữu cơ
      TrashItem('apple', 'Vỏ táo', '🍎', TrashType.organic),
      TrashItem('banana', 'Vỏ chuối', '🍌', TrashType.organic),
      TrashItem('bone', 'Xương gà', '🍗', TrashType.organic),
      TrashItem('veggie', 'Rau thừa', '🥬', TrashType.organic),
      TrashItem('coffee', 'Bã cà phê', '☕', TrashType.organic),
      TrashItem('egg', 'Vỏ trứng', '🥚', TrashType.organic),
      TrashItem('bread', 'Bánh thừa', '🥖', TrashType.organic),
      TrashItem('tissue', 'Giấy ăn', '🧻', TrashType.organic),
      // Vô cơ
      TrashItem('bottle', 'Chai nhựa', '🥤', TrashType.inorganic),
      TrashItem('can', 'Lon kim loại', '🥫', TrashType.inorganic),
      TrashItem('nylon', 'Túi nylon', '🛍️', TrashType.inorganic),
      TrashItem('foam', 'Hộp xốp', '📦', TrashType.inorganic),
      TrashItem('battery', 'Pin hỏng', '🔋', TrashType.inorganic),
      TrashItem('bulb', 'Bóng đèn', '💡', TrashType.inorganic),
      TrashItem('glass', 'Thuỷ tinh vỡ', '🧪', TrashType.inorganic),
      TrashItem('straw', 'Ống hút nhựa', '🧋', TrashType.inorganic),
    ];
  }

  int _durationByDifficulty() {
    final d = widget.game.difficulty; // 1/2/3
    if (d == 1) return 60;
    if (d == 2) return 45;
    return 30;
  }

  void _setupDeckAndState() {
    if (widget.initialDeck != null &&
        widget.initialIndex != null &&
        widget.initialCorrect != null &&
        widget.initialWrong != null &&
        widget.initialTimeLeft != null) {
      _deck = widget.initialDeck!
          .map((id) => _pool.firstWhere((e) => e.id == id))
          .toList();

      _index = widget.initialIndex!.clamp(0, _deck.isEmpty ? 0 : _deck.length - 1);
      _correct = widget.initialCorrect!;
      _wrong = widget.initialWrong!;
      _timeLeft = max(0, widget.initialTimeLeft!);

      if (_timeLeft <= 0 || widget.initialIndex! >= _deck.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      }
    } else {
      final all = List<TrashItem>.from(_pool)..shuffle(Random());
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

  void _togglePause() {
    setState(() => _paused = !_paused);
  }

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

  void _handleAnswer(TrashType dropTo) {
    final item = _deck[_index];
    final isRight = (item.type == dropTo);
    setState(() {
      if (isRight) { _correct++; _flashCorrect = true; }
      else { _wrong++; _flashWrong = true; }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() { _flashCorrect = false; _flashWrong = false; });
    });
    _nextRound();
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final item = _deck[_index];
    final difficultyLabel = switch (widget.game.difficulty) { 1=>'Dễ', 2=>'Vừa', _=>'Khó' };
    final score = _correct * 20 - _wrong * 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân loại rác thải'),
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
        child: SingleChildScrollView(  // Wrap with SingleChildScrollView
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Wrap(
                      spacing: 8, runSpacing: 8, children: [
                      _chip(
                        icon: Icons.timer,
                        label: _paused ? 'TẠM DỪNG' : '$_timeLeft giây',
                        color: _paused ? Colors.orange : (_timeLeft <= 5 ? Colors.red : Colors.blue),
                      ),
                      _chip(icon: Icons.eco, label: 'Môi trường', color: Colors.green),
                      _chip(icon: Icons.school, label: difficultyLabel, color: Colors.purple),
                      _chip(icon: Icons.flag, label: 'Vòng: ${_index + 1}/$_totalRounds', color: Colors.teal),
                      _chip(icon: Icons.stars, label: 'Điểm: $score', color: Colors.orange),
                    ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Kéo vật phẩm vào thùng phù hợp',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF8B5E00))),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: IgnorePointer(
                        ignoring: _paused,
                        child: Draggable<TrashItem>(
                          data: item,
                          feedback: _trashCard(item, dragging: true),
                          childWhenDragging: Opacity(opacity: .35, child: _trashCard(item)),
                          child: _trashCard(item),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(child: _binTarget(
                          type: TrashType.organic, label: 'Hữu cơ', color: const Color(0xFF2E7D32),
                          onAccept: () => !_paused ? _handleAnswer(TrashType.organic) : null,
                        )),
                        Expanded(child: _binTarget(
                          type: TrashType.inorganic, label: 'Vô cơ', color: const Color(0xFF424242),
                          onAccept: () => !_paused ? _handleAnswer(TrashType.inorganic) : null,
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: _paused ? null : _skip, child: const Text('Câu mới'))),
                        const SizedBox(width: 12),
                        Expanded(child: FilledButton.icon(icon: const Icon(Icons.flag), label: const Text('Kết thúc'), onPressed: _finish)),
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
                    child: Icon(_flashCorrect ? Icons.check_circle : Icons.cancel,
                        size: 120, color: _flashCorrect ? Colors.green : Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip({required IconData icon, required String label, required Color color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(.10),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: color.withOpacity(.35)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _trashCard(TrashItem item, {bool dragging = false}) => Card(
    color: dragging ? Colors.amber[50] : Colors.white,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(item.emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Widget _binTarget({
    required TrashType type,
    required String label,
    required Color color,
    required VoidCallback? onAccept,
  }) {
    bool hovering = false;
    return StatefulBuilder(
      builder: (_, setS) => DragTarget<TrashItem>(
        onWillAccept: (_) { setS(() => hovering = true); return true; },
        onLeave: (_) => setS(() => hovering = false),
        onAccept: (_) { setS(() => hovering = false); if (onAccept != null) onAccept(); },
        builder: (_, __, ___) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(16),
          height: 140,
          decoration: BoxDecoration(
            color: hovering ? color.withOpacity(.12) : color.withOpacity(.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: hovering ? color : color.withOpacity(.35), width: hovering ? 3 : 2),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.delete, size: 48, color: color),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
        ),
      ),
    );
  }
}
