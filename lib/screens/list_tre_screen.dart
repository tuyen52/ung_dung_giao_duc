import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/tre.dart';
import '../services/tre_service.dart';
import 'tre_detail_screen.dart';
import 'register_child_screen.dart';

class ListTreScreen extends StatelessWidget {
  const ListTreScreen({super.key});

  Future<void> _addChild(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterChildScreen()),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nếu đã thêm hồ sơ, danh sách sẽ được cập nhật.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập', style: GoogleFonts.balsamiqSans()),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Hồ Sơ Của Bé',
          style: GoogleFonts.balsamiqSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
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
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Thêm Trẻ',
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 28),
            onPressed: () => _addChild(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Lớp nền Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE0C3FC), // Pastel Purple
                    Color(0xFF8EC5FC), // Pastel Blue
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Các lớp hình ảnh/icon trang trí động
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: -50,
            child: _buildAnimatedDecoration(Icons.star, 80, Colors.yellow.withOpacity(0.3), 3000),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1,
            right: -60,
            child: _buildAnimatedDecoration(Icons.favorite, 100, Colors.redAccent.withOpacity(0.3), 4000),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -30,
            child: _buildAnimatedDecoration(Icons.cloud_circle, 120, Colors.white.withOpacity(0.2), 5000),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2,
            left: -20,
            child: _buildAnimatedDecoration(Icons.local_florist, 90, Colors.pink.withOpacity(0.3), 3500),
          ),

          // Lớp nội dung chính
          StreamBuilder<List<Tre>>(
            stream: TreService().watchTreList(user.uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              final items = snap.data ?? const <Tre>[];
              if (items.isEmpty) {
                return _buildEmptyState(context);
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 80.0),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final tre = items[i];
                    return _buildTreCard(context, tre);
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addChild(context),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
        label: Text(
          'Thêm Trẻ',
          style: GoogleFonts.balsamiqSans(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 8,
      ),
    );
  }

  // Widget tạo hiệu ứng chuyển động
  Widget _buildAnimatedDecoration(IconData icon, double size, Color color, int duration) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: duration),
      curve: Curves.easeInOutSine,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * value), // Hiệu ứng lơ lửng
          child: Opacity(
            opacity: value,
            child: Icon(icon, size: size, color: color),
          ),
        );
      },
    );
  }

  Widget _buildTreCard(BuildContext context, Tre tre) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFBA68C8),
          radius: 30,
          child: tre.gioiTinh.toLowerCase() == 'nam'
              ? const Icon(Icons.boy_outlined, size: 30, color: Colors.white)
              : const Icon(Icons.girl_outlined, size: 30, color: Colors.white),
        ),
        title: Text(
          tre.hoTen.isEmpty ? 'Bé' : tre.hoTen,
          style: GoogleFonts.balsamiqSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          'Giới tính: ${tre.gioiTinh.isEmpty ? "—" : tre.gioiTinh}',
          style: GoogleFonts.balsamiqSans(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TreDetailScreen(tre: tre)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.child_friendly,
            size: 100,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có hồ sơ trẻ.',
            style: GoogleFonts.balsamiqSans(fontSize: 20, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thêm bé đầu tiên vào đây!',
            style: GoogleFonts.balsamiqSans(fontSize: 16, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addChild(context),
            icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF6A1B9A)),
            label: Text(
              'Thêm Trẻ',
              style: GoogleFonts.balsamiqSans(fontWeight: FontWeight.bold, color: const Color(0xFF6A1B9A)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 8,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
