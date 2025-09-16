import 'dart:math';
import '../data/plant_care_data.dart';

double clamp100(double v) => v.clamp(0.0, 100.0).toDouble();
int clampInt(int v, int lo, int hi) => max(lo, min(hi, v));

// --- Balance ---
const double initialStatLevel = 50.0;       // vẫn dùng nếu cần mặc định
const double toolEffectAmount = 30.0;
const double baseDailyDecay   = 20.0;
const double nutrientDailyDecay = 15.0;

// Số ngày mặc định cho 1 vòng chơi
const int totalDays = 5;

// --- Zones ---
enum Zone { low, ok, high }
const double tolHi = 5.0; // nới đỉnh
const double tolLo = 5.0; // nới đáy

Zone zoneOf(double v, Range opt) {
  if (v < opt.low - tolLo) return Zone.low;
  if (v > opt.high + tolHi) return Zone.high;
  return Zone.ok;
}

// --- Sticker & Animation ---
enum Sticker { none, bronze, silver, gold }
Sticker stickerFromScore(int s) {
  if (s >= 15) return Sticker.gold;
  if (s >= 10) return Sticker.silver;
  if (s >= 5)  return Sticker.bronze;
  return Sticker.none;
}
enum AnimationTrigger { idle, healthy, unhealthy }

// --- Scoring ---
int dailyGrowthScore(Zone w, Zone l, Zone n, {bool pests = false, bool overgrown = false}) {
  final highs = [w, l, n].where((z) => z == Zone.high).length;
  final lows  = [w, l, n].where((z) => z == Zone.low).length;
  int score;
  if (highs >= 1)       score = 0;
  else if (lows == 0)   score = 15;
  else if (lows == 1)   score = 10;
  else                  score = 5;

  if (pests)     score -= 3;
  if (overgrown) score -= 3;
  return clampInt(score, 0, 15);
}
