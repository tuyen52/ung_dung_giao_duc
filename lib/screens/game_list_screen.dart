import 'package:flutter/material.dart';
import '../game/game_registry.dart';
import 'game_select_screen.dart';

class GameListScreen extends StatelessWidget {
  const GameListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allGames = GameRegistry.games;

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn Game')),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: allGames.length,
        itemBuilder: (context, index) {
          final gameInfo = allGames[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ListTile(
              leading: Icon(gameInfo.icon, size: 40, color: Theme.of(context).primaryColor),
              title: Text(gameInfo.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(gameInfo.description),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Chuyển gameInfo sang màn hình chọn trẻ
                    builder: (_) => GameSelectScreen(gameInfo: gameInfo),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}