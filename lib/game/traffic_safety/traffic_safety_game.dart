import '../core/game.dart';

class TrafficSafetyGame implements Game {
  @override
  final int difficulty; // 1, 2, 3
  TrafficSafetyGame({required this.difficulty});
}