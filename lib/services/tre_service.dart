import 'package:firebase_database/firebase_database.dart';
import '../models/tre.dart';

class TreService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference _refForParent(String parentId) =>
      _db.ref('tre').child(parentId);

  Stream<List<Tre>> watchTreList(String parentId) {
    final ref = _refForParent(parentId);
    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Tre>[];
      final map = Map<String, dynamic>.from(data as Map);
      return map.entries.map((e) {
        final child = Map<String, dynamic>.from(e.value as Map);
        return Tre.fromMap(child);
      }).toList();
    });
  }

  Future<String> addTre({
    required String parentId,
    required String hoTen,
    required String gioiTinh,
    required String ngaySinh,
    required String soThich,
  }) async {
    final ref = _refForParent(parentId).push();
    final tre = Tre(
      id: ref.key!,
      hoTen: hoTen,
      gioiTinh: gioiTinh,
      ngaySinh: ngaySinh,
      soThich: soThich,
      parentId: parentId,
    );
    await ref.set(tre.toMap());
    return tre.id;
  }

  Future<void> deleteTre({required String parentId, required String treId}) {
    return _refForParent(parentId).child(treId).remove();
  }

  Future<void> updateTre(Tre tre) async {
    await _refForParent(tre.parentId).child(tre.id).update(tre.toMap());
  }
}
