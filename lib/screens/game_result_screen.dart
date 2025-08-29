import 'package:flutter/material.dart';
import 'reward_screen.dart';

class GameResultScreen extends StatelessWidget {
  final String treId;
  final String treName;
  final int correct;
  final int wrong;
  final int score;

  const GameResultScreen({
    super.key,
    required this.treId,
    required this.treName,
    required this.correct,
    required this.wrong,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả ván chơi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(treName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    children: [
                      const Text('Điểm nhận được', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('+$score',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.teal)),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _stat('Đúng', correct, Icons.check_circle, Colors.green),
                        const SizedBox(width: 24),
                        _stat('Sai', wrong, Icons.cancel, Colors.red),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
  icon: const Icon(Icons.star),
  label: const Text('Xem bảng thưởng'),   // 👈 thay child bằng label
  onPressed: () => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => RewardScreen(treId: treId)),
  ),
),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color), const SizedBox(width: 6), Text('$label: $value'),
    ]);
  }
}
