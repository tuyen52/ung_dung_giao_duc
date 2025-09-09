import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      appBar: AppBar(
        title: Text(
          'Kết Quả Ván Chơi',
          style: GoogleFonts.balsamiqSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8EC5FC),
                Color(0xFFE0C3FC),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8EC5FC),
              Color(0xFFE0C3FC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  treName,
                  style: GoogleFonts.balsamiqSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          'Điểm nhận được',
                          style: GoogleFonts.balsamiqSans(
                            fontSize: 20,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+$score',
                          style: GoogleFonts.balsamiqSans(
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            color: Colors.teal,
                            shadows: [
                              Shadow(
                                blurRadius: 6.0,
                                color: Colors.teal.withOpacity(0.5),
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _stat('Đúng', correct, Icons.check_circle_rounded, Colors.green),
                            const SizedBox(width: 24),
                            _stat('Sai', wrong, Icons.cancel_rounded, Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FilledButton.icon(
                  icon: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
                  label: Text(
                    'Xem Bảng Thưởng',
                    style: GoogleFonts.balsamiqSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => RewardScreen(treId: treId)),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA726),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 8,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Đóng',
                    style: GoogleFonts.balsamiqSans(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.balsamiqSans(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$value',
              style: GoogleFonts.balsamiqSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
