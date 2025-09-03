// lib/game/widgets/game_screen_wrapper.dart
import 'package:flutter/material.dart';
import 'package:mobileapp/services/audio_service.dart'; // THÊM: Import audio service
import 'game_pause_menu.dart';

class GameScreenWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, bool isPaused) builder;
  final String gameName;
  final VoidCallback onExit;
  final VoidCallback? onRestart;
  final VoidCallback? onHandbook;

  const GameScreenWrapper({
    super.key,
    required this.builder,
    required this.gameName,
    required this.onExit,
    this.onRestart,
    this.onHandbook,
  });

  @override
  State<GameScreenWrapper> createState() => _GameScreenWrapperState();
}

class _GameScreenWrapperState extends State<GameScreenWrapper> {
  bool _isPaused = false;
  final _audioService = AudioService.instance; // THÊM: Lấy instance của audio service

  @override
  void initState() {
    super.initState();
    // THÊM: Bắt đầu chơi nhạc nền khi vào game
    // Hãy thay 'audio/background_music.mp3' bằng đường dẫn file nhạc của bạn
    _audioService.playBgm('audio/background_music.mp3');
  }

  @override
  void dispose() {
    // THÊM: Dừng nhạc nền khi thoát khỏi màn hình game
    _audioService.stopBgm();
    super.dispose();
  }

  // SỬA: Cập nhật hàm _showSettings để hiển thị Dialog điều chỉnh âm lượng
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cài đặt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Âm lượng nhạc nền'),
            // Sử dụng ValueListenableBuilder để tự động cập nhật UI khi âm lượng thay đổi
            ValueListenableBuilder<double>(
              valueListenable: _audioService.volumeNotifier,
              builder: (context, volume, child) {
                return Slider(
                  value: volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: (volume * 100).toStringAsFixed(0),
                  onChanged: (newVolume) {
                    // Cập nhật âm lượng thông qua service
                    _audioService.volumeNotifier.value = newVolume;
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.gameName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.pause_circle_outline, color: Colors.white),
            tooltip: 'Tạm dừng',
            iconSize: 32,
            onPressed: () => setState(() => _isPaused = true),
          ),
        ],
      ),
      body: Stack(
        children: [
          widget.builder(context, _isPaused),
          if (_isPaused)
            GamePauseMenu(
              onResumed: () => setState(() => _isPaused = false),
              onRestart: () {
                setState(() => _isPaused = false);
                widget.onRestart?.call();
              },
              onSettings: _showSettings, // <-- Hành động đã được cập nhật
              onHandbook: widget.onHandbook,
              onExit: widget.onExit,
            ),
        ],
      ),
    );
  }
}