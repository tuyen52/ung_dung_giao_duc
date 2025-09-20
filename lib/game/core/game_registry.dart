import 'package:flutter/material.dart';

/// 1) Mô tả game
class GameInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String route;              // Route để khởi chạy game
  final Color primaryColor;        // Màu chủ đạo
  final Color secondaryColor;      // Màu phụ

  const GameInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.route,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

/// 2) Danh sách game có thêm "An Toàn Bơi Lội"
class GameRegistry {
  static final List<GameInfo> games = [
    GameInfo(
      id: 'recycle_sort',
      name: 'Phân Loại Rác',
      description: 'Kéo rác vào đúng thùng hữu cơ hoặc vô cơ.',
      icon: Icons.recycling,
      route: '/game/recycle',
      primaryColor: Colors.green,
      secondaryColor: Colors.lightGreenAccent,
    ),
    GameInfo(
      id: 'traffic_safety',
      name: 'An Toàn Giao Thông',
      description: 'Chọn phương án đúng cho các tình huống giao thông.',
      icon: Icons.traffic,
      route: '/game/traffic_safety',
      primaryColor: Colors.orange,
      secondaryColor: Colors.deepOrangeAccent,
    ),
    GameInfo(
      id: 'plant_care',
      name: 'Chăm Sóc Cây Trồng',
      description: 'Chăm sóc chậu cây theo đúng nhu cầu của chúng.',
      icon: Icons.local_florist,
      route: '/game/plant_care',
      primaryColor: Colors.blueAccent,
      secondaryColor: Colors.lightBlueAccent,
    ),
    // ⭐ MỤC MỚI: An Toàn Bơi Lội
    GameInfo(
      id: 'swimming_safety',
      name: 'An Toàn Bơi Lội',
      description: 'Học kỹ năng an toàn khi ở hồ bơi, sông hồ, bãi biển.',
      icon: Icons.pool_rounded,
      route: '/game/swimming_safety',
      primaryColor: Colors.cyan,
      secondaryColor: Colors.lightBlueAccent,
    ),
  ];

  /// (Tuỳ chọn) tiện tra cứu nhanh
  static GameInfo? byId(String id) =>
      games.firstWhere((g) => g.id == id, orElse: () => games.first);

  static GameInfo? byRoute(String route) =>
      games.firstWhere((g) => g.route == route, orElse: () => games.first);
}
