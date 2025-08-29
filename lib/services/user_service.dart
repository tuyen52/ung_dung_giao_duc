// lib/services/user_service.dart
import 'package:firebase_database/firebase_database.dart';

class UserService {
  final _db = FirebaseDatabase.instance.ref('users');

  Future<void> saveProfile({
    required String uid,
    required String name,
    required String username,
    required String email,
    required String phone,
  }) {
    return _db.child(uid).set({
      'id': uid,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final snap = await _db.child(uid).get();
    if (!snap.exists || snap.value == null) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  /// NEW: lắng nghe thay đổi hồ sơ theo thời gian thực
  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _db.child(uid).onValue.map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) return null;
      return Map<String, dynamic>.from(e.snapshot.value as Map);
    });
  }
}
