import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../plant_assets.dart'; // dùng cùng background với các mini-game khác

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
  Offset p;                // vị trí
  Offset v;                // vận tốc px/s
  bool caught = false;     // đã bắt chưa
  _Bug(this.p, this.v);
}

class _Ripple {
  Offset p;
  double age; // giây
  _Ripple(this.p, this.age);
}

class _Flash {
  Offset p;
  double age; // giây
  _Flash(this.p, this.age);
}

class _PestCatchMinigamePageState extends State<PestCatchMinigamePage> {
  final math.Random _rng = math.Random();
  late Timer _timer;
  late DateTime _lastTick;
  late DateTime _startAll;

  int _left = 0;
  final List<_Bug> _bugs = [];
  Size _playSize = Size.zero;
  int _caught = 0;

  // hiệu ứng
  final List<_Ripple> _ripples = [];
  final List<_Flash> _flashes = [];

  static const double _radius = 26; // tăng nhẹ cho thân thiện hơn
  static const double _rippleLife = 0.35;
  static const double _flashLife = 0.35;

  @override
  void initState() {
    super.initState();
    _startAll = DateTime.now();
    _lastTick = DateTime.now();
    _left = widget.durationSec;
    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // precache background để mượt
    precacheImage(const AssetImage(PlantAssets.bg), context);
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
      // tốc độ ngẫu nhiên, mượt vừa phải
      final speed = 60 + _rng.nextDouble() * 90;
      final angle = _rng.nextDouble() * math.pi * 2;
      final v = Offset(math.cos(angle), math.sin(angle)) * speed;
      _bugs.add(_Bug(p, v));
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

    // Cập nhật vật lý bọ
    for (final b in _bugs) {
      if (b.caught) continue;

      // thêm chút “lắc lư” để tự nhiên
      final jitter = Offset((_rng.nextDouble() - 0.5) * 20, (_rng.nextDouble() - 0.5) * 20);
      b.v += jitter * dtSec;

      Offset np = b.p + b.v * dtSec;
      // Va vào biên thì nảy
      if (np.dx < _radius || np.dx > _playSize.width - _radius) {
        b.v = Offset(-b.v.dx, b.v.dy);
        np = Offset(np.dx.clamp(_radius, _playSize.width - _radius), np.dy);
      }
      if (np.dy < _radius || np.dy > _playSize.height - _radius) {
        b.v = Offset(b.v.dx, -b.v.dy);
        np = Offset(np.dx, np.dy.clamp(_radius, _playSize.height - _radius));
      }
      // giới hạn tốc độ tối đa để không “bay” quá nhanh
      final maxSpd = 140.0;
      final spd = b.v.distance;
      if (spd > maxSpd) b.v = b.v * (maxSpd / spd);
      b.p = np;
    }

    // hiệu ứng ripple / flash
    for (final r in _ripples) {
      r.age += dtSec;
    }
    _ripples.removeWhere((r) => r.age >= _rippleLife);

    for (final f in _flashes) {
      f.age += dtSec;
    }
    _flashes.removeWhere((f) => f.age >= _flashLife);

    // Cập nhật thời gian còn lại
    _left = (_remaining()).clamp(0, widget.durationSec);
    if (_left <= 0 || _caught >= widget.bugs) {
      _finish();
      return;
    }
    if (mounted) setState(() {});
  }

  int _remaining() {
    final elapsed = DateTime.now().difference(_startAll).inSeconds;
    return (widget.durationSec - elapsed);
  }

  void _finish() {
    if (_timer.isActive) _timer.cancel();
    final elapsedMs = DateTime.now().difference(_startAll).inMilliseconds;
    final score = (_caught / widget.bugs).clamp(0.0, 1.0);
    Navigator.pop(context, PestCatchMiniGameResult(score0to1: score, elapsedMs: elapsedMs));
  }

  void _tapDown(TapDownDetails d) {
    final pos = d.localPosition;
    bool hit = false;

    for (final b in _bugs) {
      if (b.caught) continue;
      if ((b.p - pos).distance <= _radius + 6) {
        // bắt được
        b.caught = true;
        _caught++;
        _flashes.add(_Flash(b.p, 0));
        HapticFeedback.lightImpact();
        hit = true;
        break;
      }
    }

    _ripples.add(_Ripple(pos, 0));
    if (!hit) {
      HapticFeedback.selectionClick();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final progress = widget.bugs == 0 ? 0.0 : _caught / widget.bugs;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 👉 nền đồng bộ với các mini-game khác
          Image.asset(PlantAssets.bg, fit: BoxFit.cover),
          // overlay nhẹ để chữ/điều khiển nổi hơn
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.00), Colors.white.withOpacity(0.10)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _TimerPill(secondsLeft: _left),
                    ],
                  ),
                ),
                Text(
                  'Bắt những chú sâu nghịch ngợm!',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chạm để bắt — cố gắng bắt hết trước khi hết giờ.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 10),

                // Sân chơi
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: LayoutBuilder(
                        builder: (_, c) {
                          _playSize = Size(c.maxWidth, c.maxHeight);

                          // Spawn ngay khi có size (nếu chưa có)
                          if (_bugs.isEmpty && _playSize != Size.zero) {
                            _spawnBugs(_playSize);
                          }

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: _tapDown,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // nền bãi cỏ mờ mờ trong panel
                                const _GrassBackdrop(),

                                // bọ
                                ..._bugs.map((b) {
                                  return Positioned(
                                    left: b.p.dx - _radius,
                                    top: b.p.dy - _radius,
                                    width: _radius * 2,
                                    height: _radius * 2,
                                    child: AnimatedScale(
                                      duration: const Duration(milliseconds: 120),
                                      scale: b.caught ? 0.0 : 1.0,
                                      child: Opacity(
                                        opacity: b.caught ? 0.15 : 1.0,
                                        child: const _BugSprite(),
                                      ),
                                    ),
                                  );
                                }),

                                // ripples tap
                                Positioned.fill(
                                  child: CustomPaint(painter: _RipplePainter(_ripples)),
                                ),

                                // flash ✨ khi bắt
                                ..._flashes.map((f) {
                                  final t = (f.age / _flashLife).clamp(0.0, 1.0);
                                  final scale = 0.8 + 0.6 * (1 - t);
                                  final opacity = (1 - t);
                                  return Positioned(
                                    left: f.p.dx - 12,
                                    top: f.p.dy - 12,
                                    child: Opacity(
                                      opacity: opacity,
                                      child: Transform.scale(
                                        scale: scale,
                                        child: const Text('✨', style: TextStyle(fontSize: 24)),
                                      ),
                                    ),
                                  );
                                }),

                                // Huy hiệu điểm
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: _ScoreBadge(caught: _caught, total: widget.bugs),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Thanh tiến độ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ProgressBar(value: progress, label: 'Đã bắt: $_caught/${widget.bugs}'),
                ),

                // Nút Xong
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: _finish,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Xong'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================== UI phụ ==================

class _BugSprite extends StatelessWidget {
  const _BugSprite();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('🐞', style: TextStyle(fontSize: 28)));
  }
}

class _GrassBackdrop extends StatelessWidget {
  const _GrassBackdrop();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrassPainter(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
    );
  }
}

class _GrassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xAAE8F5E9);
    canvas.drawRect(Offset.zero & size, bg);

    final blades = Paint()..color = const Color(0xFF9CCC65).withOpacity(0.6);
    final rnd = math.Random(42);
    for (double x = 0; x < size.width; x += 14) {
      final h = 10 + rnd.nextInt(22);
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

class _RipplePainter extends CustomPainter {
  final List<_Ripple> ripples;
  _RipplePainter(this.ripples);

  @override
  void paint(Canvas canvas, Size size) {
    for (final r in ripples) {
      final t = (r.age / _PestCatchMinigamePageState._rippleLife).clamp(0.0, 1.0);
      final radius = 8 + 100 * t;
      final opacity = (1 - t);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.7 * opacity);
      canvas.drawCircle(r.p, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => true;
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

class _ProgressBar extends StatelessWidget {
  final double value;
  final String label;
  const _ProgressBar({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          LayoutBuilder(builder: (_, c) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: (c.maxWidth * value).clamp(0.0, c.maxWidth),
              height: 20,
              margin: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF81C784),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
          Center(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
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
