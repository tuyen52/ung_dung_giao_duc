// lib/game/swimming_safety/swimming_safety_game.dart
import '../core/game.dart';

class SwimmingSafetyGame implements Game {
  @override
  final int difficulty; // 1, 2, 3
  SwimmingSafetyGame({required this.difficulty});
}