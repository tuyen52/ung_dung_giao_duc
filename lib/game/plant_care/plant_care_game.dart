// lib/game/plant_care/plant_care_game.dart
import '../core/game.dart';

class PlantCareGame implements Game {
  @override
  final int difficulty; // 1 (easy), 2 (medium), 3 (hard)
  PlantCareGame({required this.difficulty});
}
