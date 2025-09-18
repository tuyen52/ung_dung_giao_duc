import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/core/game_registry.dart';
import 'game_select_screen.dart';

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  final allGames = GameRegistry.games;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        // Tái sử dụng cùng một Scaffold và AppBar cho cả hai chế độ
        return Scaffold(
          appBar: _buildSharedAppBar(), // Dùng chung AppBar
          body: Stack(
            children: [
              // Dùng chung nền trang trí
              _buildDecorativeBackground(),
              // Xây dựng GridView tùy theo hướng màn hình
              if (orientation == Orientation.landscape)
                _buildLandscapeGridView()
              else
                _buildPortraitGridView(),
            ],
          ),
        );
      },
    );
  }

  // Widget xây dựng AppBar, được dùng chung cho cả hai chế độ
  AppBar _buildSharedAppBar() {
    return AppBar(
      title: Text(
        'Thế Giới Khám Phá Của Bé',
        style: GoogleFonts.quicksand(
          fontWeight: FontWeight.w900,
          fontSize: 26,
          color: Colors.white,
          shadows: const [
            Shadow(
              offset: Offset(2.0, 2.0),
              blurRadius: 5.0,
              color: Color.fromARGB(150, 0, 0, 0),
            ),
          ],
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8E24AA),
              Color(0xFFBA68C8),
              Color(0xFFCE93D8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 15,
    );
  }

  // Widget xây dựng GridView cho chế độ dọc (PORTRAIT)
  Widget _buildPortraitGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(25),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 cột
        crossAxisSpacing: 25,
        mainAxisSpacing: 25,
        childAspectRatio: 0.8,
      ),
      itemCount: allGames.length,
      itemBuilder: (context, index) {
        final gameInfo = allGames[index];
        return AnimatedGameCard(gameInfo: gameInfo);
      },
    );
  }

  // Widget chỉ xây dựng GridView cho chế độ ngang (LANDSCAPE)
  Widget _buildLandscapeGridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 20), // Điều chỉnh padding
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 cột
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.9, // Điều chỉnh tỉ lệ
      ),
      itemCount: allGames.length,
      itemBuilder: (context, index) {
        final gameInfo = allGames[index];
        return AnimatedGameCard(gameInfo: gameInfo);
      },
    );
  }

  // Widget xây dựng nền trang trí
  Widget _buildDecorativeBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFDE8E9),
                  Color(0xFFE0F7FA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.05,
          left: -30,
          child: Icon(Icons.cloud_queue, size: 100, color: Colors.white.withOpacity(0.4)),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.1,
          right: -20,
          child: Icon(Icons.star, size: 80, color: Colors.yellow.withOpacity(0.3)),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.2,
          right: -10,
          child: Icon(Icons.favorite, size: 60, color: Colors.red.withOpacity(0.2)),
        ),
      ],
    );
  }
}

// PHẦN AnimatedGameCard GIỮ NGUYÊN, KHÔNG THAY ĐỔI
class AnimatedGameCard extends StatefulWidget {
  final GameInfo gameInfo;

  const AnimatedGameCard({required this.gameInfo, super.key});

  @override
  State<AnimatedGameCard> createState() => _AnimatedGameCardState();
}

class _AnimatedGameCardState extends State<AnimatedGameCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 0.85,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _elevationAnimation = Tween<double>(begin: 15.0, end: 5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameSelectScreen(gameInfo: widget.gameInfo),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Card(
                elevation: _elevationAnimation.value,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          // Sử dụng màu từ GameInfo để tạo gradient độc đáo
                          gradient: LinearGradient(
                            colors: [
                              widget.gameInfo.primaryColor.withOpacity(0.9),
                              widget.gameInfo.secondaryColor.withOpacity(1.0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 25,
                      left: 0,
                      right: 0,
                      child: Icon(
                        widget.gameInfo.icon,
                        size: 90,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            offset: Offset(4.0, 4.0),
                            blurRadius: 10.0,
                            color: Color.fromARGB(150, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 25,
                      left: 15,
                      right: 15,
                      child: Text(
                        widget.gameInfo.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              offset: Offset(1.5, 1.5),
                              blurRadius: 3.0,
                              color: Color.fromARGB(100, 0, 0, 0),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Icon(
                        Icons.emoji_events,
                        color: Colors.white.withOpacity(0.7),
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}