// lib/game/traffic_safety/data/traffic_safety_questions.dart
import 'package:mobileapp/game/traffic_safety/traffic_safety_play_screen.dart';

/// Defines the pool of questions for the Traffic Safety game.
const List<Question> trafficSafetyQuestionsPool = [
  Question(
    id: 'q1',
    situation: 'Khi đèn tín hiệu giao thông chuyển sang màu đỏ, em phải làm gì?',
    icon: '🚦',
    options: ['Đi tiếp', 'Dừng lại', 'Đi chậm lại', 'chạy nhanh qua'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q2',
    situation: 'Khi gặp đám đông trên vỉa hè, em nên làm gì để an toàn?',
    icon: '👥',
    options: ['Đi ra lòng đường', 'chạy nhanh qua đám đông', 'Đi chậm và cẩn thận trên vỉa hè','đi nhanh qua đám đông'],
    correctAnswerIndices: [2],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q3',
    situation: 'Khi đi xe buýt, em cần làm gì để an toàn?',
    icon: '🚌',
    options: ['Ngồi xuống và nắm tay vịn', 'Đứng gần cửa ra vào', 'Chạy quanh trong xe', 'Thò tay qua cửa sổ'],
    correctAnswerIndices: [0],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q4',
    situation: 'Trong cơn mưa bão, em nên làm gì khi đi bộ qua đường?',
    icon: '🌧️',
    options: ['Chạy thật nhanh', 'không dùng ô để dễ quan sát', 'Đi dưới lòng đường', 'Dùng ô và quan sát kỹ'],
    correctAnswerIndices: [3],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q5',
    situation: 'Sắp xếp các bước để qua đường an toàn theo thứ tự đúng:',
    icon: '🚸',
    options: ['Nhìn trái và phải', 'Dừng lại ở lề đường', 'Đi qua khi đường an toàn', 'Giơ tay ra hiệu'],
    correctAnswerIndices: [1, 0, 3, 2],
    type: QuestionType.sorting,
  ),
  // === CÂU HỎI CŨ ĐÃ ĐƯỢC THAY THẾ BẰNG CÂU HỎI MỚI DƯỚI ĐÂY ===
  Question(
    id: 'q_safe_to_walk', // ID mới có ý nghĩa hơn
    situation: ' đứa trẻ nào đang qua đường đúng cách nhất ?', // Nội dung câu hỏi mới, phù hợp
    icon: '🚶', // Thêm icon cho sinh động
    // Không có 'imagePath' để tránh gây nhầm lẫn
    options: [
      'assets/images/traffic/crossing-properly.png',
      'assets/images/traffic/crossing-nocrosswalk.png',
      'assets/images/traffic/crossing-incorrectly.png',
      'assets/images/traffic/crossing-no-traffic-lights.png',
    ],
    correctAnswerIndices: [0], // Đáp án đúng là lựa chọn đầu tiên
    type: QuestionType.imageSelection,
  ),
  Question(
    id: 'q7_helmet',
    situation: 'Khi ngồi trên xe máy, em phải làm gì để bảo vệ đầu?',
    icon: '🏍️',
    options: ['Đội mũ lưỡi trai', 'Không cần đội gì', 'Đội mũ bảo hiểm và cài quai đúng cách', 'Đội mũ len'],
    correctAnswerIndices: [2],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q8_play_area',
    situation: 'Đâu là nơi an toàn để em vui chơi?',
    icon: '⚽',
    options: ['Dưới lòng đường', 'Trên vỉa hè gần đường', 'Trong sân chơi hoặc công viên', 'Ở bãi đỗ xe'],
    correctAnswerIndices: [2],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q9_bus_stop',
    situation: 'Khi đợi xe buýt, em nên đứng ở đâu?',
    icon: '🚏',
    options: ['Đứng dưới lòng đường để vẫy xe', 'Đứng trật tự trên vỉa hè tại điểm chờ', 'Chạy nhảy lung tung', 'Đứng sau xe buýt'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q10_night_walk',
    situation: 'Khi đi bộ vào buổi tối, em nên mặc quần áo màu gì để người khác dễ nhìn thấy?',
    icon: '🌙',
    options: ['Màu tối như đen, xanh đậm', 'Màu sáng hoặc có phản quang', 'Màu gì cũng được', 'Mặc đồ có kim tuyến'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q11_animal_road',
    situation: 'Nếu thấy động vật trên đường, em nên làm gì?',
    icon: '🐕',
    options: ['Lại gần trêu chọc', 'Báo cho người lớn và đi chậm lại', 'Bóp còi inh ỏi', 'Cố gắng đuổi nó đi'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q12_bus_boarding', // id mới, duy nhất
    situation: 'Sắp xếp các bước lên xe buýt của trường một cách an toàn:',
    icon: '🚌',
    options: [
      'Bước lên xe và tìm chỗ ngồi',       // index 0
      'Chờ xe buýt dừng hẳn',             // index 1
      'Xếp hàng trật tự, không xô đẩy',    // index 2
      'Đứng cách lề đường 3 bước chân', // index 3
    ],
    correctAnswerIndices: [3, 1, 2, 0],
    type: QuestionType.sorting,
  ),
];