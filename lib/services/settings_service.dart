import 'package:shared_preferences/shared_preferences.dart';

/// Service để quản lý và lưu trữ cài đặt của ứng dụng.
class SettingsService {
  // Singleton pattern để đảm bảo chỉ có một instance của service
  SettingsService._();
  static final instance = SettingsService._();

  late final SharedPreferences _prefs;

  // Khởi tạo service, cần được gọi khi ứng dụng bắt đầu
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _keyShowHandbook = 'autoShowHandbookOnStart';

  /// Lấy cài đặt tự động hiển thị hướng dẫn.
  /// Mặc định là `true` nếu chưa có cài đặt.
  bool getAutoShowHandbook() {
    return _prefs.getBool(_keyShowHandbook) ?? true;
  }

  /// Lưu cài đặt tự động hiển thị hướng dẫn.
  Future<void> setAutoShowHandbook(bool value) async {
    await _prefs.setBool(_keyShowHandbook, value);
  }
}