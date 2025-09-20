import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PruneMiniGameResult {
  final double score0to1;
  const PruneMiniGameResult({required this.score0to1});
}

/// Mini-game TỈA CÀNH – “Cắt ngay trên mắt lá ~1cm”
/// Bố cục thay đổi mỗi ngày nhờ daySeed (ổn định trong ngày).
class PruneMinigamePage extends StatefulWidget {
  final int durationSec; // không dùng, giữ để tương thích
  final int branches;    // số “bài”/cành cần xử lý
  final int? daySeed;    // ✅ seed theo NGÀY để bố cục ổn định trong ngày

  const PruneMinigamePage({
    super.key,
    this.durationSec = 20,
    this.branches = 6,
    this.daySeed,
  });

  @override
  State<PruneMinigamePage> createState() => _PruneMinigamePageState();
}

class _Task {
  final Offset a;        // đầu cành (gần thân)
  final Offset b;        // ngọn cành
  final double budT;     // vị trí “mắt lá” dọc theo cành (0..1)
  final double targetT;  // vị trí cắt chuẩn = budT + offset (0..1)
  final double tolT;     // dung sai (± theo t)
  _Task({
    required this.a,
    required this.b,
    required this.budT,
    required this.targetT,
    required this.tolT,
  });
}

class _PruneMinigamePageState extends State<PruneMinigamePage>
    with SingleTickerProviderStateMixin {

  late final math.Random _rng; // ✅ seed theo ngày
  final List<_Task> _tasks = [];
  int _idx = 0;                 // đang ở cành thứ mấy
  double _cutT = 0.5;           // vị trí kéo hiện tại dọc theo cành (0..1)
  int _correct = 0;
  int _wrong   = 0;
  bool _showFlash = false;      // hiệu ứng nháy khi chấm điểm

  late final AnimationController _pulse =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    // Nếu không truyền daySeed, vẫn hoạt động nhưng không ổn định trong ngày
    _rng = math.Random(widget.daySeed ?? DateTime.now().millisecondsSinceEpoch);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // Tạo danh sách cành dựa theo kích thước sân chơi (theo _rng đã seed)
  void _spawn(Size size) {
    _tasks.clear();

    final cx = size.width * 0.5;               // thân cây “ảo”
    final topY = size.height * 0.22;
    final botY = size.height * 0.78;

    for (int i = 0; i < widget.branches; i++) {
      final y = _lerp(botY, topY, _rng.nextDouble()); // vị trí dọc
      final side = _rng.nextBool() ? 1.0 : -1.0;
      final len = 140 + _rng.nextDouble() * 140;      // độ dài cành
      final angDeg = 15 + _rng.nextDouble() * 35;     // góc 15..50°
      final ang = (angDeg * math.pi / 180) * side;

      final a = Offset(cx, y);
      final b = a + Offset(math.cos(ang) * len, math.sin(ang) * len);

      // Mỗi ngày mắt lá và dung sai cũng khác nhẹ, nhưng luôn trong biên giáo dục an toàn
      final budT   = _lerp(0.55, 0.85, _rng.nextDouble()); // vị trí mắt lá
      final offset = 0.035 + _rng.nextDouble() * 0.015;    // ~3.5%..5% chiều dài (≈ “~1cm”)
      final tol    = 0.025 + _rng.nextDouble() * 0.01;     // ±2.5%..3.5% chiều dài

      final targetT = (budT + offset).clamp(0.0, 1.0);
      final tolT    = tol.clamp(0.02, 0.05);

      _tasks.add(_Task(a: a, b: b, budT: budT, targetT: targetT, tolT: tolT));
    }

    _idx = 0;
    _cutT = 0.5;
    _correct = 0;
    _wrong = 0;
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  // Chiếu 1 điểm P lên đoạn AB để lấy tham số t (0..1)
  double _projectT(Offset a, Offset b, Offset p) {
    final ab = b - a;
    final l2 = ab.distanceSquared;
    if (l2 == 0) return 0.0;
    final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / l2).clamp(0.0, 1.0);
    return t;
  }

  void _onPanUpdate(DragUpdateDetails d, _Task task) {
    final t = _projectT(task.a, task.b, d.localPosition);
    setState(() => _cutT = t);
  }

  Future<void> _onCut(_Task task) async {
    final hit = ( _cutT - task.targetT ).abs() <= task.tolT;
    if (hit) {
      _correct++;
      HapticFeedback.selectionClick();
    } else {
      _wrong++;
      HapticFeedback.lightImpact();
    }
    setState(() => _showFlash = true);
    await Future.delayed(const Duration(milliseconds: 280));
    setState(() => _showFlash = false);

    if (_idx < _tasks.length - 1) {
      setState(() {
        _idx++;
        _cutT = 0.5; // reset kéo ở giữa cành mới
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    // điểm = số cành cắt đúng / tổng cành
    final score = (_correct / (_tasks.isEmpty ? 1 : _tasks.length)).clamp(0.0, 1.0);
    Navigator.pop(context, PruneMiniGameResult(score0to1: score));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    const Spacer(),
                    _Badge(icon: Icons.check, text: 'Đúng: $_correct'),
                    const SizedBox(width: 10),
                    _Badge(icon: Icons.close, text: 'Sai: $_wrong'),
                  ],
                ),
              ),
              Text('Kéo ✂️ đến NGAY TRÊN mắt lá ~1cm rồi bấm CẮT',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const _LegendRow(),
              const SizedBox(height: 8),

              // Sân chơi
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) {
                    final size = Size(c.maxWidth, c.maxHeight);
                    if (_tasks.isEmpty) _spawn(size);

                    final task = _tasks[_idx];
                    return GestureDetector(
                      onPanUpdate: (d) => _onPanUpdate(d, task),
                      child: CustomPaint(
                        painter: _PrunePainter(
                          size: size,
                          task: task,
                          cutT: _cutT,
                          pulse: _pulse,
                          flash: _showFlash,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    );
                  },
                ),
              ),

              // Chỉ mục cành & nút
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Badge(icon: Icons.local_florist, text: 'Cành ${_idx + 1}/${_tasks.length}'),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _onCut(_tasks[_idx]),
                      icon: const Icon(Icons.content_cut),
                      label: const Text('CẮT'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== VẼ ===================

class _PrunePainter extends CustomPainter {
  final Size size;
  final _Task task;
  final double cutT;             // 0..1
  final Animation<double> pulse; // nhịp vùng vàng
  final bool flash;              // nháy khi chấm điểm

  _PrunePainter({
    required this.size,
    required this.task,
    required this.cutT,
    required this.pulse,
    required this.flash,
  }) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size sz) {
    // Thân cây mờ phía sau
    final trunkX = sz.width * .5;
    final trunkPaint = Paint()
      ..color = const Color(0xFF8D6E63).withOpacity(0.6)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(trunkX, sz.height - 20),
      Offset(trunkX, sz.height * .22),
      trunkPaint,
    );

    // Cành hiện tại
    final branchPaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(task.a, task.b, branchPaint);

    // Mắt lá (nụ) – chấm xanh ở vị trí budT
    final bud = Offset(
      task.a.dx + (task.b.dx - task.a.dx) * task.budT,
      task.a.dy + (task.b.dy - task.a.dy) * task.budT,
    );
    final leaf = Paint()..color = const Color(0xFF66BB6A);
    canvas.drawCircle(bud, 8, leaf);

    // Vùng vàng = dải mỏng quanh vị trí cắt chuẩn (targetT)
    final target = Offset(
      task.a.dx + (task.b.dx - task.a.dx) * task.targetT,
      task.a.dy + (task.b.dy - task.a.dy) * task.targetT,
    );
    final dir = (task.b - task.a);
    final len = dir.distance;
    final n = Offset(-dir.dy, dir.dx) / (len == 0 ? 1 : len); // pháp tuyến đơn vị
    final bandW = 40.0; // bề rộng dải vàng theo phương vuông góc
    final bandHalf = bandW / 2;

    final alpha = (0.18 + 0.12 * pulse.value);
    final bandPaint = Paint()..color = Colors.amber.withOpacity(alpha);
    final outline = Paint()
      ..color = Colors.amber.shade700.withOpacity(0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Tạo 1 “hình chữ nhật” mỏng vuông góc với cành tại vị trí target
    final p1 = target + n * bandHalf;
    final p2 = target - n * bandHalf;
    final tTol = task.tolT * len; // px dung sai theo chiều dọc cành
    final q1 = p1 + dir / len * tTol;
    final q2 = p2 + dir / len * tTol;
    final r1 = p1 - dir / len * tTol;
    final r2 = p2 - dir / len * tTol;

    final path = Path()
      ..moveTo(r1.dx, r1.dy)
      ..lineTo(q1.dx, q1.dy)
      ..lineTo(q2.dx, q2.dy)
      ..lineTo(r2.dx, r2.dy)
      ..close();
    canvas.drawPath(path, bandPaint);
    canvas.drawPath(path, outline);

    // Kéo ✂️ tại vị trí cutT
    final cutPos = Offset(
      task.a.dx + (task.b.dx - task.a.dx) * cutT,
      task.a.dy + (task.b.dy - task.a.dy) * cutT,
    );
    // Vẽ đường cắt vuông góc với cành
    final scissorLen = 52.0;
    final s1 = cutPos + n * scissorLen / 2;
    final s2 = cutPos - n * scissorLen / 2;
    final cutLine = Paint()
      ..color = flash ? Colors.green : Colors.black54
      ..strokeWidth = 2.5;
    canvas.drawLine(s1, s2, cutLine);

    // Icon ✂️ tại vị trí cắt
    final tp = TextPainter(
      text: const TextSpan(text: '✂️', style: TextStyle(fontSize: 22)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, cutPos.translate(-10, -10));

    // Nhãn gợi ý
    final hint = TextPainter(
      text: const TextSpan(
        text: 'Cắt NGAY TRÊN mắt lá',
        style: TextStyle(fontSize: 14, color: Colors.brown, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hint.paint(canvas, target + n * (bandHalf + 10) - const Offset(60, 10));
  }

  @override
  bool shouldRepaint(covariant _PrunePainter old) =>
      old.task != task || old.cutT != cutT || old.flash != flash;
}

// =================== WIDGET PHỤ ===================

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      children: const [
        _LegendChip(color: Color(0xFF66BB6A), label: 'Mắt lá'),
        _LegendChip(color: Colors.amber, label: 'Vùng cắt an toàn'),
        _LegendChip(color: Colors.black54, label: 'Đường kéo ✂️'),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Badge({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
