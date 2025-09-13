// lib/game/plant_care/data/plant_care_data.dart
import 'package:flutter/material.dart';
import '../plant_care_play_screen.dart';


// NEW: Enum for different plant types
enum PlantType { normal, cactus, fern }

// NEW: Class to define the characteristics of each plant species
class PlantSpecies {
  final PlantType type;
  final String name;
  final double waterNeed; // Multiplier for water consumption
  final double lightNeed; // Multiplier for light consumption
  final double waterTolerance; // Max water level before damage
  final double lightTolerance; // Max light level before damage

  const PlantSpecies({
    required this.type,
    required this.name,
    this.waterNeed = 1.0,
    this.lightNeed = 1.0,
    this.waterTolerance = 100.0,
    this.lightTolerance = 100.0,
  });
}

// NEW: Database for plant species
const Map<PlantType, PlantSpecies> plantSpeciesData = {
  PlantType.normal: PlantSpecies(
    type: PlantType.normal,
    name: 'Cây Thường',
  ),
  PlantType.cactus: PlantSpecies(
    type: PlantType.cactus,
    name: 'Xương Rồng',
    waterNeed: 0.5, // Needs half the water
    lightNeed: 1.5, // Needs 50% more light
    waterTolerance: 70.0, // Health decreases if water > 70
  ),
  PlantType.fern: PlantSpecies(
    type: PlantType.fern,
    name: 'Dương Xỉ',
    waterNeed: 1.5, // Needs 50% more water
    lightNeed: 0.7, // Needs 30% less light
    lightTolerance: 80.0, // Health decreases if light > 80
  ),
};


// 1. Dữ liệu về các dụng cụ
const List<CareTool> plantCareTools = [
  CareTool('Tưới Nước', Icons.water_drop, CareToolType.nuoc, PlantIssue.datKho, 'Chính xác! Nước rất cần thiết cho cây.'),
  CareTool('Thêm Sáng', Icons.light_mode, CareToolType.anhSang, PlantIssue.thieuAnhSang, 'Đúng rồi! Ánh sáng cung cấp năng lượng cho cây.'),
  CareTool('Bắt Sâu', Icons.bug_report, CareToolType.thuocTruSau, PlantIssue.sauBenh, 'Tuyệt vời! Cây đã được bảo vệ khỏi sâu bệnh.'),
  CareTool('Tỉa Cành', Icons.cut, CareToolType.catTia, PlantIssue.quaTai, 'Chính xác! Tỉa cành giúp cây tập trung dinh dưỡng.'),
  CareTool('Bón Phân', Icons.eco, CareToolType.phanBon, PlantIssue.thieuChatDinhDuong, 'Rất tốt! Phân bón cung cấp thêm dinh dưỡng cho cây.'),
];

// 2. Các quy tắc của game: Vấn đề nào có thể xảy ra ở giai đoạn nào
const Map<PlantStage, List<PlantIssue>> plantStageRules = {
  PlantStage.hatGiong: [PlantIssue.datKho, PlantIssue.thieuAnhSang],
  PlantStage.cayCon: [PlantIssue.datKho, PlantIssue.thieuAnhSang, PlantIssue.sauBenh],
  PlantStage.truongThanh: [PlantIssue.quaTai, PlantIssue.thieuChatDinhDuong, PlantIssue.sauBenh],
  PlantStage.raHoa: [PlantIssue.sauBenh, PlantIssue.quaTai, PlantIssue.datKho],
};

// 3. Các nhãn/tên hiển thị
const Map<PlantStage, String> plantStageCreativeNames = {
  PlantStage.hatGiong: 'Mầm Xinh',
  PlantStage.cayCon: 'Chồi Non',
  PlantStage.truongThanh: 'Cây Trưởng Thành',
  PlantStage.raHoa: 'Cây Sắp Nở Hoa',
};

const Map<PlantIssue, String> plantIssueLabels = {
  PlantIssue.datKho: 'Đất khô',
  PlantIssue.thieuAnhSang: 'Thiếu sáng',
  PlantIssue.sauBenh: 'Có sâu bệnh',
  PlantIssue.quaTai: 'Quá um tùm',
  PlantIssue.thieuChatDinhDuong: 'Thiếu dinh dưỡng',
};

// 4. Đường dẫn hình ảnh (ĐÃ CẬP NHẬT)
const Map<PlantType, Map<PlantStage, String>> plantImagePaths = {
  PlantType.normal: {
    PlantStage.hatGiong: 'assets/images/plant/normal_hat_giong.png',
    PlantStage.cayCon: 'assets/images/plant/normal_cay_con.png',
    PlantStage.truongThanh: 'assets/images/plant/normal_truong_thanh.png',
    PlantStage.raHoa: 'assets/images/plant/normal_ra_hoa.png',
  },
  PlantType.cactus: {
    PlantStage.hatGiong: 'assets/images/plant/cactus_hat_giong.png',
    PlantStage.cayCon: 'assets/images/plant/cactus_cay_con.png',
    PlantStage.truongThanh: 'assets/images/plant/cactus_truong_thanh.png',
    PlantStage.raHoa: 'assets/images/plant/cactus_ra_hoa.png',
  },
  PlantType.fern: {
    PlantStage.hatGiong: 'assets/images/plant/fern_hat_giong.jpg',
    PlantStage.cayCon: 'assets/images/plant/fern_cay_con.png',
    PlantStage.truongThanh: 'assets/images/plant/fern_truong_thanh.png',
    PlantStage.raHoa: 'assets/images/plant/fern_ra_hoa.png',
  },
};

// 5. Tên mô tả giai đoạn
const Map<PlantStage, String> plantStageDescriptiveNames = {
  PlantStage.hatGiong: 'Hạt giống',
  PlantStage.cayCon: 'Cây con',
  PlantStage.truongThanh: 'Trưởng thành',
  PlantStage.raHoa: 'Ra hoa',
};