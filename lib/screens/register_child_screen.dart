import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/tre_service.dart';

class RegisterChildScreen extends StatefulWidget {
  const RegisterChildScreen({super.key});

  @override
  State<RegisterChildScreen> createState() => _RegisterChildScreenState();
}

class _RegisterChildScreenState extends State<RegisterChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoTenCtrl = TextEditingController();
  final _gioiTinhCtrl = TextEditingController();
  final _ngaySinhCtrl = TextEditingController(); // giữ dạng text cho đúng yêu cầu
  final _soThichCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _hoTenCtrl.dispose();
    _gioiTinhCtrl.dispose();
    _ngaySinhCtrl.dispose();
    _soThichCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn cần đăng nhập trước')),
        );
        return;
      }
      await TreService().addTre(
        parentId: user.uid,
        hoTen: _hoTenCtrl.text.trim(),
        gioiTinh: _gioiTinhCtrl.text.trim(),
        ngaySinh: _ngaySinhCtrl.text.trim(),
        soThich: _soThichCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Ký Hồ Sơ Trẻ')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _hoTenCtrl,
                  decoration: const InputDecoration(hintText: 'Họ tên', labelText: 'Họ tên'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _gioiTinhCtrl,
                  decoration: const InputDecoration(hintText: 'Giới tính', labelText: 'Giới tính'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ngaySinhCtrl,
                  decoration: const InputDecoration(hintText: 'Ngày sinh', labelText: 'Ngày sinh'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _soThichCtrl,
                  decoration: const InputDecoration(hintText: 'Sở thích', labelText: 'Sở thích'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy ? const CircularProgressIndicator() : const Text('Lưu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
