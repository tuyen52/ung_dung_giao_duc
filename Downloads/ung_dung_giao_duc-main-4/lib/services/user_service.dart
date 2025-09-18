// lib/services/user_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Dịch vụ quản lý hồ sơ phụ huynh tại node `users/{uid}`
/// - API cũ (giữ nguyên): saveProfile, getProfile, watchProfile
/// - API mới: upsertProfile (merge một phần), updateProfileFields (patch),
///           updateAuthDisplayName (đồng bộ tên hiển thị của Auth)
class UserService {
  /// Cho phép truyền root khác để test; mặc định là 'users'
  UserService({DatabaseReference? root})
      : _db = root ?? FirebaseDatabase.instance.ref('users');

  final DatabaseReference _db;

  DatabaseReference _refOf(String uid) => _db.child(uid);

  // ---------------------------------------------------------------------------
  // API CŨ (giữ nguyên chữ ký)
  // ---------------------------------------------------------------------------

  /// Tạo/ghi đè toàn bộ hồ sơ (giống phiên bản cũ).
  /// Giữ createdAt dạng ISO để tương thích (createdAtIso),
  /// đồng thời thêm createdAt/updatedAt = ServerValue.timestamp.
  Future<void> saveProfile({
    required String uid,
    required String name,
    required String username,
    required String email,
    required String phone,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final ref = _refOf(uid);

    // Để tương thích tối đa với dữ liệu cũ:
    await ref.set({
      'id': uid,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      // cũ: giữ ISO
      'createdAt': nowIso,
      // mới: thêm mốc thời gian server
      'createdAtIso': nowIso,
      'createdAtServer': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    });
  }

  /// Lấy hồ sơ (Map) theo uid
  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final snap = await _refOf(uid).get();
    if (!snap.exists || snap.value == null) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  /// Lắng nghe realtime thay đổi hồ sơ
  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _refOf(uid).onValue.map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) return null;
      return Map<String, dynamic>.from(e.snapshot.value as Map);
    });
  }

  // ---------------------------------------------------------------------------
  // API MỚI (bổ sung)
  // ---------------------------------------------------------------------------

  /// Ghi/merge một phần hồ sơ. Chỉ trường nào truyền vào khác null mới được cập nhật.
  /// - Luôn cập nhật 'updatedAt' = ServerValue.timestamp
  /// - Nếu 'createdAtServer' chưa có thì chỉ set **một lần** (transaction)
  Future<void> upsertProfile({
    required String uid,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? address,
    Map<String, dynamic>? extra, // cho các trường mở rộng khác
  }) async {
    final ref = _refOf(uid);

    // map chỉ chứa các trường != null
    final patch = <String, dynamic>{
      if (name != null) 'name': name,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (extra != null) ...extra,
      'updatedAt': ServerValue.timestamp,
    };

    // merge trước
    await ref.update(patch);

    // đảm bảo tạo createdAtServer chỉ 1 lần
    await ref.child('createdAtServer').runTransaction((current) {
      if (current == null) {
        return Transaction.success(ServerValue.timestamp);
      }
      return Transaction.abort();
    });

    // nếu chưa có createdAtIso (tương thích dạng ISO), set 1 lần
    await ref.child('createdAtIso').runTransaction((current) {
      if (current == null) {
        return Transaction.success(DateTime.now().toIso8601String());
      }
      return Transaction.abort();
    });

    // nếu chưa có id, set uid (giữ tương thích với schema cũ)
    await ref.child('id').runTransaction((current) {
      if (current == null) {
        return Transaction.success(uid);
      }
      return Transaction.abort();
    });
  }

  /// Cập nhật các trường tuỳ ý (patch). Không đụng createdAt*, chỉ update updatedAt.
  Future<void> updateProfileFields(
      String uid,
      Map<String, dynamic> fields,
      ) async {
    if (fields.isEmpty) return;
    final ref = _refOf(uid);
    final patch = <String, dynamic>{...fields, 'updatedAt': ServerValue.timestamp};
    await ref.update(patch);
  }

  /// Đồng bộ tên hiển thị của FirebaseAuth (không đổi email ở đây vì cần re-auth).
  Future<void> updateAuthDisplayName(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
    }
  }

  /// Kiểm tra hồ sơ có tồn tại không
  Future<bool> exists(String uid) async {
    final s = await _refOf(uid).get();
    return s.exists && s.value != null;
  }
}