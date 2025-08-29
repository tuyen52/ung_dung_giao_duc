import 'package:firebase_database/firebase_database.dart';
import '../models/reward.dart';

class RewardService {
  final _db = FirebaseDatabase.instance.ref('rewards');

  Stream<Reward?> watchReward(String treId) {
    final ref = _db.child(treId);
    return ref.onValue.map((e) {
      if (e.snapshot.value == null) return null;
      return Reward.fromMap(Map<String, dynamic>.from(e.snapshot.value as Map));
    });
  }

  Future<void> updateReward(Reward reward) async {
    await _db.child(reward.treId).set(reward.toMap());
  }

  Future<void> addPoints(String treId, int points) async {
    final ref = _db.child(treId);
    final snap = await ref.get();
    Reward current;
    if (snap.value != null) {
      current = Reward.fromMap(Map<String, dynamic>.from(snap.value as Map));
    } else {
      current = Reward(treId: treId);
    }

    final newPoints = current.points + points;

    // tính huy chương dựa theo điểm
    int gold = newPoints ~/ 100;
    int silver = (newPoints % 100) ~/ 50;
    int bronze = ((newPoints % 50) ~/ 10);

    final updated = current.copyWith(
      points: newPoints,
      gold: gold,
      silver: silver,
      bronze: bronze,
      lastUpdated: DateTime.now(),
    );
    await updateReward(updated);
  }
}

extension on Reward {
  Reward copyWith({
    int? points,
    int? gold,
    int? silver,
    int? bronze,
    DateTime? lastUpdated,
  }) {
    return Reward(
      treId: treId,
      points: points ?? this.points,
      gold: gold ?? this.gold,
      silver: silver ?? this.silver,
      bronze: bronze ?? this.bronze,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
