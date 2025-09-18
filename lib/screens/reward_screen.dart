import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: StreamBuilder<Reward?>(
          stream: RewardService().watchReward(treId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            final reward = snap.data ?? Reward(treId: treId);

            return RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: OrientationBuilder(
                builder: (context, orientation) {
                  if (orientation == Orientation.landscape) {
                    // Trả về giao diện cho màn hình ngang với bố cục mới
                    return _buildLandscapeLayout(context, reward);
                  } else {
                    // Trả về giao diện cho màn hình đứng
                    return _buildPortraitLayout(context, reward);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // Giao diện cho màn hình đứng (Portrait)
  Widget _buildPortraitLayout(BuildContext context, Reward reward) {
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildScoreCard(context, reward),
        const SizedBox(height: 24),
        _buildMedalCard(reward),
        const SizedBox(height: 24),
        _buildInfoCard(context, reward),
      ],
    );
  }

  // *** BẮT ĐẦU PHẦN MỚI: GIAO DIỆN NGANG VỚI BỐ CỤC 2 HÀNG ***
  Widget _buildLandscapeLayout(BuildContext context, Reward reward) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        // Cấu trúc chính là một cột
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hàng trên cùng chứa Điểm và Huy chương
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thẻ điểm chiếm 1 nửa bên trái
              Expanded(
                child: _buildScoreCard(context, reward),
              ),
              const SizedBox(width: 24),
              // Thẻ huy chương chiếm 1 nửa bên phải
              Expanded(
                child: _buildMedalCard(reward),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Hàng dưới cùng chứa thông tin chi tiết
          _buildInfoCard(context, reward),
        ],
      ),
    );
  }
  // *** KẾT THÚC PHẦN MỚI ***

  Widget _buildScoreCard(BuildContext context, Reward reward) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFA726),
              Color(0xFFFFCC80),
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
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.white, size: 50),
            const SizedBox(width: 16),
            Text(
              "${reward.points}",
              style: GoogleFonts.balsamiqSans(
                fontSize: 60,
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
                fontSize: 28,
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
                _badge(Icons.emoji_events, "Vàng", reward.gold, const Color(0xFFFFD700)),
                _badge(Icons.emoji_events, "Bạc", reward.silver, const Color(0xFFC0C0C0)),
                _badge(Icons.emoji_events, "Đồng", reward.bronze, const Color(0xFFCD7F32)),
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
        Icon(icon, size: 50, color: medalColor),
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6A1B9A),
          ),
        ),
      ],
    );
  }
}