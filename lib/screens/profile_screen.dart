import 'package:flutter/material.dart';
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

    // Lắng nghe thay đổi đăng nhập để tránh state “đỏ màn”
    _auth.userChanges().listen((u) {
      if (!mounted) return;
      setState(() => _user = u);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(title: const Text('Thông Tin Hồ Sơ')),
      body: user == null
          ? const Center(child: Text('Vui lòng đăng nhập'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('Phụ Huynh:'),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line('Họ và tên', user.displayName ?? '—'),
                        _line('Email', user.email ?? '—'),
                        _line('Số điện thoại', user.phoneNumber ?? '—'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const EditParentScreen()),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Chỉnh sửa'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _sectionTitle('Trẻ:'),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _ChildrenList(parentUid: user.uid),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LearningProgressScreen()),
  ),
  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
  child: const Text('Xem Tiến Độ Học'),
),

                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi đăng xuất: $e')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Đăng Xuất'),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
      );

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text('$k:')),
            Expanded(flex: 5, child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _ChildrenList extends StatelessWidget {
  const _ChildrenList({required this.parentUid});
  final String parentUid;

  @override
  Widget build(BuildContext context) {
    // Bọc try/catch + errorBuilder để tránh “đỏ màn”
    return StreamBuilder<List<Tre>>(
      stream: TreService().watchTreList(parentUid),
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Lỗi tải danh sách trẻ: ${snap.error}', style: const TextStyle(color: Colors.red)),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final list = snap.data ?? const <Tre>[];
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Chưa có hồ sơ trẻ.'),
          );
        }
        return Column(
          children: list.map((t) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.child_care)),
              title: Text(t.hoTen.isEmpty ? 'Bé' : t.hoTen),
              subtitle: Text(
                'Giới tính: ${t.gioiTinh.isEmpty ? "—" : t.gioiTinh}  •  '
                'Ngày sinh: ${t.ngaySinh.isEmpty ? "—" : t.ngaySinh}',
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
