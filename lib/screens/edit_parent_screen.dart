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
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // load từ DB
    final dbData = await UserService().getProfile(user.uid);
    if (dbData != null) {
      _nameCtrl.text = dbData['name'] ?? '';
      _usernameCtrl.text = dbData['username'] ?? '';
      _emailCtrl.text = dbData['email'] ?? user.email ?? '';
      _phoneCtrl.text = dbData['phone'] ?? user.phoneNumber ?? '';
    } else {
      // fallback
      _nameCtrl.text = user.displayName ?? '';
      _emailCtrl.text = user.email ?? '';
      _phoneCtrl.text = user.phoneNumber ?? '';
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await UserService().saveProfile(
      uid: user.uid,
      name: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật thành công!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa phụ huynh')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Họ và tên'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Số điện thoại'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: const Text('Lưu thay đổi'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
