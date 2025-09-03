import 'package:flutter/material.dart';

// 1. Định nghĩa một class để chứa thông tin game
class GameInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String route; // Route để khởi chạy game

  const GameInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.route,
  });
}

// 2. Cập nhật danh sách các game
class GameRegistry {
  static final List<GameInfo> games = [
    GameInfo(
      id: 'recycle_sort',
      name: 'Phân Loại Rác',
      description: 'Kéo rác vào đúng thùng hữu cơ hoặc vô cơ.',
      icon: Icons.recycling,
      route: '/game/recycle',
    ),
    // THAY THẾ GAME CŨ BẰNG GAME MỚI
    GameInfo(
      id: 'traffic_safety',
      name: 'An Toàn Giao Thông',
      description: 'Chọn phương án đúng cho các tình huống giao thông.',
      icon: Icons.traffic,
      route: '/game/traffic_safety', // Route mới cho game
    ),
    GameInfo(
      id: 'plant_care',
      name: 'Chăm Sóc Cây Trồng',
      description: 'Chăm sóc các chậu cây theo đúng nhu cầu của chúng.',
      icon: Icons.local_florist,
      route: '/game/plant_care',
    ),
  ];
}