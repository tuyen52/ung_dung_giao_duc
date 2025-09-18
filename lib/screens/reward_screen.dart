import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Đảm bảo đã cài đặt trong pubspec.yaml
import '../services/reward_service.dart';
import '../models/reward.dart';

class RewardScreen extends StatelessWidget {
  final String treId;
  const RewardScreen({super.key, required this.treId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Điểm Thưởng Của Bé',
          style: GoogleFonts.balsamiqSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // AppBar trong suốt để gradient nền body hiển thị
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Đổi màu icon back thành trắng
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8EC5FC), // Màu xanh dương nhạt
                Color(0xFFE0C3FC), // Màu tím hồng nhạt
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
        child: StreamBuilder<Reward?>(
          stream: RewardService().watchReward(treId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            final reward = snap.data ?? Reward(treId: treId);

            return RefreshIndicator(
              onRefresh: () async {
                // Logic tải lại dữ liệu từ Firebase nếu cần (hiện tại StreamBuilder đã tự động làm)
                await Future.delayed(const Duration(seconds: 1)); // Mô phỏng tải lại
              },
              child: ListView(
                padding: const EdgeInsets.all(24),
                physics: const AlwaysScrollableScrollPhysics(), // Luôn cho phép cuộn để RefreshIndicator hoạt động
                children: [
                  _buildScoreCard(context, reward),
                  const SizedBox(height: 24),
                  _buildMedalCard(reward),
                  const SizedBox(height: 24),
                  _buildInfoCard(context, reward),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, Reward reward) {
    return Card(
      elevation: 10, // Tăng độ nổi bật
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // Bo tròn nhiều hơn
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFA726), // Orange
              Color(0xFFFFCC80), // Light Orange
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20), // Tăng padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.white, size: 50), // Icon lớn hơn
            const SizedBox(width: 16),
            Text(
              "${reward.points}",
              style: GoogleFonts.balsamiqSans(
                fontSize: 60, // Cỡ chữ lớn hơn
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 8.0,
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Điểm",
              style: GoogleFonts.balsamiqSans(
                fontSize: 28, // Cỡ chữ lớn hơn
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedalCard(Reward reward) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Thành Tích Huy Chương",
              style: GoogleFonts.balsamiqSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6A1B9A),
              ),
            ),
            const Divider(height: 30, color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _badge(
                  Icons.emoji_events, // Icon thay thế cho ảnh
                  "Vàng",
                  reward.gold,
                  const Color(0xFFFFD700), // Màu vàng cho huy chương vàng
                ),
                _badge(
                  Icons.emoji_events, // Icon thay thế cho ảnh
                  "Bạc",
                  reward.silver,
                  const Color(0xFFC0C0C0), // Màu bạc cho huy chương bạc
                ),
                _badge(
                  Icons.emoji_events, // Icon thay thế cho ảnh
                  "Đồng",
                  reward.bronze,
                  const Color(0xFFCD7F32), // Màu đồng cho huy chương đồng
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Reward reward) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Thông tin chi tiết",
              style: GoogleFonts.balsamiqSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6A1B9A),
              ),
            ),
            const Divider(height: 30, color: Colors.grey),
            Row(
              children: [
                Icon(Icons.access_time_filled, color: Colors.grey[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Cập nhật lần cuối: ${reward.lastUpdated ?? 'Chưa có'}",
                    style: GoogleFonts.balsamiqSans(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, int count, Color medalColor) {
    return Column(
      children: [
        Icon(icon, size: 50, color: medalColor), // Sử dụng Icon và màu sắc
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.balsamiqSans(
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        Text(
          "$count",
          style: GoogleFonts.balsamiqSans(
            fontSize: 24, // Cỡ chữ lớn hơn cho số lượng huy chương
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6A1B9A),
          ),
        ),
      ],
    );
  }
}