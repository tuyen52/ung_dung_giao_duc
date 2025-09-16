// lib/game/plant_care/data/plant_care_data.dart
import 'package:flutter/material.dart';

/// ====== Core enums & models ======
enum PlantType { normal, cactus, fern }
enum PlantStage { hatGiong, cayCon, truongThanh, raHoa }
enum CareToolType { nuoc, anhSang, thuocTruSau, catTia, phanBon }

class CareTool {
  final String label;
  final IconData icon;
  final CareToolType type;
  final String explanation;
  const CareTool(this.label, this.icon, this.type, this.explanation);
}

/// Khoảng tối ưu (ví dụ 60–80)
class Range {
  final double low;
  final double high;
  const Range(this.low, this.high);

  bool contains(double v) => v >= low && v <= high;
  String get label => '${low.toInt()}–${high.toInt()}%';
}

/// ====== Đặc tính theo loài ======
class PlantSpecies {
  final PlantType type;
  final String name;

  /// Hệ số hao hụt mỗi ngày
  final double waterNeed;
  final double lightNeed;

  /// Ngưỡng “quá nhiều” → phạt (sau tác động)
  final double waterTolerance;   // ví dụ: xương rồng dễ úng nếu > 70
  final double lightTolerance;   // ví dụ: dương xỉ dễ cháy nắng nếu > 80
  final double nutrientTolerance; // bón quá tay gây “cháy rễ”

  /// Vùng tối ưu – dùng để chấm “đúng/sai”
  final Range optimalWater;
  final Range optimalLight;
  final Range optimalNutrient;

  const PlantSpecies({
    required this.type,
    required this.name,
    this.waterNeed = 1.0,
    this.lightNeed = 1.0,
    this.waterTolerance = 100.0,
    this.lightTolerance = 100.0,
    this.nutrientTolerance = 95.0,
    required this.optimalWater,
    required this.optimalLight,
    required this.optimalNutrient,
  });
}

const Map<PlantType, PlantSpecies> plantSpeciesData = {
  PlantType.normal: PlantSpecies(
    type: PlantType.normal,
    name: 'Cây Thường',
    waterNeed: 1.0,
    lightNeed: 1.0,
    waterTolerance: 95.0,
    lightTolerance: 95.0,
    nutrientTolerance: 95.0,
    optimalWater: Range(55, 80),
    optimalLight: Range(55, 80),
    optimalNutrient: Range(55, 80),
  ),
  PlantType.cactus: PlantSpecies(
    type: PlantType.cactus,
    name: 'Xương Rồng',
    waterNeed: 0.5,          // cần ít nước
    lightNeed: 1.5,          // cần nhiều sáng
    waterTolerance: 70.0,    // dễ úng nếu > 70
    lightTolerance: 100.0,   // chịu sáng mạnh
    nutrientTolerance: 90.0, // dễ “cháy rễ” nếu bón quá tay
    optimalWater: Range(30, 60),
    optimalLight: Range(70, 90),
    optimalNutrient: Range(50, 80),
  ),
  PlantType.fern: PlantSpecies(
    type: PlantType.fern,
    name: 'Dương Xỉ',
    waterNeed: 1.5,          // cần nhiều nước
    lightNeed: 0.7,          // cần ít sáng
    waterTolerance: 100.0,
    lightTolerance: 80.0,    // dễ “cháy nắng” nếu > 80
    nutrientTolerance: 95.0,
    optimalWater: Range(70, 90),
    optimalLight: Range(40, 70),
    optimalNutrient: Range(55, 80),
  ),
};

/// ====== Bộ công cụ ======
const List<CareTool> plantCareTools = [
  CareTool('Tưới Nước', Icons.water_drop, CareToolType.nuoc,
      'Chính xác! Nước rất cần thiết cho cây.'),
  CareTool('Thêm Sáng', Icons.light_mode, CareToolType.anhSang,
      'Đúng rồi! Ánh sáng cung cấp năng lượng cho cây.'),
  CareTool('Bắt Sâu', Icons.bug_report, CareToolType.thuocTruSau,
      'Tuyệt vời! Cây đã được bảo vệ khỏi sâu bệnh.'),
  CareTool('Tỉa Cành', Icons.cut, CareToolType.catTia,
      'Chính xác! Tỉa cành giúp cây tập trung dinh dưỡng.'),
  CareTool('Bón Phân', Icons.eco, CareToolType.phanBon,
      'Rất tốt! Phân bón cung cấp thêm dinh dưỡng cho cây.'),
];

/// ====== Tên giai đoạn “sáng tạo” (hiển thị trên thẻ) ======
const Map<PlantStage, String> plantStageCreativeNames = {
  PlantStage.hatGiong: 'Mầm Xinh',
  PlantStage.cayCon: 'Chồi Non',
  PlantStage.truongThanh: 'Cây Trưởng Thành',
  PlantStage.raHoa: 'Cây Sắp Nở Hoa',
};

/// ====== Đường dẫn hình ảnh theo loài & giai đoạn ======
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
    PlantStage.hatGiong: 'assets/images/plant/fern_hat_giong.png', // chú ý .jpg
    PlantStage.cayCon: 'assets/images/plant/fern_cay_con.png',
    PlantStage.truongThanh: 'assets/images/plant/fern_truong_thanh.png',
    PlantStage.raHoa: 'assets/images/plant/fern_ra_hoa.png',
  },
};

/// ====== Tên mô tả giai đoạn ======
const Map<PlantStage, String> plantStageDescriptiveNames = {
  PlantStage.hatGiong: 'Hạt giống',
  PlantStage.cayCon: 'Cây con',
  PlantStage.truongThanh: 'Trưởng thành',
  PlantStage.raHoa: 'Ra hoa',
};

/// ====== Helper: emoji & câu mô tả rõ ràng theo loài ======
const Map<PlantType, String> speciesEmoji = {
  PlantType.normal: '🪴',
  PlantType.cactus: '🌵',
  PlantType.fern: '🌿',
};

/// Mô tả ngắn gọn, rõ ràng đặc tính & vùng tối ưu + cảnh báo vượt ngưỡng
String speciesHint(PlantSpecies s) {
  final e = speciesEmoji[s.type] ?? '🪴';
  final water = s.optimalWater.label;
  final light = s.optimalLight.label;
  final nutrient = s.optimalNutrient.label;

  final waterWarn = s.waterTolerance < 100
      ? '• Nước > ${s.waterTolerance.toInt()}% dễ úng.'
      : '• Chịu nước tương đối, nhưng vẫn nên “vừa đủ”.';
  final lightWarn = s.lightTolerance < 100
      ? '• Ánh sáng > ${s.lightTolerance.toInt()}% dễ cháy lá.'
      : '• Ưa nắng mạnh, ít khi cháy lá.';
  final nutrientWarn = '• Bón > ${s.nutrientTolerance.toInt()}% dễ “cháy rễ”.';

  return '$e ${s.name}\n'
      '• Nước tối ưu: $water\n'
      '• Ánh sáng tối ưu: $light\n'
      '• Dinh dưỡng tối ưu: $nutrient\n'
      '$waterWarn\n$lightWarn\n$nutrientWarn';
}
