import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _GameSelectScreenState extends State<GameSelectScreen> with WidgetsBindingObserver {
  Tre? _selectedTre;
  GameDifficulty _difficulty = GameDifficulty.easy;

  @override
  void initState() {
    super.initState();
    // Cho phép xoay màn hình
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Rebuild khi xoay màn hình
    setState(() {});
  }

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

    // Lấy thông tin màn hình
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final isTablet = size.shortestSide >= 600;

    return Scaffold(
      appBar: _buildAppBar(isLandscape, isTablet),
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: isLandscape
            ? _buildLandscapeLayout(context, user, size, isTablet)
            : _buildPortraitLayout(context, user, size, isTablet),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isLandscape, bool isTablet) {
    final double toolbarHeight = isLandscape
        ? (isTablet ? 65 : 50)
        : (isTablet ? 80 : kToolbarHeight);

    return PreferredSize(
      preferredSize: Size.fromHeight(toolbarHeight),
      child: AppBar(
        toolbarHeight: toolbarHeight,
        title: Text(
          'Chơi: ${widget.gameInfo.name}',
          style: GoogleFonts.balsamiqSans(
            fontSize: isLandscape ? (isTablet ? 26 : 20) : (isTablet ? 28 : 22),
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: widget.gameInfo.primaryColor,
        elevation: 8,
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
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFFFFF1EB),
          Color(0xFFE0F7FA),
          Color(0xFFE8F5E9),
          Color(0xFFFFFDE7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  // Layout cho màn hình dọc
  Widget _buildPortraitLayout(BuildContext context, User user, Size size, bool isTablet) {
    final double titleFontSize = isTablet ? 28 : 24;
    final double padding = isTablet ? 32 : 24;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tiêu đề chọn hồ sơ
        Padding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
          child: Text(
            '1. Chọn hồ sơ của bé',
            style: GoogleFonts.balsamiqSans(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 3.0,
                  color: Colors.deepPurple.shade100,
                ),
              ],
            ),
          ),
        ),
        // Danh sách trẻ
        Expanded(
          flex: isTablet ? 5 : 4,
          child: _buildTreList(user, isTablet, false),
        ),
        // Chọn độ khó
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 8),
          child: Text(
            '2. Chọn độ khó',
            style: GoogleFonts.balsamiqSans(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 3.0,
                  color: Colors.deepPurple.shade100,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, isTablet ? 16 : 8),
          child: _buildDifficultySelector(isTablet, false),
        ),
        // Nút bắt đầu
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: _buildStartButton(isTablet, false),
          ),
        ),
      ],
    );
  }

  // Layout cho màn hình ngang
  Widget _buildLandscapeLayout(BuildContext context, User user, Size size, bool isTablet) {
    final double titleFontSize = isTablet ? 26 : 20;
    final double padding = isTablet ? 24 : 16;

    return Row(
      children: [
        // Cột trái - Danh sách trẻ
        Expanded(
          flex: isTablet ? 3 : 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding / 2, 8),
                child: Text(
                  '1. Chọn hồ sơ của bé',
                  style: GoogleFonts.balsamiqSans(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 3.0,
                        color: Colors.deepPurple.shade100,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _buildTreList(user, isTablet, true),
              ),
            ],
          ),
        ),
        // Cột phải - Độ khó và nút Start
        Expanded(
          flex: isTablet ? 2 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(padding / 2, padding, padding, 8),
                child: Text(
                  '2. Chọn độ khó',
                  style: GoogleFonts.balsamiqSans(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 3.0,
                        color: Colors.deepPurple.shade100,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
                child: _buildDifficultySelector(isTablet, true),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: _buildStartButton(isTablet, true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTreList(User user, bool isTablet, bool isLandscape) {
    return StreamBuilder<List<Tre>>(
      stream: TreService().watchTreList(user.uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
          );
        }

        final list = snap.data ?? const <Tre>[];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Chưa có hồ sơ trẻ, hãy thêm ở tab "Trẻ" để bắt đầu chơi.',
                style: GoogleFonts.balsamiqSans(
                  color: Colors.deepPurple.shade700,
                  fontSize: isTablet ? 20 : 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (_selectedTre == null && list.isNotEmpty) {
          _selectedTre = list.first;
        }

        // Grid view cho tablet hoặc landscape mode với nhiều item
        if ((isTablet || isLandscape) && list.length > 3) {
          return GridView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: 8,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isLandscape ? 1 : 2,
              childAspectRatio: isLandscape ? 3.5 : 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final t = list[i];
              final selected = _selectedTre?.id == t.id;
              return _buildTreCard(t, selected, isTablet, isLandscape);
            },
          );
        }

        // List view cho phone hoặc ít item
        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: 8,
          ),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final t = list[i];
            final selected = _selectedTre?.id == t.id;
            return _buildTreCard(t, selected, isTablet, isLandscape);
          },
        );
      },
    );
  }

  Widget _buildTreCard(Tre tre, bool selected, bool isTablet, bool isLandscape) {
    final isMale = tre.gioiTinh.toLowerCase() == 'nam';
    final unselectedColor = isMale ? Colors.blue.shade100 : Colors.pink.shade100;
    final unselectedIconColor = isMale ? Colors.blue.shade700 : Colors.pink.shade700;
    final unselectedTextColor = Colors.grey.shade800;

    final selectedCardColor = widget.gameInfo.primaryColor.withOpacity(0.9);
    final selectedBorderColor = isMale ? Colors.blue.shade300 : Colors.pink.shade300;
    final selectedIconColor = Colors.white;
    final selectedTextColor = Colors.white;
    final selectedSubtitleColor = Colors.white70;

    // Điều chỉnh kích thước theo thiết bị
    final double avatarRadius = isTablet ? 36 : (isLandscape ? 28 : 32);
    final double iconSize = isTablet ? 44 : (isLandscape ? 36 : 40);
    final double titleSize = isTablet ? 22 : (isLandscape ? 18 : 20);
    final double subtitleSize = isTablet ? 16 : 14;
    final double checkIconSize = isTablet ? 36 : (isLandscape ? 28 : 32);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        vertical: isLandscape ? 6 : 10,
        horizontal: isLandscape ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: selected ? selectedCardColor : unselectedColor,
        borderRadius: BorderRadius.circular(isTablet ? 35 : 30),
        boxShadow: [
          BoxShadow(
            color: selected ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
            blurRadius: selected ? 20 : 10,
            offset: selected ? const Offset(0, 10) : const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: selected ? selectedBorderColor : Colors.transparent,
          width: selected ? 4 : 0,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 30 : (isLandscape ? 20 : 25),
          vertical: isTablet ? 20 : (isLandscape ? 10 : 15),
        ),
        leading: CircleAvatar(
          radius: avatarRadius,
          backgroundColor: selected
              ? selectedIconColor.withOpacity(0.2)
              : (isMale ? Colors.blue.shade300 : Colors.pink.shade300),
          child: Icon(
            isMale ? Icons.boy_rounded : Icons.girl_rounded,
            size: iconSize,
            color: selected ? selectedIconColor : unselectedIconColor,
          ),
        ),
        title: Text(
          tre.hoTen.isEmpty ? 'Bé' : tre.hoTen,
          style: GoogleFonts.balsamiqSans(
            fontWeight: FontWeight.bold,
            fontSize: titleSize,
            color: selected ? selectedTextColor : unselectedTextColor,
          ),
        ),
        subtitle: Text(
          'Giới tính: ${tre.gioiTinh.isEmpty ? "—" : tre.gioiTinh}',
          style: GoogleFonts.balsamiqSans(
            color: selected ? selectedSubtitleColor : Colors.grey.shade600,
            fontSize: subtitleSize,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: selectedIconColor, size: checkIconSize)
            : null,
        onTap: () => setState(() => _selectedTre = tre),
      ),
    );
  }

  Widget _buildDifficultySelector(bool isTablet, bool isLandscape) {
    if (isLandscape) {
      // Vertical layout cho landscape
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: GameDifficulty.values.map((d) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _buildDifficultyChip(d, isTablet, isLandscape),
          );
        }).toList(),
      );
    } else {
      // Horizontal layout cho portrait
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: GameDifficulty.values.map((d) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildDifficultyChip(d, isTablet, isLandscape),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildDifficultyChip(GameDifficulty d, bool isTablet, bool isLandscape) {
    final label = switch (d) {
      GameDifficulty.easy => 'Dễ',
      GameDifficulty.medium => 'Vừa',
      GameDifficulty.hard => 'Khó',
    };
    final selected = _difficulty == d;

    Color primaryColor;
    Color secondaryColor;
    Color textColor;
    IconData icon;

    switch (d) {
      case GameDifficulty.easy:
        primaryColor = Colors.lightGreen.shade400;
        secondaryColor = Colors.lightGreen.shade700;
        textColor = selected ? Colors.white : Colors.lightGreen.shade800;
        icon = Icons.sentiment_very_satisfied_rounded;
        break;
      case GameDifficulty.medium:
        primaryColor = Colors.orange.shade400;
        secondaryColor = Colors.orange.shade700;
        textColor = selected ? Colors.white : Colors.orange.shade800;
        icon = Icons.sentiment_satisfied_rounded;
        break;
      case GameDifficulty.hard:
        primaryColor = Colors.red.shade400;
        secondaryColor = Colors.red.shade700;
        textColor = selected ? Colors.white : Colors.red.shade800;
        icon = Icons.local_fire_department_rounded;
        break;
    }

    final double fontSize = isTablet ? 20 : (isLandscape ? 16 : 18);
    final double padding = isTablet ? 20 : (isLandscape ? 14 : 18);
    final double iconSize = isTablet ? 28 : (isLandscape ? 22 : 24);

    return GestureDetector(
      onTap: () => setState(() => _difficulty = d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 16 : 12,
          vertical: padding,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selected
                ? [primaryColor, secondaryColor]
                : [Colors.white.withOpacity(0.9), Colors.grey.shade50.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isLandscape ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: textColor,
              size: iconSize,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              label,
              style: GoogleFonts.balsamiqSans(
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(bool isTablet, bool isLandscape) {
    final double fontSize = isTablet ? 24 : (isLandscape ? 20 : 22);
    final double iconSize = isTablet ? 34 : (isLandscape ? 28 : 30);
    final double verticalPadding = isTablet ? 22 : (isLandscape ? 16 : 18);
    final double horizontalPadding = isTablet ? 40 : (isLandscape ? 25 : 30);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: FilledButton.icon(
        icon: Icon(
          Icons.play_circle_fill,
          size: iconSize,
          color: Colors.white,
        ),
        label: Text(
          'Bắt đầu chơi',
          style: GoogleFonts.balsamiqSans(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _selectedTre == null
              ? Colors.grey.shade400
              : widget.gameInfo.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 60 : 50),
          ),
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
          elevation: 12,
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
    );
  }
}