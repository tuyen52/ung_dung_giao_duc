// lib/game/types.dart

typedef FinishCallback = void Function(int correct, int wrong);

// 👇 THÊM enum độ khó
enum GameDifficulty { easy, medium, hard }
