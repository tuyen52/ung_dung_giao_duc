import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/tre.dart';
import '../services/tre_service.dart';
import 'package:mobileapp/game/core/types.dart';
import '../game/core/game_registry.dart';

class GameSelectScreen extends StatefulWidget {
  final GameInfo gameInfo;

  const GameSelectScreen({super.key, required this.gameInfo});

  @override
  State<GameSelectScreen> createState() => _GameSelectScreenState();
}

class _GameSelectScreenState extends State<GameSelectScreen> {
  Tre? _selectedTre;
  GameDifficulty _difficulty = GameDifficulty.easy;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập', style: GoogleFonts.balsamiqSans()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chơi: ${widget.gameInfo.name}',
          style: GoogleFonts.balsamiqSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: widget.gameInfo.primaryColor,
        elevation: 8,
        // Cải thiện appBar với gradient để phù hợp với nền tổng thể
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.gameInfo.primaryColor.withOpacity(0.8),
                widget.gameInfo.secondaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF1EB), // Màu hồng nhạt siêu nhẹ
              Color(0xFFE0F7FA), // Màu xanh da trời nhạt
              Color(0xFFE8F5E9), // Màu xanh lá cây nhạt
              Color(0xFFFFFDE7), // Màu vàng nhạt
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- Tiêu đề Danh sách Trẻ ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                '1. Chọn hồ sơ của bé',
                style: GoogleFonts.balsamiqSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700, // Màu đậm hơn cho tiêu đề
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3.0,
                      color: Colors.deepPurple.shade100,
                    ),
                  ],
                ),
              ),
            ),
            // ---------- Danh sách Trẻ ----------
            Expanded(
              child: StreamBuilder<List<Tre>>(
                stream: TreService().watchTreList(user.uid),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
                  }
                  final list = snap.data ?? const <Tre>[];
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Chưa có hồ sơ trẻ, hãy thêm ở tab "Trẻ" để bắt đầu chơi.',
                          style: GoogleFonts.balsamiqSans(color: Colors.deepPurple.shade700, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (_selectedTre == null && list.isNotEmpty) {
                    _selectedTre = list.first;
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final t = list[i];
                      final selected = _selectedTre?.id == t.id;
                      return _buildTreCard(t, selected);
                    },
                  );
                },
              ),
            ),
            // ---------- Chọn độ khó ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                '2. Chọn độ khó',
                style: GoogleFonts.balsamiqSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700, // Màu đậm hơn cho tiêu đề
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3.0,
                      color: Colors.deepPurple.shade100,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: GameDifficulty.values.map((d) {
                  return _buildDifficultyChip(d);
                }).toList(),
              ),
            ),
            // ---------- Nút Bắt đầu ----------
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_circle_fill, size: 30, color: Colors.white),
                  label: Text(
                    'Bắt đầu chơi',
                    style: GoogleFonts.balsamiqSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _selectedTre == null
                        ? Colors.grey.shade400
                        : widget.gameInfo.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30), // Tăng padding
                    elevation: 12, // Tăng độ nổi bật
                    shadowColor: Colors.black.withOpacity(0.3),
                  ),
                  onPressed: _selectedTre == null
                      ? null
                      : () {
                    final tre = _selectedTre!;
                    Navigator.pushNamed(
                      context,
                      widget.gameInfo.route,
                      arguments: <String, Object>{
                        'treId': tre.id,
                        'treName': tre.hoTen.isEmpty ? 'Bé' : tre.hoTen,
                        'difficulty': _difficulty,
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreCard(Tre tre, bool selected) {
    final isMale = tre.gioiTinh.toLowerCase() == 'nam';
    // Màu sắc riêng biệt cho bé trai/bé gái khi chưa được chọn
    final unselectedColor = isMale ? Colors.blue.shade100 : Colors.pink.shade100;
    final unselectedIconColor = isMale ? Colors.blue.shade700 : Colors.pink.shade700;
    final unselectedTextColor = Colors.grey.shade800;

    // Màu sắc khi được chọn
    final selectedCardColor = widget.gameInfo.primaryColor.withOpacity(0.9);
    final selectedBorderColor = isMale ? Colors.blue.shade300 : Colors.pink.shade300;
    final selectedIconColor = Colors.white;
    final selectedTextColor = Colors.white;
    final selectedSubtitleColor = Colors.white70;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: selected ? selectedCardColor : unselectedColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: selected ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
            blurRadius: selected ? 20 : 10,
            offset: selected ? const Offset(0, 10) : const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: selected ? selectedBorderColor : Colors.transparent, // Viền màu riêng cho giới tính khi được chọn
          width: selected ? 4 : 0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        leading: CircleAvatar(
          radius: 32,
          backgroundColor: selected
              ? selectedIconColor.withOpacity(0.2)
              : (isMale ? Colors.blue.shade300 : Colors.pink.shade300),
          child: Icon(
            isMale ? Icons.boy_rounded : Icons.girl_rounded,
            size: 40,
            color: selected ? selectedIconColor : unselectedIconColor,
          ),
        ),
        title: Text(
          tre.hoTen.isEmpty ? 'Bé' : tre.hoTen,
          style: GoogleFonts.balsamiqSans(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: selected ? selectedTextColor : unselectedTextColor,
          ),
        ),
        subtitle: Text(
          'Giới tính: ${tre.gioiTinh.isEmpty ? "—" : tre.gioiTinh}',
          style: GoogleFonts.balsamiqSans(color: selected ? selectedSubtitleColor : Colors.grey.shade600),
        ),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: selectedIconColor, size: 32)
            : null,
        onTap: () => setState(() => _selectedTre = tre),
      ),
    );
  }

  Widget _buildDifficultyChip(GameDifficulty d) {
    final label = switch (d) {
      GameDifficulty.easy => 'Dễ',
      GameDifficulty.medium => 'Vừa',
      GameDifficulty.hard => 'Khó',
    };
    final selected = _difficulty == d;

    // Định nghĩa màu sắc cụ thể cho từng độ khó
    Color primaryColor;
    Color secondaryColor;
    Color textColor;

    switch (d) {
      case GameDifficulty.easy:
        primaryColor = Colors.lightGreen.shade400;
        secondaryColor = Colors.lightGreen.shade700;
        textColor = selected ? Colors.white : Colors.lightGreen.shade800;
        break;
      case GameDifficulty.medium:
        primaryColor = Colors.orange.shade400;
        secondaryColor = Colors.orange.shade700;
        textColor = selected ? Colors.white : Colors.orange.shade800;
        break;
      case GameDifficulty.hard:
        primaryColor = Colors.red.shade400;
        secondaryColor = Colors.red.shade700;
        textColor = selected ? Colors.white : Colors.red.shade800;
        break;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = d),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 6), // Khoảng cách giữa các chip
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: selected
                  ? [primaryColor, secondaryColor] // Gradient khi được chọn
                  : [Colors.white.withOpacity(0.9), Colors.grey.shade50.withOpacity(0.9)], // Màu nhẹ khi không chọn
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: selected ? textColor : Colors.grey.shade300,
              width: selected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(selected ? 0.25 : 0.05),
                blurRadius: selected ? 15 : 5,
                offset: selected ? const Offset(0, 8) : const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.balsamiqSans(
                fontWeight: FontWeight.w800, // Đậm hơn
                fontSize: 18,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
