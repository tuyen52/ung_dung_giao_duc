// lib/game/traffic_safety/data/traffic_safety_questions.dart
import 'package:mobileapp/game/traffic_safety/traffic_safety_play_screen.dart';

/// Defines the pool of questions for the Traffic Safety game.
const List<Question> trafficSafetyQuestionsPool = [
  Question(
    id: 'q1',
    situation: 'Khi đèn tín hiệu giao thông chuyển sang màu đỏ, em phải làm gì?',
    icon: '🚦',
    options: ['Đi tiếp', 'Dừng lại', 'Đi chậm lại'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q2',
    situation: 'Khi gặp đám đông trên vỉa hè, em nên làm gì để an toàn?',
    icon: '👥',
    options: ['Đi ra lòng đường', 'Đi chậm và cẩn thận trên vỉa hè', 'Chạy nhanh qua đám đông'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q3',
    situation: 'Khi đi xe buýt, em cần làm gì để an toàn?',
    icon: '🚌',
    options: ['Đứng gần cửa ra vào', 'Ngồi xuống và nắm tay vịn', 'Chạy quanh trong xe'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q4',
    situation: 'Trong cơn mưa bão, em nên làm gì khi đi bộ qua đường?',
    icon: '🌧️',
    options: ['Chạy thật nhanh', 'Dùng ô và quan sát kỹ', 'Đi dưới lòng đường'],
    correctAnswerIndices: [1],
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
    situation: 'Đâu là nơi an toàn để em đi bộ?', // Nội dung câu hỏi mới, phù hợp
    icon: '🚶', // Thêm icon cho sinh động
    // Không có 'imagePath' để tránh gây nhầm lẫn
    options: [
      'assets/images/sidewalk.jpg',       // Giả sử đây là ảnh vỉa hè
      'assets/images/road_with_cars.jpg', // Giả sử đây là ảnh lòng đường
      'assets/images/playing_on_street.jpg', // Ví dụ: ảnh trẻ em chơi dưới lòng đường
      'assets/images/railway_track.jpg', // Ví dụ: ảnh đường ray xe lửa
    ],
    correctAnswerIndices: [0], // Đáp án đúng là lựa chọn đầu tiên
    type: QuestionType.imageSelection,
  ),
];