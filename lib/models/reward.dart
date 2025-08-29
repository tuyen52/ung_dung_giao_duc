class Reward {
  final String treId;
  final int points;
  final int gold;
  final int silver;
  final int bronze;
  final DateTime? lastUpdated;

  Reward({
    required this.treId,
    this.points = 0,
    this.gold = 0,
    this.silver = 0,
    this.bronze = 0,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'treId': treId,
        'points': points,
        'gold': gold,
        'silver': silver,
        'bronze': bronze,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory Reward.fromMap(Map<dynamic, dynamic> map) => Reward(
        treId: map['treId'] ?? '',
        points: map['points'] ?? 0,
        gold: map['gold'] ?? 0,
        silver: map['silver'] ?? 0,
        bronze: map['bronze'] ?? 0,
        lastUpdated: map['lastUpdated'] != null
            ? DateTime.tryParse(map['lastUpdated'])
            : null,
      );
}
