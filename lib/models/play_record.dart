class PlayRecord {
  final String id;          // sessionId (push key)
  final String treId;       // bé nào chơi
  final String gameId;      // ví dụ: recycle_sort
  final String gameName;    // Phân Loại Rác
  final String difficulty;  // easy/medium/hard hoặc số
  final int correct;
  final int wrong;
  final int score;          // tính theo quy tắc +20/-10
  final DateTime createdAt;

  PlayRecord({
    required this.id,
    required this.treId,
    required this.gameId,
    required this.gameName,
    required this.difficulty,
    required this.correct,
    required this.wrong,
    required this.score,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'treId': treId,
    'gameId': gameId,
    'gameName': gameName,
    'difficulty': difficulty,
    'correct': correct,
    'wrong': wrong,
    'score': score,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PlayRecord.fromMap(Map<dynamic, dynamic> m) => PlayRecord(
    id: (m['id'] ?? '') as String,
    treId: (m['treId'] ?? '') as String,
    gameId: (m['gameId'] ?? '') as String,
    gameName: (m['gameName'] ?? '') as String,
    difficulty: (m['difficulty'] ?? '') as String,
    correct: (m['correct'] ?? 0) as int,
    wrong: (m['wrong'] ?? 0) as int,
    score: (m['score'] ?? 0) as int,
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
  );
}
