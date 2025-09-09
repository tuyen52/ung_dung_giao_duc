import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Đảm bảo đã cài đặt trong pubspec.yaml
import 'package:firebase_auth/firebase_auth.dart';
import '../services/tre_service.dart';
import '../models/tre.dart';
import 'learning_progress_screen.dart';
import 'edit_parent_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final FirebaseAuth _auth;
  User? _user;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _user = _auth.currentUser;

    _auth.userChanges().listen((u) {
      if (!mounted) return;
      setState(() => _user = u);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hồ Sơ Của Tôi',
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
                Color(0xFFBA68C8),
                Color(0xFF8E24AA),
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
              Color(0xFFE0C3FC),
              Color(0xFF8EC5FC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: user == null
            ? Center(
          child: Text(
            'Vui lòng đăng nhập',
            style: GoogleFonts.balsamiqSans(color: Colors.white, fontSize: 18),
          ),
        )
            : ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildProfileSection(
              title: 'Phụ Huynh:',
              icon: Icons.person_pin,
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditParentScreen()),
                );
              },
              children: [
                _buildInfoLine(
                  'Họ và tên',
                  user.displayName ?? '—',
                  Icons.badge_outlined,
                ),
                _buildInfoLine(
                  'Email',
                  user.email ?? '—',
                  Icons.email_outlined,
                ),
                _buildInfoLine(
                  'Số điện thoại',
                  user.phoneNumber ?? '—',
                  Icons.phone_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildProfileSection(
              title: 'Trẻ:',
              icon: Icons.child_care,
              children: [
                _ChildrenList(parentUid: user.uid),
              ],
            ),
            const SizedBox(height: 30),
            _buildActionButton(
              label: 'Xem Tiến Độ Học',
              icon: Icons.timeline_rounded,
              color: const Color(0xFFFFA726),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LearningProgressScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              label: 'Đăng Xuất',
              icon: Icons.logout_rounded,
              color: Colors.redAccent,
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi đăng xuất: $e', style: GoogleFonts.balsamiqSans())),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    VoidCallback? onEdit,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.balsamiqSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6A1B9A),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: Icon(Icons.edit, color: const Color(0xFFBA68C8), size: 24),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLine(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFBA68C8), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: GoogleFonts.balsamiqSans(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.balsamiqSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.balsamiqSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
        shadowColor: color.withOpacity(0.5),
      ),
    );
  }
}

class _ChildrenList extends StatelessWidget {
  const _ChildrenList({required this.parentUid});
  final String parentUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tre>>(
      stream: TreService().watchTreList(parentUid),
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Lỗi tải danh sách trẻ: ${snap.error}',
              style: GoogleFonts.balsamiqSans(color: Colors.red),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A))),
          );
        }
        final list = snap.data ?? const <Tre>[];
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Chưa có hồ sơ trẻ.',
              style: GoogleFonts.balsamiqSans(color: Colors.grey[700]),
            ),
          );
        }
        return Column(
          children: list.map((t) {
            final isMale = t.gioiTinh.toLowerCase() == 'nam';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isMale ? Colors.lightBlueAccent : Colors.pinkAccent,
                  radius: 25,
                  child: Icon(isMale ? Icons.boy_rounded : Icons.girl_rounded, color: Colors.white, size: 30),
                ),
                title: Text(
                  t.hoTen.isEmpty ? 'Bé' : t.hoTen,
                  style: GoogleFonts.balsamiqSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Giới tính: ${t.gioiTinh.isEmpty ? "—" : t.gioiTinh}',
                  style: GoogleFonts.balsamiqSans(color: Colors.grey[600]),
                ),
                onTap: () {
                  // Có thể điều hướng đến màn hình chi tiết trẻ
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}