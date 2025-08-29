import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
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
    HomeScreen(),          // 👈 Trang chủ có nút “Chơi game…”
    TimeScreen(),
    ListTreScreen(),
    RewardListScreen(),
    ProfileScreen(),       // nếu bạn có tab Hồ sơ
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.access_time), label: 'Thời gian'),
          NavigationDestination(icon: Icon(Icons.emoji_people_outlined), selectedIcon: Icon(Icons.emoji_people), label: 'Trẻ'),
          NavigationDestination(icon: Icon(Icons.star_border), selectedIcon: Icon(Icons.star), label: 'Điểm'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}
