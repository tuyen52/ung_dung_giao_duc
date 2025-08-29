import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _busy = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      // Tạo tài khoản Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // GHI HỒ SƠ USER (Realtime Database)
      await UserService().saveProfile(
        uid: cred.user!.uid,
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );


      // Nếu bạn muốn lưu thêm name/username/phone vào Firestore hoặc RTDB,
      // hãy thêm code ghi DB tại đây (theo ý bạn).

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Đăng ký thất bại';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // giống layout XML bạn gửi
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Đăng ký tài khoản',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFF57C00))),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Họ và tên'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _usernameCtrl,
                          decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(labelText: 'Số điện thoại'),
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().length < 8) ? 'Số điện thoại không hợp lệ' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passCtrl,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            suffixIcon: IconButton(
                              icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure1 = !_obscure1),
                            ),
                          ),
                          obscureText: _obscure1,
                          validator: (v) => (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nhập lại mật khẩu',
                            suffixIcon: IconButton(
                              icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure2 = !_obscure2),
                            ),
                          ),
                          obscureText: _obscure2,
                          validator: (v) => (v != _passCtrl.text) ? 'Mật khẩu không khớp' : null,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _busy ? null : _signup,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          child: _busy ? const CircularProgressIndicator() : const Text('Đăng ký'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _busy ? null : () => Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text('Đã có tài khoản? Đăng nhập'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
