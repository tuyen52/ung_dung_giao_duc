// lib/screens/list_tre_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tre.dart';
import '../services/tre_service.dart';
import 'tre_detail_screen.dart';
import 'register_child_screen.dart'; // 👈 màn thêm trẻ

class ListTreScreen extends StatelessWidget {
  const ListTreScreen({super.key});

  Future<void> _addChild(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterChildScreen()),
    );
    // Không cần làm gì thêm: StreamBuilder sẽ tự refresh khi DB thay đổi
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
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách trẻ'),
        actions: [
          IconButton(
            tooltip: 'Thêm Trẻ',
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => _addChild(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Tre>>(
        stream: TreService().watchTreList(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const <Tre>[];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có hồ sơ trẻ.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _addChild(context),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Thêm Trẻ'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final tre = items[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.child_care)),
                title: Text(tre.hoTen.isEmpty ? 'Bé' : tre.hoTen),
                subtitle: Text(
                  'Giới tính: ${tre.gioiTinh.isEmpty ? "—" : tre.gioiTinh}  •  '
                  'Ngày sinh: ${tre.ngaySinh.isEmpty ? "—" : tre.ngaySinh}',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TreDetailScreen(tre: tre)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addChild(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Trẻ'),
      ),
    );
  }
}
