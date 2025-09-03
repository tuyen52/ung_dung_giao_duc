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
  Question(
    id: 'q6',
    situation: 'Chọn biển báo cấm đỗ xe:',
    imagePath: 'assets/images/traffic_signs.png',
    options: [
      'assets/images/no_parking.png',
      'assets/images/no_entry.png',
      'assets/images/speed_limit.png',
      'assets/images/pedestrian.png'
    ],
    correctAnswerIndices: [0],
    type: QuestionType.imageSelection,
  ),
];