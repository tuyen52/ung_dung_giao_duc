import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/tre.dart';
import '../services/tre_service.dart';

class LearningProgressScreen extends StatefulWidget {
  const LearningProgressScreen({super.key});

  @override
  State<LearningProgressScreen> createState() => _LearningProgressScreenState();
}

class _LearningProgressScreenState extends State<LearningProgressScreen> {
  String? _selectedTreId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tiến Độ Học')),
      body: Column(
        children: [
          // -------- Chọn Trẻ --------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _TrePicker(
              parentUid: user.uid,
              selectedTreId: _selectedTreId,
              onChanged: (id) => setState(() => _selectedTreId = id),
            ),
          ),
          const Divider(height: 0),
          // -------- Danh sách tiến độ --------
          Expanded(
            child: _selectedTreId == null
                ? const Center(child: Text('Hãy chọn một hồ sơ trẻ để xem tiến độ.'))
                : _GameProgressList(treId: _selectedTreId!),
          ),
        ],
      ),
    );
  }
}

class _TrePicker extends StatelessWidget {
  const _TrePicker({
    required this.parentUid,
    required this.selectedTreId,
    required this.onChanged,
  });

  final String parentUid;
  final String? selectedTreId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tre>>(
      stream: TreService().watchTreList(parentUid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        final list = snap.data ?? const <Tre>[];
        if (list.isEmpty) return const Text('Chưa có hồ sơ trẻ.');

        // Nếu chưa chọn, mặc định chọn phần tử đầu.
        final value = selectedTreId ?? list.first.id;

        return Row(
          children: [
            const Text('Trẻ:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: value,
                items: [
                  for (final t in list)
                    DropdownMenuItem(
                      value: t.id,
                      child: Text(t.hoTen.isEmpty ? 'Bé' : t.hoTen),
                    ),
                ],
                onChanged: onChanged,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ĐỌC từ `plays/{treId}` theo đúng cấu trúc bạn đang có
class _GameProgressList extends StatelessWidget {
  const _GameProgressList({required this.treId});
  final String treId;

  @override
  Widget build(BuildContext context) {
    // 🔁 đổi ref: plays/{treId}
    final ref = FirebaseDatabase.instance.ref('plays/$treId');

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.snapshot.value == null) {
          return const Center(child: Text('Chưa có dữ liệu tiến độ.'));
        }

        final raw = Map<String, dynamic>.from(
          snap.data!.snapshot.value as Map,
        );

        // playId -> Map
        final plays = raw.values
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        // Gom theo gameId (vì bạn có thể có nhiều game sau này)
        final Map<String, _GameAgg> byGame = {};
        for (final p in plays) {
          final id = (p['gameId'] ?? 'unknown') as String;
          final name = (p['gameName'] ?? 'Game') as String;
          final correct = (p['correct'] ?? 0) as int;
          final wrong = (p['wrong'] ?? 0) as int;
          final score = (p['score'] ?? (correct * 20 - wrong * 10)) as int;

          final g = byGame.putIfAbsent(id, () => _GameAgg(gameId: id, gameName: name));
          g.count += 1;
          g.totalCorrect += correct;
          g.totalWrong += wrong;
          g.totalScore += score;
        }

        final games = byGame.values.toList()
          ..sort((a, b) => a.gameName.compareTo(b.gameName));

        if (games.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu tiến độ.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => _GameProgressCard(agg: games[i]),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: games.length,
        );
      },
    );
  }
}

class _GameAgg {
  _GameAgg({required this.gameId, required this.gameName});
  final String gameId;
  final String gameName;

  int count = 0;
  int totalCorrect = 0;
  int totalWrong = 0;
  int totalScore = 0;

  int get totalQuestions => totalCorrect + totalWrong;
}

class _GameProgressCard extends StatelessWidget {
  const _GameProgressCard({required this.agg});
  final _GameAgg agg;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(agg.gameName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          _row('Hoàn thành', '${agg.count} phiên • ${agg.totalQuestions} câu'),
          _row('Tiến độ', 'Đúng ${agg.totalCorrect} • Sai ${agg.totalWrong}'),
          _row('Tổng điểm', agg.totalScore.toString()),
        ]),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text(k)),
            Expanded(
              flex: 6,
              child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
