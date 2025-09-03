// lib/game/plant_care/data/plant_care_data.dart
import 'package:flutter/material.dart';
import '../plant_care_play_screen.dart';

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

// 4. Đường dẫn hình ảnh
const Map<PlantStage, String> plantImagePaths = {
  PlantStage.hatGiong: 'assets/images/hat_giong.jpg',
  PlantStage.cayCon: 'assets/images/cay_con.jpg',
  PlantStage.truongThanh: 'assets/images/truong_thanh.jpg',
  PlantStage.raHoa: 'assets/images/ra_hoa.jpg',
};

// 5. Tên mô tả giai đoạn
const Map<PlantStage, String> plantStageDescriptiveNames = {
  PlantStage.hatGiong: 'Hạt giống',
  PlantStage.cayCon: 'Cây con',
  PlantStage.truongThanh: 'Trưởng thành',
  PlantStage.raHoa: 'Ra hoa',
};