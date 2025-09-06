import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart'; // Đảm bảo đường dẫn này đúng

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
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu nhập lại không khớp')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      // Tạo tài khoản Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // GHI HỒ SƠ USER (Realtime Database)
      // Đảm bảo UserService và phương thức saveProfile của bạn hoạt động đúng cách
      await UserService().saveProfile(
        uid: cred.user!.uid,
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Gradient xanh lá cây và vàng kem tươi sáng
            colors: [Color(0xFFA7FFEB), Color(0xFFDCEDC8)], // Từ xanh bạc hà sang xanh lá kem nhạt
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 15,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35), // Bo tròn mềm mại
                ),
                margin: const EdgeInsets.all(24), // Margin cho card
                color: Colors.white,
                shadowColor: const Color(0xFF80CBC4).withOpacity(0.6),
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Icon đăng ký
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1), // Màu xanh rất nhạt
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF80CBC4).withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_outlined, // Icon thêm người dùng
                              size: 45,
                              color: Color(0xFF00796B), // Màu xanh lá cây đậm
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Đăng Ký Tài Khoản',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28, // Kích thước lớn hơn
                              fontWeight: FontWeight.w900, // Rất đậm
                              color: Color(0xFF004D40), // Màu xanh rất đậm
                              shadows: [
                                Shadow(
                                  blurRadius: 5.0,
                                  color: Color.fromRGBO(0, 0, 0, 0.1),
                                  offset: Offset(2.0, 2.0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Hãy cùng chúng tôi xây dựng một cộng đồng tuyệt vời!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF26A69A), // Màu xanh ngọc sáng
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Họ và tên
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'Họ và tên',
                              hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF26A69A)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFFB2DFDB), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF0FDFD),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Họ và tên là bắt buộc' : null,
                            cursorColor: const Color(0xFF00897B),
                          ),
                          const SizedBox(height: 18),
                          // Tên đăng nhập
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: InputDecoration(
                              hintText: 'Tên đăng nhập',
                              hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
                              prefixIcon: const Icon(Icons.person_pin_outlined, color: Color(0xFF26A69A)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFFB2DFDB), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF0FDFD),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Tên đăng nhập là bắt buộc' : null,
                            cursorColor: const Color(0xFF00897B),
                          ),
                          const SizedBox(height: 18),
                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF26A69A)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFFB2DFDB), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF0FDFD),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
                            cursorColor: const Color(0xFF00897B),
                          ),
                          const SizedBox(height: 18),
                          // Số điện thoại
                          TextFormField(
                            controller: _phoneCtrl,
                            decoration: InputDecoration(
                              hintText: 'Số điện thoại',
                              hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
                              prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF26A69A)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFFB2DFDB), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF0FDFD),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().length < 8) ? 'Số điện thoại không hợp lệ' : null,
                            cursorColor: const Color(0xFF00897B),
                          ),
                          const SizedBox(height: 18),
                          // Mật khẩu
                          TextFormField(
                            controller: _passCtrl,
                            decoration: InputDecoration(
                              hintText: 'Mật khẩu',
                              hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF26A69A)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFFB2DFDB), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF0FDFD),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure1 ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF00897B),
                                ),
                                onPressed: () => setState(() => _obscure1 = !_obscure1),
                              ),
                            ),
                            obscureText: _obscure1,
                            validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                            cursorColor: const Color(0xFF00897B),
                          ),
                          const SizedBox(height: 18),
                          // Nhập lại mật khẩu
                          TextFormField(
                            controller: _confirmCtrl,
                            decoration: InputDecoration(
                              hintText: 'Nhập lại mật khẩu',
                              hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
                              prefixIcon: const Icon(Icons.lock_reset_outlined, color: Color(0xFF26A69A)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFFB2DFDB), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF0FDFD),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure2 ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF00897B),
                                ),
                                onPressed: () => setState(() => _obscure2 = !_obscure2),
                              ),
                            ),
                            obscureText: _obscure2,
                            validator: (v) => (v != _passCtrl.text) ? 'Mật khẩu không khớp' : null,
                            cursorColor: const Color(0xFF00897B),
                          ),
                          const SizedBox(height: 35),
                          // Nút "Đăng ký"
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00BFA5), Color(0xFF26A69A)], // Gradient xanh ngọc tươi
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00BFA5).withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: FilledButton(
                              onPressed: _busy ? null : _signup,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: _busy
                                  ? const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.5),
                              )
                                  : const Text(
                                'Đăng Ký',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // "Đã có tài khoản? Đăng nhập"
                          TextButton(
                            onPressed: _busy ? null : () => Navigator.pushReplacementNamed(context, '/login'),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Đã có tài khoản? ',
                                style: TextStyle(
                                  color: Color(0xFF26A69A), // Màu xanh ngọc sáng
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Đăng nhập',
                                    style: TextStyle(
                                      color: Color(0xFF00897B), // Màu xanh ngọc đậm hơn
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }
}