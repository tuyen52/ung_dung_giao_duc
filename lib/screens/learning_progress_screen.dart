import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

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
      return Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập', style: GoogleFonts.quicksand()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tiến Độ Học',
          style: GoogleFonts.quicksand(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFBA68C8),
                Color(0xFF8EC5FC),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFBA68C8),
              Color(0xFF8EC5FC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: _TrePicker(
                parentUid: user.uid,
                selectedTreId: _selectedTreId,
                onChanged: (id) => setState(() => _selectedTreId = id),
              ),
            ),
            const Divider(height: 0, color: Colors.white54),
            Expanded(
              child: _selectedTreId == null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Hãy chọn một hồ sơ trẻ để xem tiến độ.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
                  : _GameProgressList(treId: _selectedTreId!),
            ),
          ],
        ),
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
          return const LinearProgressIndicator(minHeight: 2, color: Colors.white);
        }
        final list = snap.data ?? const <Tre>[];
        if (list.isEmpty) {
          return Text(
            'Chưa có hồ sơ trẻ.',
            style: GoogleFonts.quicksand(color: Colors.white),
          );
        }

        final value = selectedTreId ?? list.first.id;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.child_care_rounded, color: const Color(0xFFBA68C8), size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: value,
                    items: [
                      for (final t in list)
                        DropdownMenuItem(
                          value: t.id,
                          child: Text(
                            t.hoTen.isEmpty ? 'Bé' : t.hoTen,
                            style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Chọn hồ sơ trẻ',
                      hintStyle: GoogleFonts.quicksand(color: Colors.grey),
                    ),
                    style: GoogleFonts.quicksand(color: Colors.black),
                    dropdownColor: Colors.white,
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

class _GameProgressList extends StatelessWidget {
  const _GameProgressList({required this.treId});
  final String treId;

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('plays/$treId');

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snap.hasData || snap.data!.snapshot.value == null) {
          return Center(
            child: Text(
              'Chưa có dữ liệu tiến độ cho bé này.',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          );
        }

        final raw = Map<String, dynamic>.from(
          snap.data!.snapshot.value as Map,
        );

        final plays = raw.values
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .toList();

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
          return Center(
            child: Text(
              'Chưa có dữ liệu tiến độ cho bé này.',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemBuilder: (_, i) => _GameProgressCard(agg: games[i]),
          separatorBuilder: (_, __) => const SizedBox(height: 16),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            agg.gameName,
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: const Color(0xFF6A1B9A),
            ),
          ),
          const SizedBox(height: 12),
          _row('Hoàn thành', '${agg.count} phiên • ${agg.totalQuestions} câu', Icons.sports_esports_outlined),
          _row('Tiến độ', 'Đúng ${agg.totalCorrect} • Sai ${agg.totalWrong}', Icons.poll_outlined),
          _row('Tổng điểm', agg.totalScore.toString(), Icons.score),
        ]),
      ),
    );
  }

  Widget _row(String k, String v, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: Text(k, style: GoogleFonts.quicksand(color: Colors.grey[700])),
        ),
        Expanded(
          flex: 6,
          child: Text(
            v,
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}