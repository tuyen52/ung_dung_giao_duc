import 'game.dart';

class PlantCareGame implements Game {
  @override
  final int difficulty; // 1, 2, 3
  PlantCareGame({required this.difficulty});
}