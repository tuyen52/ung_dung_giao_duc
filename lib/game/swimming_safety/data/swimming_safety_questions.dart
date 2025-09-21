// lib/game/swimming_safety/data/swimming_safety_questions.dart
import '../swimming_safety_play_screen.dart';

/// Defines the pool of questions for the Swimming Safety game.
const List<Question> swimmingSafetyQuestionsPool = [
  Question(
    id: 'q1',
    situation: 'Trước khi xuống hồ bơi, em nên làm gì đầu tiên?',
    icon: '🚿',
    options: ['Ăn thật no', 'Tắm tráng, làm sạch cơ thể', 'Chạy nhảy quanh hồ'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q2',
    situation: 'Khi đang bơi mà cảm thấy mệt hoặc bị chuột rút, em nên làm gì?',
    icon: '🆘',
    options: ['Cố bơi thật nhanh vào bờ', 'Bình tĩnh, gọi người lớn giúp đỡ', 'Tiếp tục bơi'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q3',
    situation: 'Em không nên đi bơi ở đâu khi không có người lớn đi cùng?',
    icon: '🚫',
    options: ['Hồ bơi công cộng', 'Sông, hồ, biển', 'Bể bơi phao ở nhà'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q_safe_to_swim',
    situation: 'Chọn hình ảnh cho thấy hành động đúng đắn khi ở hồ bơi:',
    icon: '🏊',
    options: [
      'assets/images/swimming/hinh_dung.png', // Hành động đúng
      'assets/images/swimming/hinh_sai_1.png', // Hành động sai
      'assets/images/swimming/hinh_sai_2.png',     // Hành động sai
      'assets/images/swimming/hinh_sai_3.png',   // Hành động sai
    ],
    correctAnswerIndices: [0],
    type: QuestionType.imageSelection,
  ),
  // Bắt đầu 9 câu hỏi mới
  Question(
    id: 'q5',
    situation: 'Nếu thấy bạn bị đuối nước, em sẽ làm gì?',
    icon: '😱',
    options: ['Nhảy xuống cứu bạn', 'La to và gọi người lớn giúp đỡ', 'Lờ đi và bơi ra chỗ khác'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),

  Question(
    id: 'q6',
    situation: 'Vì sao em không được chạy nhảy ở khu vực quanh hồ bơi?',
    icon: '🏃‍♂️',
    options: ['Vì sẽ làm người khác chú ý', 'Vì sàn ướt, dễ bị trơn trượt và ngã', 'Vì sẽ làm bắn nước vào người khác'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q7',
    situation: 'Em nên bơi ở khu vực nào của hồ bơi?',
    icon: '📏',
    options: ['Khu vực nước sâu nhất', 'Khu vực dành cho trẻ em, có mực nước phù hợp', 'Bất cứ đâu em thích'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q8',
    situation: 'Khi bơi ngoài trời nắng, em nên làm gì để bảo vệ da?',
    icon: '☀️',
    options: ['Bôi kem chống nắng', 'Mặc áo khoác dày', 'Không cần làm gì cả'],
    correctAnswerIndices: [0],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q9',
    situation: 'Tại sao em không nên xô đẩy, đùa nghịch mạnh với bạn ở gần hồ bơi?',
    icon: '🤝',
    options: ['Vì bạn có thể ngã xuống hồ rất nguy hiểm', 'Vì làm vậy rất vui', 'Vì sẽ bị bố mẹ mắng'],
    correctAnswerIndices: [0],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q10',
    situation: 'Nếu trời nổi giông bão, sấm sét khi đang bơi, em nên làm gì?',
    icon: '⛈️',
    options: ['Cố bơi thêm một chút', 'Nhanh chóng lên bờ và vào nơi trú ẩn an toàn', 'Đứng dưới gốc cây to gần đó'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
  Question(
    id: 'q13',
    situation: 'Khi ở hồ bơi, em phải luôn lắng nghe ai nhất?',
    icon: '👨‍🏫',
    options: ['Bạn bè rủ rê', 'Bố mẹ, thầy cô hoặc chú cứu hộ', 'Tự ý làm điều mình thích'],
    correctAnswerIndices: [1],
    type: QuestionType.multipleChoice,
  ),
];