import 'package:flutter/material.dart';
import 'package:mobileapp/services/audio_service.dart';
import 'package:mobileapp/services/settings_service.dart'; // MỚI: Import SettingsService
import 'game_pause_menu.dart';

class GameScreenWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, bool isPaused) builder;
  final String gameName;
  final VoidCallback onFinishAndExit;
  final VoidCallback? onSaveAndExit;
  final VoidCallback? onRestart;
  final Widget? handbookContent;

  // CẬP NHẬT: Tham số này giờ là giá trị mặc định cho lần đầu tiên.
  // Logic chính sẽ dựa vào SettingsService.
  final bool showHandbookOnStart;

  const GameScreenWrapper({
    super.key,
    required this.builder,
    required this.gameName,
    required this.onFinishAndExit,
    this.onSaveAndExit,
    this.onRestart,
    this.handbookContent,
    this.showHandbookOnStart = true, // Giữ nguyên giá trị mặc định
  });

  @override
  State<GameScreenWrapper> createState() => _GameScreenWrapperState();
}

enum _Interruption { none, menu, handbook, settings }

class _GameScreenWrapperState extends State<GameScreenWrapper> {
  final _audioService = AudioService.instance;
  // MỚI: Thêm instance của SettingsService
  final _settingsService = SettingsService.instance;

  _Interruption _interruption = _Interruption.none;
  bool _handbookShown = false;
  // MỚI: State để lưu trạng thái tự động bật hướng dẫn
  late bool _autoShowHandbook;

  bool get _isFrozen => _interruption != _Interruption.none;

  @override
  void initState() {
    super.initState();
    // MỚI: Đọc cài đặt ngay khi vào màn hình
    _autoShowHandbook = _settingsService.getAutoShowHandbook();

    _audioService.playBgm('audio/background_music.mp3');

    // CẬP NHẬT: Logic hiển thị hướng dẫn dựa trên cài đặt đã lưu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Chỉ hiện khi cài đặt đang bật, có nội dung và chưa được hiển thị
      if (_autoShowHandbook &&
          widget.handbookContent != null &&
          !_handbookShown) {
        _showHandbookDialogWrapper();
        _handbookShown = true;
      }
    });
  }

  @override
  void dispose() {
    _audioService.stopBgm();
    super.dispose();
  }

  // ... (giữ nguyên hàm _buildDialogButton và _showCustomDialog) ...
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
                Flexible(child: contentBox),
                const SizedBox(height: 24.0),
                if (actions.isNotEmpty)
                // CẬP NHẬT: Dùng Wrap để các nút tự xuống dòng nếu không đủ chỗ
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ... (giữ nguyên _showExitConfirmationDialog và _showSettings) ...
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
        if (widget.onSaveAndExit != null) const SizedBox(height: 8),
        _buildDialogButton(
          text: 'Thoát & Tổng kết',
          icon: Icons.flag_rounded,
          onPressed: () {
            Navigator.of(context).pop();
            widget.onFinishAndExit();
          },
          backgroundColor: Colors.redAccent,
        ),
        const SizedBox(height: 8),
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
            setState(() => _interruption = old);
          },
          backgroundColor: Colors.blueAccent,
        ),
      ],
    );
  }


  // MỚI: Hàm wrapper để quản lý trạng thái khi mở/đóng dialog
  void _showHandbookDialogWrapper() {
    setState(() => _interruption = _Interruption.handbook);
    _showHandbookDialog(onClosed: () {
      if (!mounted) return;
      setState(() => _interruption = _Interruption.none);
    });
  }

  // CẬP NHẬT: Hàm hiển thị dialog hướng dẫn
  void _showHandbookDialog({VoidCallback? onClosed}) {
    if (widget.handbookContent == null) return;

    // Dùng StatefulBuilder để dialog có thể tự cập nhật trạng thái của nút toggle
    // mà không cần rebuild cả màn hình game.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {

            // Hàm để xử lý khi nhấn nút toggle
            void toggleAutoShow() {
              final newValue = !_autoShowHandbook;
              _settingsService.setAutoShowHandbook(newValue);
              // Cập nhật state của dialog và cả màn hình wrapper
              setDialogState(() => _autoShowHandbook = newValue);
              setState(() => _autoShowHandbook = newValue);
            }

            final maxH = MediaQuery.of(context).size.height * 0.6;
            final contentBox = ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: SingleChildScrollView(child: widget.handbookContent!),
            );

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
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Hướng dẫn',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Flexible(child: contentBox),
                    const SizedBox(height: 24.0),
                    // CẬP NHẬT: Actions giờ là một Row
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        // Nút bật/tắt mới
                        TextButton.icon(
                          icon: Icon(
                            _autoShowHandbook
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                          ),
                          label: Text(_autoShowHandbook ? 'Tự động bật' : 'Đã tắt'),
                          onPressed: toggleAutoShow,
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.7)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16)
                          ),
                        ),

                        // Nút "Đã hiểu"
                        ElevatedButton.icon(
                          icon: const Icon(Icons.thumb_up_alt_outlined),
                          label: const Text('Đã hiểu'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onClosed?.call();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16)
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: AnimatedOpacity(
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
        // ... (giữ nguyên flexibleSpace) ...
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
                : _showHandbookDialogWrapper, // CẬP NHẬT: Gọi hàm wrapper
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
          widget.builder(context, _isFrozen),
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