import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class PestCatchMiniGameResult {
  final double score0to1;
  final int elapsedMs;
  const PestCatchMiniGameResult({required this.score0to1, required this.elapsedMs});
}

class PestCatchMinigamePage extends StatefulWidget {
  final int durationSec;
  final int bugs; // số bọ

  const PestCatchMinigamePage({
    super.key,
    this.durationSec = 20,
    this.bugs = 10,
  });

  @override
  State<PestCatchMinigamePage> createState() => _PestCatchMinigamePageState();
}

class _Bug {
  Offset p;
  Offset v;
  final bool isLadyBug; // ✅ loại bọ cố định khi spawn
  bool caught = false;
  _Bug(this.p, this.v, {required this.isLadyBug});
}

class _PestCatchMinigamePageState extends State<PestCatchMinigamePage> {
  final math.Random _rng = math.Random();
  late Timer _timer;
  late DateTime _lastTick;          // ✅ thời điểm frame trước
  final DateTime _firstTickStart = DateTime.now();

  int _left = 0;
  final List<_Bug> _bugs = [];
  Size _playSize = Size.zero;
  int _caught = 0;

  static const double _radius = 24;

  @override
  void initState() {
    super.initState();
    _lastTick = DateTime.now();
    _left = widget.durationSec;
    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _spawnBugs(Size size) {
    _bugs.clear();
    for (int i = 0; i < widget.bugs; i++) {
      final p = Offset(
        _rng.nextDouble() * (size.width - 2 * _radius) + _radius,
        _rng.nextDouble() * (size.height - 2 * _radius) + _radius,
      );
      // tốc độ ngẫu nhiên
      final speed = 60 + _rng.nextDouble() * 90;
      final angle = _rng.nextDouble() * math.pi * 2;
      final v = Offset(math.cos(angle), math.sin(angle)) * speed;

      // ✅ ấn định loại bọ ngay khi spawn (không random trong build nữa)
      final isLady = _rng.nextBool();
      _bugs.add(_Bug(p, v, isLadyBug: isLady));
    }
  }

  void _tick(Timer t) {
    final now = DateTime.now();
    final dtSec = now.difference(_lastTick).inMilliseconds / 1000.0;
    _lastTick = now;

    // Spawn sau khi biết kích thước sân
    if (_playSize != Size.zero && _bugs.isEmpty) {
      _spawnBugs(_playSize);
    }

    // Cập nhật vật lý
    for (final b in _bugs) {
      if (b.caught) continue;
      Offset np = b.p + b.v * dtSec;
      // Va vào biên thì nẩy
      if (np.dx < _radius || np.dx > _playSize.width - _radius) {
        b.v = Offset(-b.v.dx, b.v.dy);
        np = Offset(np.dx.clamp(_radius, _playSize.width - _radius), np.dy);
      }
      if (np.dy < _radius || np.dy > _playSize.height - _radius) {
        b.v = Offset(b.v.dx, -b.v.dy);
        np = Offset(np.dx, np.dy.clamp(_radius, _playSize.height - _radius));
      }
      b.p = np;
    }

    // Cập nhật thời gian còn lại
    setState(() {
      _left = (_leftFromStart()).clamp(0, widget.durationSec);
    });
    if (_left <= 0 || _caught >= widget.bugs) {
      _finish();
    }
  }

  int _leftFromStart() {
    final elapsed = DateTime.now().difference(_firstTickStart).inSeconds;
    return (widget.durationSec - elapsed);
    // Nếu muốn không đếm giờ như minigame ánh sáng bản mới:
    // return widget.durationSec; // và bỏ hết logic kết thúc theo thời gian
  }

  void _finish() {
    if (_timer.isActive) _timer.cancel();
    final elapsedMs = DateTime.now().difference(_firstTickStart).inMilliseconds;
    final score = (_caught / widget.bugs).clamp(0.0, 1.0);
    Navigator.pop(context, PestCatchMiniGameResult(score0to1: score, elapsedMs: elapsedMs));
  }

  void _tapDown(TapDownDetails d) {
    final pos = d.localPosition;
    for (final b in _bugs) {
      if (b.caught) continue;
      if ((b.p - pos).distance <= _radius + 6) {
        setState(() {
          b.caught = true;
          _caught++;
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    const Spacer(),
                    _TimerPill(secondsLeft: _left),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('Bắt những chú sâu nghịch ngợm!',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),

              // Sân chơi
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) {
                    final newSize = Size(c.maxWidth, c.maxHeight);
                    // Spawn đúng 1 lần sau khi có size
                    if (_playSize == Size.zero) {
                      _playSize = newSize;
                      // Nếu muốn spawn ngay không chờ tick:
                      if (_bugs.isEmpty) _spawnBugs(_playSize);
                    } else {
                      _playSize = newSize;
                    }

                    return GestureDetector(
                      onTapDown: _tapDown,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Bãi cỏ
                          const RepaintBoundary(child: CustomPaint(painter: _GrassPainter())),

                          // Bọ
                          ..._bugs.map((b) => Positioned(
                            left: b.p.dx - _radius,
                            top: b.p.dy - _radius,
                            width: _radius * 2,
                            height: _radius * 2,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 120),
                              scale: b.caught ? 0.0 : 1.0,
                              child: Opacity(
                                opacity: b.caught ? 0.2 : 1.0,
                                // ✅ không random trong build; cố định theo bug
                                child: const RepaintBoundary(
                                  child: _BugSpriteWrapper(),
                                ),
                              ),
                            ),
                          )),

                          // Điểm
                          Positioned(
                            right: 10, top: 10,
                            child: _ScoreBadge(caught: _caught, total: widget.bugs),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TextButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Xong'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Để giữ emoji không đổi giữa các frame, chúng ta không random trong build.
/// Nếu vẫn muốn 2 loại bọ khác nhau, có 2 cách:
/// - Cách A (đơn giản): 1 kiểu sprite duy nhất (🐞) dùng cho mọi bug.
/// - Cách B (mỗi con cố định kiểu riêng): thêm `isLadyBug` vào _Bug (đã làm ở trên),
///   và vẽ theo cờ đó. Ở đây dùng A cho ổn định hoàn toàn.
class _BugSpriteWrapper extends StatelessWidget {
  const _BugSpriteWrapper();
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('🐞', style: const TextStyle(fontSize: 28)));
  }
}

class _ScoreBadge extends StatelessWidget {
  final int caught;
  final int total;
  const _ScoreBadge({required this.caught, required this.total});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Row(children: [
        const Icon(Icons.bug_report, size: 18),
        const SizedBox(width: 6),
        Text('$caught/$total', style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final int secondsLeft;
  const _TimerPill({required this.secondsLeft});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Row(children: [
        const Icon(Icons.timer, size: 18),
        const SizedBox(width: 6),
        Text('${secondsLeft}s', style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _GrassPainter extends CustomPainter {
  const _GrassPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFC8E6C9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      bg,
    );
    final blades = Paint()..color = const Color(0xFF81C784);
    for (double x = 0; x < size.width; x += 16) {
      final h = 10 + math.Random(x.toInt()).nextInt(18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h.toDouble(), 10, h.toDouble()),
          const Radius.circular(4),
        ),
        blades,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
