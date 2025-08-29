import 'package:firebase_database/firebase_database.dart';
import '../game/game_progress.dart';

class GameProgressService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _ref(String treId, String gameId) =>
      _db.ref('progress').child(treId).child(gameId);

  Future<void> save(GameProgress p) async {
    await _ref(p.treId, p.gameId).set(p.toMap());
  }

  Future<GameProgress?> load(String treId, String gameId) async {
    final snap = await _ref(treId, gameId).get();
    if (!snap.exists || snap.value == null) return null;
    return GameProgress.fromMap(Map<String, dynamic>.from(snap.value as Map));
  }

  Future<void> clear(String treId, String gameId) async {
    await _ref(treId, gameId).remove();
  }
}
