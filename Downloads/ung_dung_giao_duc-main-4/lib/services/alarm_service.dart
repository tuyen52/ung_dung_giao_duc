// lib/services/alarm_service.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  Timer? _ticker;
  DateTime? _target; // thời điểm báo
  GlobalKey<NavigatorState>? _navKey;
  VoidCallback? _logoutCallback; // callback để handle logout

  void attachNavigatorKey(GlobalKey<NavigatorState> key) {
    _navKey = key;
  }

  void setLogoutCallback(VoidCallback? callback) {
    _logoutCallback = callback;
  }

  /// Đặt báo tới TimeOfDay (hôm nay hoặc ngày mai nếu giờ đã qua)
  void scheduleDaily(TimeOfDay time) {
    _target = _nextDateTimeFor(time);
    _startTicker();
  }

  /// Hủy báo giờ
  void cancel() {
    _ticker?.cancel();
    _ticker = null;
    _target = null;
  }

  DateTime? get target => _target;

  // ==== private ====

  void _startTicker() {
    _ticker?.cancel();
    if (_target == null) return;

    // Tick mỗi giây cho mượt (có thể dùng mỗi 5s/10s nếu muốn tiết kiệm)
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_target == null) return;
      final now = DateTime.now();
      if (now.isAfter(_target!) || now.isAtSameMomentAs(_target!)) {
        _ticker?.cancel();

        // Thông báo + đăng xuất
        await _notifyAndLogout();
      }
    });
  }

  Future<void> _notifyAndLogout() async {
    final ctx = _navKey?.currentContext;

    if (ctx != null) {
      // Hiện thông báo ngắn
      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.access_time, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text('Hết thời gian'),
            ],
          ),
          content: const Text('Đã đến giờ giới hạn. Ứng dụng sẽ đăng xuất sau 3 giây.'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // đợi 3 giây cho user đọc
      await Future.delayed(const Duration(seconds: 3));

      // Đóng dialog trước khi navigate
      if (Navigator.of(ctx, rootNavigator: true).canPop()) {
        Navigator.of(ctx, rootNavigator: true).pop();
      }
    }

    // Sign out Firebase
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }

    // Gọi callback nếu có
    if (_logoutCallback != null) {
      _logoutCallback!();
    } else {
      // Fallback: dùng navigator key
      final nav = _navKey?.currentState;
      nav?.pushNamedAndRemoveUntil('/login', (route) => false);
    }

    // Reset target
    _target = null;
  }

  DateTime _nextDateTimeFor(TimeOfDay tod) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    if (today.isAfter(now)) return today;
    // đã qua -> ngày mai
    final tomorrow = today.add(const Duration(days: 1));
    return tomorrow;
  }
}