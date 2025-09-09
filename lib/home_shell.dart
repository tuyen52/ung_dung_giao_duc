import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'screens/game_list_screen.dart';
import 'screens/time_screen.dart';
import 'screens/list_tre_screen.dart';
import 'screens/reward_list_screen.dart';
import 'screens/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    GameListScreen(),
    TimeScreen(),
    ListTreScreen(),
    RewardListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: const Color(0xFF6A1B9A),
              color: Colors.grey[600],
              tabs: [
                GButton(
                  icon: Icons.videogame_asset_outlined,
                  text: 'Game',
                  textStyle: GoogleFonts.balsamiqSans(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                GButton(
                  icon: Icons.access_time_outlined,
                  text: 'Thời gian',
                  textStyle: GoogleFonts.balsamiqSans(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                GButton(
                  icon: Icons.groups_outlined,
                  text: 'Trẻ',
                  textStyle: GoogleFonts.balsamiqSans(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                GButton(
                  icon: Icons.card_giftcard_outlined,
                  text: 'Thưởng',
                  textStyle: GoogleFonts.balsamiqSans(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                GButton(
                  icon: Icons.person_outline,
                  text: 'Hồ sơ',
                  textStyle: GoogleFonts.balsamiqSans(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
              selectedIndex: _index,
              onTabChange: (i) => setState(() => _index = i),
            ),
          ),
        ),
      ),
    );
  }
}