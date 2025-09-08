import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tre.dart';
import '../services/tre_service.dart';
import 'package:mobileapp/game/core/types.dart';
import '../game/core/game_registry.dart';

// THÊM: Import các service và model cần thiết
import '../services/game_progress_service.dart';
import '../game/core/game_progress.dart';


class GameSelectScreen extends StatefulWidget {
  final GameInfo gameInfo;

  const GameSelectScreen({super.key, required this.gameInfo});

  @override
  State<GameSelectScreen> createState() => _GameSelectScreenState();
}

class _GameSelectScreenState extends State<GameSelectScreen> {
  Tre? _selectedTre;
  GameDifficulty _difficulty = GameDifficulty.easy;

  // ====================================================================
  // HÀM MỚI: Xử lý logic khi nhấn nút "Bắt đầu chơi"
  // ====================================================================
  Future<void> _handleStartGame() async {
    if (_selectedTre == null) return;

    final tre = _selectedTre!;
    final gameInfo = widget.gameInfo;
    final gameProgressService = GameProgressService();

    // 1. Kiểm tra xem có tiến trình nào đã được lưu không
    final GameProgress? savedProgress = await gameProgressService.load(tre.id, gameInfo.id);

    // 2. Nếu không có tiến trình lưu, hoặc context không còn tồn tại, thì vào game luôn
    if (savedProgress == null || !mounted) {
      _navigateToGame(tre);
      return;
    }

    // 3. Nếu có, hiển thị hộp thoại hỏi người dùng
    showDialog(
      context: context,
      barrierDismissible: false, // Người dùng phải chọn một trong hai
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Phát hiện tiến trình đã lưu'),
          content: const Text('Bạn có một ván chơi đang dang dở. Bạn muốn tiếp tục hay bắt đầu một ván chơi mới?'),
          actions: <Widget>[
            // Nút "Chơi mới": Xóa tiến trình cũ rồi vào game
            TextButton(
              child: const Text('Chơi mới'),
              onPressed: () async {
                await gameProgressService.clear(tre.id, gameInfo.id);
                if (mounted) {
                  Navigator.of(context).pop(); // Đóng hộp thoại
                  _navigateToGame(tre);
                }
              },
            ),
            // Nút "Chơi tiếp": Chỉ vào game, launcher sẽ tự tải tiến trình
            FilledButton(
              child: const Text('Chơi tiếp'),
              onPressed: () {
                Navigator.of(context).pop(); // Đóng hộp thoại
                _navigateToGame(tre);
              },
            ),
          ],
        );
      },
    );
  }

  // HÀM MỚI: Tách riêng phần điều hướng để dễ gọi lại
  void _navigateToGame(Tre tre) {
    Navigator.pushNamed(
      context,
      widget.gameInfo.route,
      arguments: <String, Object>{
        'treId': tre.id,
        'treName': tre.hoTen.isEmpty ? 'Bé' : tre.hoTen,
        'difficulty': _difficulty,
      },
    );
  }
  // ====================================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Chơi: ${widget.gameInfo.name}')),
      body: Column(
        children: [
          // ---------- Danh sách Trẻ (giữ nguyên) ----------
          Expanded(
            child: StreamBuilder<List<Tre>>(
              stream: TreService().watchTreList(user.uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data ?? const <Tre>[];
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Chưa có hồ sơ trẻ, hãy thêm ở tab "Trẻ".'),
                  );
                }

                if (_selectedTre == null && list.isNotEmpty) {
                  _selectedTre = list.first;
                }

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (ctx, i) {
                    final t = list[i];
                    final selected = _selectedTre?.id == t.id;
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.child_care)),
                      title: Text(t.hoTen.isEmpty ? 'Bé' : t.hoTen),
                      subtitle: Text(
                        'Giới tính: ${t.gioiTinh.isEmpty ? "—" : t.gioiTinh}  •  '
                            'Sinh: ${t.ngaySinh.isEmpty ? "—" : t.ngaySinh}',
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: Colors.teal)
                          : null,
                      selected: selected,
                      onTap: () => setState(() => _selectedTre = t),
                    );
                  },
                );
              },
            ),
          ),

          // ---------- Chọn độ khó (giữ nguyên) ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: GameDifficulty.values.map((d) {
                final label = switch (d) {
                  GameDifficulty.easy => 'Dễ',
                  GameDifficulty.medium => 'Vừa',
                  GameDifficulty.hard => 'Khó',
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: _difficulty == d,
                  onSelected: (_) => setState(() => _difficulty = d),
                );
              }).toList(),
            ),
          ),

          // ---------- Nút Bắt đầu ----------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Bắt đầu chơi'),
                // SỬA ĐỔI: Gọi hàm _handleStartGame thay vì điều hướng trực tiếp
                onPressed: _selectedTre == null ? null : _handleStartGame,
              ),
            ),
          ),
        ],
      ),
    );
  }
}