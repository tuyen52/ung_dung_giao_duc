// lib/screens/edit_parent_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class EditParentScreen extends StatefulWidget {
  const EditParentScreen({super.key});

  @override
  State<EditParentScreen> createState() => _EditParentScreenState();
}

class _EditParentScreenState extends State<EditParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();   // sẽ bị khóa (enabled: false)
  final _phone = TextEditingController();
  final _address = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final profile = await _userService.getProfile(u.uid);
      _name.text     = (profile?['name'] ?? u.displayName ?? '').toString();
      _username.text = (profile?['username'] ?? _deriveUsername(u.email ?? 'user@${u.uid}', u.uid)).toString();
      _email.text    = (profile?['email'] ?? u.email ?? '').toString(); // KHÓA
      _phone.text    = (profile?['phone'] ?? u.phoneNumber ?? '').toString();
      _address.text  = (profile?['address'] ?? '').toString();
    } catch (_) {
      // bỏ qua lỗi nạp — sẽ dùng fallback từ Auth
      _name.text     = (u.displayName ?? '').toString();
      _username.text = _deriveUsername(u.email ?? 'user@${u.uid}', u.uid);
      _email.text    = (u.email ?? '').toString();
      _phone.text    = (u.phoneNumber ?? '').toString();
      _address.text  = '';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    setState(() => _saving = true);
    try {
      // KHÔNG cập nhật email ở đây
      await _userService.upsertProfile(
        uid: u.uid,
        name: _name.text.trim(),
        username: _username.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );
      // Đồng bộ displayName cho Auth
      if (_name.text.trim().isNotEmpty) {
        await _userService.updateAuthDisplayName(_name.text.trim());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu hồ sơ')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ===== EMAIL BỊ KHÓA =====
              TextFormField(
                controller: _email,
                enabled: false,                // khóa hoàn toàn
                readOnly: true,                // tránh focus/keyboard
                enableInteractiveSelection: false, // không cho select & xoá
                decoration: const InputDecoration(
                  labelText: 'Email (không chỉnh tại đây)',
                  helperText: 'Muốn đổi email: dùng nút "Đổi email" ở màn Hồ sơ.',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _deriveUsername(String emailOrElse, String uid) {
    final at = emailOrElse.indexOf('@');
    if (at > 0) return emailOrElse.substring(0, at);
    return 'user_${uid.substring(0, 6)}';
  }
}
