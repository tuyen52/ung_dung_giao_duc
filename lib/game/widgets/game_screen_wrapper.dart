import 'package:flutter/material.dart';
import 'package:mobileapp/services/audio_service.dart';
import 'game_pause_menu.dart';

class GameScreenWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, bool isPaused) builder;
  final String gameName;
  final VoidCallback onFinishAndExit;
  final VoidCallback? onSaveAndExit;
  final VoidCallback? onRestart;

  /// Nội dung "Hướng dẫn" (Sổ tay) — hiển thị bằng nút ? trên AppBar
  final Widget? handbookContent;

  /// Tự động hiện Hướng dẫn khi vào màn chơi.
  final bool showHandbookOnStart;

  const GameScreenWrapper({
    super.key,
    required this.builder,
    required this.gameName,
    required this.onFinishAndExit,
    this.onSaveAndExit,
    this.onRestart,
    this.handbookContent,
    this.showHandbookOnStart = true,
  });

  @override
  State<GameScreenWrapper> createState() => _GameScreenWrapperState();
}

// LÝ DO GIÁN ĐOẠN GAME
enum _Interruption { none, menu, handbook, settings }

class _GameScreenWrapperState extends State<GameScreenWrapper> {
  final _audioService = AudioService.instance;

  _Interruption _interruption = _Interruption.none;
  bool _handbookShown = false;

  bool get _isFrozen => _interruption != _Interruption.none; // gửi xuống gameplay

  @override
  void initState() {
    super.initState();
    _audioService.playBgm('audio/background_music.mp3');

    // Auto-show Hướng dẫn lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.handbookContent != null &&
          widget.showHandbookOnStart &&
          !_handbookShown) {
        setState(() => _interruption = _Interruption.handbook);
        _showHandbookDialog(onClosed: () {
          if (!mounted) return;
          setState(() => _interruption = _Interruption.none);
        });
        _handbookShown = true;
      }
    });
  }

  @override
  void dispose() {
    _audioService.stopBgm();
    super.dispose();
  }

  Widget _buildDialogButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        padding: const EdgeInsets.symmetric(vertical: 14.0),
      ),
    );
  }

  void _showCustomDialog({
    required String title,
    required Widget content,
    List<Widget> actions = const [],
    bool isScrollable = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final maxH = MediaQuery.of(context).size.height * 0.6;
        final contentBox = isScrollable
            ? ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SingleChildScrollView(child: content),
        )
            : content;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
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
                BoxShadow(color: Colors.black54, blurRadius: 10.0, offset: Offset(0.0, 10.0)),
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
                Flexible(child: contentBox), // Sửa lỗi overflow cho dialog
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

  void _showExitConfirmationDialog() {
    // vẫn đang ở trạng thái menu → hiển thị hộp thoại xác nhận
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

  void _showSettings() {
    // Nếu gọi từ AppBar hoặc menu, ta chỉ đóng băng game (không ép hiện menu)
    final old = _interruption;
    setState(() => _interruption = _Interruption.settings);
    _showCustomDialog(
      title: 'Cài đặt',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Âm lượng nhạc nền', style: TextStyle(color: Colors.white70)),
          ValueListenableBuilder<double>(
            valueListenable: _audioService.volumeNotifier,
            builder: (context, volume, child) {
              return Slider(
                value: volume,
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.blueAccent.withOpacity(0.3),
                onChanged: (newVolume) => _audioService.volumeNotifier.value = newVolume,
              );
            },
          ),
        ],
      ),
      actions: [
        _buildDialogButton(
          text: 'Đóng',
          icon: Icons.check_circle_outline,
          onPressed: () {
            Navigator.of(context).pop();
            if (!mounted) return;
            // Trả lại trạng thái trước (thường là menu hoặc none)
            setState(() => _interruption = old);
          },
          backgroundColor: Colors.blueAccent,
        ),
      ],
    );
  }

  void _showHandbookDialog({VoidCallback? onClosed}) {
    if (widget.handbookContent == null) return;
    _showCustomDialog(
      title: 'Hướng dẫn',
      content: widget.handbookContent!,
      actions: [
        _buildDialogButton(
          text: 'Đã hiểu',
          icon: Icons.thumb_up_alt_outlined,
          onPressed: () {
            Navigator.of(context).pop();
            onClosed?.call();
          },
          backgroundColor: Colors.blueAccent,
        ),
      ],
      isScrollable: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: AnimatedOpacity( // Sửa lỗi chữ đè lên nhau
          opacity: _isFrozen ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: Text(
            widget.gameName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.8,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Hướng dẫn',
            onPressed: widget.handbookContent == null
                ? null
                : () {
              setState(() => _interruption = _Interruption.handbook);
              _showHandbookDialog(onClosed: () {
                if (!mounted) return;
                setState(() => _interruption = _Interruption.none);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.pause_circle_outline, color: Colors.white),
            tooltip: 'Tạm dừng',
            iconSize: 32,
            onPressed: () => setState(() => _interruption = _Interruption.menu),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gửi trạng thái "đóng băng" xuống gameplay để dừng timer/nhập liệu
          widget.builder(context, _isFrozen),

          // Chỉ hiển thị menu tạm dừng nếu lý do là MENU
          if (_interruption == _Interruption.menu)
            GamePauseMenu(
              onResumed: () => setState(() => _interruption = _Interruption.none),
              onRestart: () {
                setState(() => _interruption = _Interruption.none);
                widget.onRestart?.call();
              },
              onSettings: _showSettings,
              onExit: _showExitConfirmationDialog,
            ),
        ],
      ),
    );
  }
}