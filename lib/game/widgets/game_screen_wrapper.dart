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
  // THÊM: Tham số để nhận nội dung Sổ tay từ launcher
  final Widget? handbookContent;

  const GameScreenWrapper({
    super.key,
    required this.builder,
    required this.gameName,
    required this.onFinishAndExit,
    this.onSaveAndExit,
    this.onRestart,
    this.handbookContent,
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

  // Widget helper để tạo nút cho dialog, giữ nguyên
  Widget _buildDialogButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14.0),
      ),
    );
  }

  // HÀM MỚI: Hàm chung để hiển thị dialog với giao diện tùy chỉnh
  void _showCustomDialog({
    required String title,
    required Widget content,
    List<Widget> actions = const [],
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF2C3E50),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.blueAccent, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16.0),
                content,
                const SizedBox(height: 24.0),
                if (actions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: actions,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // CẬP NHẬT: Sử dụng hàm _showCustomDialog
  void _showExitConfirmationDialog() {
    _showCustomDialog(
      title: 'Xác nhận thoát',
      content: const Text(
        'Bạn muốn kết thúc ván chơi hay lưu lại để chơi sau?',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16.0, color: Colors.white70),
      ),
      actions: [
        if (widget.onSaveAndExit != null)
          _buildDialogButton(
            text: 'Lưu & Thoát',
            icon: Icons.save_alt_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSaveAndExit!();
            },
            backgroundColor: Colors.green,
          ),
        if (widget.onSaveAndExit != null) const SizedBox(height: 12),
        _buildDialogButton(
          text: 'Thoát & Tổng kết',
          icon: Icons.flag_rounded,
          onPressed: () {
            Navigator.of(context).pop();
            widget.onFinishAndExit();
          },
          backgroundColor: Colors.redAccent,
        ),
        const SizedBox(height: 12),
        _buildDialogButton(
          text: 'Hủy',
          icon: Icons.cancel_outlined,
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: Colors.grey.shade600,
        ),
      ],
    );
  }

  // CẬP NHẬT: Sử dụng hàm _showCustomDialog
  void _showSettings() {
    _showCustomDialog(
      title: 'Cài đặt',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Âm lượng nhạc nền',
              style: TextStyle(color: Colors.white70)),
          ValueListenableBuilder<double>(
            valueListenable: _audioService.volumeNotifier,
            builder: (context, volume, child) {
              return Slider(
                value: volume,
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.blueAccent.withOpacity(0.3),
                onChanged: (newVolume) {
                  _audioService.volumeNotifier.value = newVolume;
                },
              );
            },
          ),
        ],
      ),
      actions: [
        _buildDialogButton(
          text: 'Đóng',
          icon: Icons.check_circle_outline,
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: Colors.blueAccent,
        ),
      ],
    );
  }

  // HÀM MỚI: Dành riêng cho Sổ tay, sử dụng nội dung được truyền vào
  void _showHandbookDialog() {
    if (widget.handbookContent == null) return;
    _showCustomDialog(
      title: 'Hướng dẫn',
      content: widget.handbookContent!,
      actions: [
        _buildDialogButton(
          text: 'Đã hiểu',
          icon: Icons.thumb_up_alt_outlined,
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: Colors.blueAccent,
        ),
      ],
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
              // CẬP NHẬT: Kết nối với hàm hiển thị Sổ tay mới
              onHandbook:
              widget.handbookContent != null ? _showHandbookDialog : null,
              onExit: _showExitConfirmationDialog,
            ),
        ],
      ),
    );
  }
}