import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập thành công')),
      );
      Navigator.pushReplacementNamed(context, '/shell');
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Đăng nhập thất bại';
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
            // Gradient mới: xanh lá cây và vàng kem tươi sáng
            colors: [Color(0xFFA7FFEB), Color(0xFFDCEDC8)], // Từ xanh bạc hà sang xanh lá kem nhạt
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  elevation: 15,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                  margin: EdgeInsets.zero,
                  color: Colors.white, // Màu trắng tinh khiết cho Card
                  shadowColor: const Color(0xFF80CBC4).withOpacity(0.6), // Màu đổ bóng mềm mại, tông xanh
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon chủ đề phát triển trẻ em với màu sắc mới
                          Container(
                            padding: const EdgeInsets.all(20),
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
                              Icons.child_care_outlined, // Icon trẻ em/chăm sóc
                              size: 50,
                              color: Color(0xFF00796B), // Màu xanh lá cây đậm
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Cùng Bé',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
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
                          const Text(
                            'Trưởng Thành',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF00897B), // Màu xanh ngọc tươi
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
                            'Phát triển toàn diện, tự tin vươn xa!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              color: Color(0xFF26A69A), // Màu xanh ngọc sáng
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Trường Email/Tên Đăng Nhập
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              hintText: 'Email hoặc Tên đăng nhập',
                              hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF26A69A)), // Icon màu xanh
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFFB2DFDB), width: 1.5), // Màu border nhạt
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFF00897B), width: 2), // Màu border đậm
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF0FDFD), // Nền trắng xanh rất nhạt
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập email hoặc tên đăng nhập' : null,
                            cursorColor: const Color(0xFF00897B),
                          ),
                          const SizedBox(height: 20),
                          // Trường Mật Khẩu
                          TextFormField(
                            controller: _passCtrl,
                            decoration: InputDecoration(
                              hintText: 'Mật khẩu',
                              hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF26A69A)), // Icon màu xanh
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
                                  _obscure ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF00897B), // Icon ẩn/hiện mật khẩu màu xanh
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            obscureText: _obscure,
                            validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                            cursorColor: const Color(0xFF00897B),
                          ),
                          const SizedBox(height: 25),
                          // Nút "Quên mật khẩu?"
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _busy ? null : () {
                                // Xử lý quên mật khẩu
                              },
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: Color(0xFF26A69A), // Màu xanh ngọc sáng
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),
                          // Nút "Đăng Nhập" với gradient và đổ bóng mới
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
                              onPressed: _busy ? null : _login,
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
                                'Đăng Nhập',
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
                          // "Chưa có tài khoản? Đăng ký"
                          TextButton(
                            onPressed: _busy ? null : () => Navigator.pushReplacementNamed(context, '/signup'),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Chưa có tài khoản? ',
                                style: TextStyle(
                                  color: Color(0xFF26A69A), // Màu xanh ngọc sáng
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Đăng Ký',
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