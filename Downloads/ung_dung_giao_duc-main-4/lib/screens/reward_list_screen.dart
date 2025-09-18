import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/tre.dart';
import '../services/tre_service.dart';
import '../services/reward_service.dart';
import '../widgets/tre_reward_item.dart';
import 'reward_screen.dart';

class RewardListScreen extends StatelessWidget {
  const RewardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thành Tích Của Bé',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
              child: Text(
                'Danh sách điểm thưởng',
                style: GoogleFonts.balsamiqSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
            if (user == null)
              Expanded(
                child: Center(
                  child: Text(
                    'Vui lòng đăng nhập',
                    style: GoogleFonts.balsamiqSans(color: Colors.white),
                  ),
                ),
              )
            else
              Expanded(
                child: StreamBuilder<List<Tre>>(
                  stream: TreService().watchTreList(user.uid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    final list = snap.data ?? const <Tre>[];
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'Chưa có trẻ nào.',
                          style: GoogleFonts.balsamiqSans(color: Colors.white),
                        ),
                      );
                    }

                    // *** BẮT ĐẦU THAY ĐỔI: SỬ DỤNG ORIENTATION BUILDER ***
                    // OrientationBuilder sẽ tự động nhận diện hướng màn hình và build lại UI
                    return OrientationBuilder(
                      builder: (context, orientation) {
                        // Nếu là màn hình ngang, sử dụng GridView
                        if (orientation == Orientation.landscape) {
                          return _buildLandscapeLayout(list);
                        }
                        // Mặc định (màn hình đứng), sử dụng ListView
                        return _buildPortraitLayout(list);
                      },
                    );
                    // *** KẾT THÚC THAY ĐỔI ***
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Giao diện cho màn hình đứng (Portrait) - Giữ nguyên như cũ
  Widget _buildPortraitLayout(List<Tre> list) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final tre = list[i];
        return _buildTreRewardItem(tre);
      },
    );
  }

  // *** BẮT ĐẦU PHẦN MỚI: GIAO DIỆN CHO MÀN HÌNH NGANG (LANDSCAPE) ***
  Widget _buildLandscapeLayout(List<Tre> list) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      // Cấu hình GridView
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Hiển thị 2 cột
        crossAxisSpacing: 16, // Khoảng cách ngang giữa các item
        mainAxisSpacing: 16, // Khoảng cách dọc giữa các item
        childAspectRatio: 2.5, // Tỉ lệ chiều rộng/chiều cao của item
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final tre = list[i];
        // Sử dụng lại widget item đã có
        return _buildTreRewardItem(tre);
      },
    );
  }
  // *** KẾT THÚC PHẦN MỚI ***

  Widget _buildTreRewardItem(Tre tre) {
    return StreamBuilder(
      stream: RewardService().watchReward(tre.id),
      builder: (context, rewardSnap) {
        final reward = rewardSnap.data;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RewardScreen(treId: tre.id)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE0C3FC),
                    radius: 30,
                    child: Icon(
                      tre.gioiTinh.toLowerCase() == 'nam' ? Icons.boy_rounded : Icons.girl_rounded,
                      color: const Color(0xFF6A1B9A),
                      size: 35,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center, // Căn giữa nội dung trong cột
                      children: [
                        Text(
                          tre.hoTen.isEmpty ? 'Bé' : tre.hoTen,
                          style: GoogleFonts.balsamiqSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: const Color(0xFF6A1B9A),
                          ),
                          overflow: TextOverflow.ellipsis, // Tránh tràn chữ
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tổng điểm: ${reward?.points ?? 0}',
                          style: GoogleFonts.balsamiqSans(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Phần huy hiệu có thể giữ nguyên hoặc tùy chỉnh lại nếu cần
                  Row(
                    children: [
                      _badge(Icons.emoji_events, Colors.orange, reward?.gold ?? 0),
                      _badge(Icons.emoji_events, Colors.grey, reward?.silver ?? 0),
                      _badge(Icons.emoji_events, Colors.brown, reward?.bronze ?? 0),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _badge(IconData icon, Color color, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Giúp cột co lại vừa đủ nội dung
        children: [
          Icon(icon, color: color, size: 24),
          Text(
            '$count',
            style: GoogleFonts.balsamiqSans(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}