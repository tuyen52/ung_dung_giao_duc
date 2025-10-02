import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Menu tạm dừng: đáp ứng, có Semantics, nút full-width.
class GamePauseMenu extends StatelessWidget {
  const GamePauseMenu({
    super.key,
    required this.onResumed,
    required this.onRestart,
    this.onSettings,
    required this.onExit,
  });

  final VoidCallback onResumed;
  final VoidCallback onRestart;
  final VoidCallback? onSettings;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxW = math.min(360.0, size.width * 0.9);

    // CẬP NHẬT: Thêm Container để làm mờ nền và chặn tương tác với game
    return Container(
      color: Colors.black.withOpacity(0.3), // Lớp màu này sẽ chặn các thao tác chạm
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Material(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FocusTraversalGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'GAME TẠM DỪNG',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TIẾP TỤC
                      _semanticButton(
                        label: 'Tiếp tục trò chơi',
                        child: _menuButton(
                          context,
                          icon: Icons.play_arrow_rounded,
                          text: 'TIẾP TỤC',
                          onPressed: onResumed,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // CHƠI LẠI
                      _semanticButton(
                        label: 'Chơi lại từ đầu',
                        child: _menuButton(
                          context,
                          icon: Icons.replay_rounded,
                          text: 'CHƠI LẠI',
                          onPressed: onRestart,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // CÀI ĐẶT (nếu có)
                      if (onSettings != null) ...[
                        _semanticButton(
                          label: 'Cài đặt âm thanh/tuỳ chọn',
                          child: _menuButton(
                            context,
                            icon: Icons.settings_rounded,
                            text: 'CÀI ĐẶT',
                            onPressed: onSettings,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // THOÁT
                      _semanticButton(
                        label: 'Thoát trò chơi',
                        child: _menuButton(
                          context,
                          icon: Icons.exit_to_app_rounded,
                          text: 'THOÁT',
                          onPressed: onExit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _semanticButton({required String label, required Widget child}) {
    return Semantics(button: true, label: label, child: child);
  }

  Widget _menuButton(
      BuildContext context, {
        required IconData icon,
        required String text,
        required VoidCallback? onPressed,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}