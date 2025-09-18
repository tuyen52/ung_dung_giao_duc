import 'package:firebase_database/firebase_database.dart';
import '../models/play_record.dart';
import 'reward_service.dart';

class GameSessionService {
  final _db = FirebaseDatabase.instance;

  /// Lưu ván chơi dưới /plays/<treId>/<sessionId>
  /// Đồng thời cộng điểm vào Reward.
  Future<String> saveAndReward({
    required String treId,
    required String gameId,
    required String gameName,
    required String difficulty,
    required int correct,
    required int wrong,
    bool floorAtZero = true, // nếu muốn không âm điểm
  }) async {
    final scoreRaw = (correct * 20) - (wrong * 10);
    final score = floorAtZero ? (scoreRaw < 0 ? 0 : scoreRaw) : scoreRaw;

    final ref = _db.ref('plays').child(treId).push();
    final rec = PlayRecord(
      id: ref.key!,
      treId: treId,
      gameId: gameId,
      gameName: gameName,
      difficulty: difficulty,
      correct: correct,
      wrong: wrong,
      score: score,
      createdAt: DateTime.now(),
    );
    await ref.set(rec.toMap());

    // Cộng điểm thưởng
    await RewardService().addPoints(treId, score);

    return rec.id;
  }

  /// Lấy danh sách ván chơi của 1 bé (để thống kê)
  Stream<List<PlayRecord>> watchByTre(String treId) {
    final ref = _db.ref('plays').child(treId);
    return ref.onValue.map((e) {
      final v = e.snapshot.value;
      if (v == null) return <PlayRecord>[];
      final map = Map<String, dynamic>.from(v as Map);
      return map.entries.map((it) {
        final m = Map<String, dynamic>.from(it.value as Map);
        return PlayRecord.fromMap(m);
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }
}
