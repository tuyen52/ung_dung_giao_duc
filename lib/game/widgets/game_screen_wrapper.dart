// lib/game/widgets/game_screen_wrapper.dart
import 'package:flutter/material.dart';
import 'package:mobileapp/services/audio_service.dart';
import 'game_pause_menu.dart';

class GameScreenWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, bool isPaused) builder;
  final String gameName;
  final VoidCallback onFinishAndExit;
  final VoidCallback? onSaveAndExit;
  final VoidCallback? onRestart;
  final VoidCallback? onHandbook;



  const GameScreenWrapper({
    super.key,
    required this.builder,
    required this.gameName,
    required this.onFinishAndExit,
    this.onSaveAndExit,
    this.onRestart,
    this.onHandbook,
  });

  @override
  State<GameScreenWrapper> createState() => _GameScreenWrapperState();
}

class _GameScreenWrapperState extends State<GameScreenWrapper> {
  bool _isPaused = false;
  final _audioService = AudioService.instance;

  @override
  void initState() {
    super.initState();
    _audioService.playBgm('audio/background_music.mp3');
  }

  @override
  void dispose() {
    _audioService.stopBgm();
    super.dispose();
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận thoát'),
          content: const Text('Bạn muốn kết thúc ván chơi hay lưu lại để chơi sau?'),
          actions: <Widget>[
            if (widget.onSaveAndExit != null)
              TextButton(
                child: const Text('Lưu & Thoát'),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onSaveAndExit!();
                },
              ),
            TextButton(
              child: const Text('Thoát & Tổng kết'),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onFinishAndExit();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
            ValueListenableBuilder<double>(
              valueListenable: _audioService.volumeNotifier,
              builder: (context, volume, child) {
                return Slider(
                  value: volume,
                  onChanged: (newVolume) {
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
              onSettings: _showSettings,
              onHandbook: widget.onHandbook,
              onExit: _showExitConfirmationDialog,
            ),
        ],
      ),
    );
  }
}