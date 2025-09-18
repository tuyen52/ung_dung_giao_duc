// lib/services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  // --- Singleton Pattern ---
  // Đảm bảo chỉ có một instance duy nhất của service này trong toàn bộ ứng dụng
  AudioService._privateConstructor();
  static final AudioService instance = AudioService._privateConstructor();
  // -------------------------

  final AudioPlayer _bgmPlayer = AudioPlayer();
  // ValueNotifier để giao diện có thể lắng nghe và cập nhật khi âm lượng thay đổi
  ValueNotifier<double> volumeNotifier = ValueNotifier<double>(0.5);

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    // Đặt chế độ lặp lại vô hạn cho nhạc nền
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    // Đặt âm lượng ban đầu
    await _bgmPlayer.setVolume(volumeNotifier.value);

    // Lắng nghe sự thay đổi âm lượng từ notifier để cập nhật player
    volumeNotifier.addListener(() {
      _bgmPlayer.setVolume(volumeNotifier.value);
    });
    _isInitialized = true;
  }

  /// Bắt đầu chơi nhạc nền từ một đường dẫn asset.
  /// Ví dụ: 'audio/bgm.mp3'
  Future<void> playBgm(String assetPath) async {
    // Khởi tạo nếu chưa
    await init();
    // Chỉ chạy nếu nhạc chưa phát
    if (_bgmPlayer.state != PlayerState.playing) {
      await _bgmPlayer.play(AssetSource(assetPath));
    }
  }

  /// Dừng nhạc nền
  Future<void> stopBgm() async {
    if (_bgmPlayer.state == PlayerState.playing) {
      await _bgmPlayer.stop();
    }
  }

  /// Dọn dẹp tài nguyên khi không cần nữa
  void dispose() {
    _bgmPlayer.dispose();
    volumeNotifier.dispose();
  }
}