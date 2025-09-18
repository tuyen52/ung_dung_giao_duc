import '../data/plant_care_data.dart';

enum QuestType { okZonesDays, handlePestsOnce, pruneOnce }

class StageQuest {
  final QuestType type;
  final int requiredOkCount; // cho okZonesDays
  final int targetDays;      // cho okZonesDays
  int progressDays;
  bool completed;

  StageQuest.okDays({required this.requiredOkCount, required this.targetDays})
      : type = QuestType.okZonesDays,
        progressDays = 0,
        completed = false;

  StageQuest.handlePests()
      : type = QuestType.handlePestsOnce,
        requiredOkCount = 0,
        targetDays = 0,
        progressDays = 0,
        completed = false;

  StageQuest.pruneOnce()
      : type = QuestType.pruneOnce,
        requiredOkCount = 0,
        targetDays = 0,
        progressDays = 0,
        completed = false;

  String label() {
    switch (type) {
      case QuestType.okZonesDays:
        final p = progressDays > targetDays ? targetDays : progressDays;
        return 'Giữ ≥$requiredOkCount vùng xanh trong $targetDays ngày ($p/$targetDays)';
      case QuestType.handlePestsOnce:
        return 'Bắt sâu khi xuất hiện';
      case QuestType.pruneOnce:
        return 'Tỉa cành khi cây um';
    }
  }
}

List<StageQuest> generateQuestsForStage(PlantStage s) {
  switch (s) {
    case PlantStage.hatGiong:
      return [ StageQuest.okDays(requiredOkCount: 2, targetDays: 1) ];
    case PlantStage.cayCon:
      return [ StageQuest.okDays(requiredOkCount: 2, targetDays: 2) ];
    case PlantStage.truongThanh:
      return [
        StageQuest.okDays(requiredOkCount: 3, targetDays: 1),
        StageQuest.pruneOnce(),
      ];
    case PlantStage.raHoa:
      return [];
  }
}
