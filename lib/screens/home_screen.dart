import 'package:flutter/material.dart';
import 'game_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_esports, size: 72),
              const SizedBox(height: 16),
              const Text('Chào mừng!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Sẵn sàng khám phá các trò chơi trí tuệ!', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameListScreen()),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Bắt đầu chơi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}