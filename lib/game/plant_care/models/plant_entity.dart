import '../data/plant_care_data.dart';
import '../core/balance.dart';
import 'quests.dart';

class Plant {
  final PlantType type;
  String speciesName;
  String label;
  PlantStage stage;

  double waterLevel;
  double lightLevel;
  double nutrientLevel;

  int growthProgress; // 0..100

  bool pests;      // cần Bắt Sâu
  bool overgrown;  // cần Tỉa Cành

  bool isCompleted;

  AnimationTrigger animationTrigger = AnimationTrigger.idle;
  int animationCounter = 0;

  int lastDailyScore;
  Sticker lastSticker;

  List<StageQuest> quests;

  Plant({
    required this.type,
    required this.speciesName,
    required this.label,
    required this.stage,
    required this.waterLevel,
    required this.lightLevel,
    required this.nutrientLevel,
    this.growthProgress = 0,
    this.pests = false,
    this.overgrown = false,
    this.isCompleted = false,
    this.lastDailyScore = 0,
    this.lastSticker = Sticker.none,
    this.quests = const [],
  });
}
