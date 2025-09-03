// lib/game/widgets/game_pause_menu.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GamePauseMenu extends StatelessWidget {
  final VoidCallback onResumed;
  // THÊM: Callback cho chức năng Chơi lại
  final VoidCallback onRestart;
  final VoidCallback onSettings;
  // THÊM: Callback cho Hướng dẫn (có thể null)
  final VoidCallback? onHandbook;
  final VoidCallback onExit;

  const GamePauseMenu({
    super.key,
    required this.onResumed,
    required this.onRestart, // THÊM
    required this.onSettings,
    this.onHandbook, // THÊM
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'GAME TẠM DỪNG',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 3.0,
                        color: Color.fromARGB(150, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Nút Tiếp tục
                _buildMenuItem(
                  icon: Icons.play_arrow_rounded,
                  label: 'TIẾP TỤC',
                  onPressed: onResumed,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),

                // THÊM: Nút Chơi lại
                _buildMenuItem(
                  icon: Icons.replay_rounded,
                  label: 'CHƠI LẠI',
                  onPressed: onRestart,
                  color: Colors.orange,
                ),
                const SizedBox(height: 20),

                // Nút Cài đặt
                _buildMenuItem(
                  icon: Icons.settings_rounded,
                  label: 'CÀI ĐẶT',
                  onPressed: onSettings,
                  color: Colors.blueGrey,
                ),
                const SizedBox(height: 20),

                // THÊM: Nút Hướng dẫn (chỉ hiển thị nếu có)
                if (onHandbook != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'HƯỚNG DẪN',
                      onPressed: onHandbook!,
                      color: Colors.teal,
                    ),
                  ),

                // Nút Thoát
                _buildMenuItem(
                  icon: Icons.exit_to_app_rounded,
                  label: 'THOÁT',
                  onPressed: onExit,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: 250,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: color, width: 2),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}