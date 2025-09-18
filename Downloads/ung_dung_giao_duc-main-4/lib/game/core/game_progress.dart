class GameProgress {
  final String treId;
  final String gameId;       // ví dụ: recycle_sort
  final int difficulty;      // 1/2/3
  final List<String> deck;   // danh sách item id/emoji để giữ thứ tự
  final int index;           // đang ở câu thứ mấy (0-based)
  final int correct;
  final int wrong;
  final int timeLeft;        // giây còn lại
  final String updatedAt;    // ISO8601

  const GameProgress({
    required this.treId,
    required this.gameId,
    required this.difficulty,
    required this.deck,
    required this.index,
    required this.correct,
    required this.wrong,
    required this.timeLeft,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'treId': treId,
    'gameId': gameId,
    'difficulty': difficulty,
    'deck': deck,
    'index': index,
    'correct': correct,
    'wrong': wrong,
    'timeLeft': timeLeft,
    'updatedAt': updatedAt,
  };

  factory GameProgress.fromMap(Map<dynamic, dynamic> m) => GameProgress(
    treId: m['treId'] as String,
    gameId: m['gameId'] as String,
    difficulty: (m['difficulty'] ?? 1) as int,
    deck: List<String>.from((m['deck'] ?? const []) as List),
    index: (m['index'] ?? 0) as int,
    correct: (m['correct'] ?? 0) as int,
    wrong: (m['wrong'] ?? 0) as int,
    timeLeft: (m['timeLeft'] ?? 0) as int,
    updatedAt: (m['updatedAt'] ?? '') as String,
  );

  GameProgress copyWith({
    List<String>? deck, int? index, int? correct, int? wrong, int? timeLeft,
  }) => GameProgress(
    treId: treId,
    gameId: gameId,
    difficulty: difficulty,
    deck: deck ?? this.deck,
    index: index ?? this.index,
    correct: correct ?? this.correct,
    wrong: wrong ?? this.wrong,
    timeLeft: timeLeft ?? this.timeLeft,
    updatedAt: DateTime.now().toIso8601String(),
  );
}
