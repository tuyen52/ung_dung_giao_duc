import 'dart:math';
import 'package:flutter/material.dart';

enum Weather { sunny, rainy, cloudy }

class WeatherInfo {
  final String name;
  final IconData icon;
  final String hint;
  final double waterMul; // nhân vào decay nước
  final double lightMul; // nhân vào decay sáng
  const WeatherInfo(this.name, this.icon, this.hint, this.waterMul, this.lightMul);
}

const Map<Weather, WeatherInfo> kWeather = {
  Weather.sunny : WeatherInfo('Nắng',  Icons.wb_sunny,     'Nắng ấm: nước bốc hơi nhanh hơn', 1.2, 0.8),
  Weather.rainy : WeatherInfo('Mưa',   Icons.beach_access, 'Mưa rơi: cây ít mất nước, thiếu nắng', 0.6, 1.1),
  Weather.cloudy: WeatherInfo('Mát',   Icons.cloud,        'Trời mát: mọi thứ cân bằng', 1.0, 1.0),
};

Weather rollWeather(Random rnd) {
  final r = rnd.nextDouble();
  if (r < 0.4) return Weather.sunny;
  if (r < 0.7) return Weather.cloudy;
  return Weather.rainy;
}
