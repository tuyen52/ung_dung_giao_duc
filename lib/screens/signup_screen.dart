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
    // Kiểm tra mật khẩu khớp nhau vẫn được giữ lại vì validator chỉ kiểm tra trên từng field
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu nhập lại không khớp')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

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

  // LOGIC MỚI: Phương thức kiểm tra email chặt chẽ
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email là bắt buộc';
    }
    const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    final regExp = RegExp(pattern);
    if (!regExp.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  // LOGIC MỚI: Phương thức kiểm tra số điện thoại
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số điện thoại là bắt buộc';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Số điện thoại chỉ được chứa ký tự số';
    }
    if (value.length < 8) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  // LOGIC MỚI: Phương thức kiểm tra mật khẩu mạnh
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu là bắt buộc';
    }
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasDigit = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialChar = RegExp(r'[!@#\$&*~]').hasMatch(value);
    if (!hasUppercase) {
      return 'Mật khẩu phải có ít nhất 1 chữ cái viết hoa';
    }
    if (!hasLowercase) {
      return 'Mật khẩu phải có ít nhất 1 chữ cái viết thường';
    }
    if (!hasDigit) {
      return 'Mật khẩu phải có ít nhất 1 chữ số';
    }
    if (!hasSpecialChar) {
      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt (!@#\$&*~)';
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA7FFEB), Color(0xFFDCEDC8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return _buildPortraitLayout();
            } else {
              return _buildLandscapeLayout();
            }
          },
        ),
      ),
    );
  }

  // WIDGET CHO LAYOUT DỌC (PORTRAIT)
  Widget _buildPortraitLayout() {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 15,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
            margin: const EdgeInsets.all(24),
            color: Colors.white,
            shadowColor: const Color(0xFF80CBC4).withOpacity(0.6),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: SingleChildScrollView(child: _buildFormContent()),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET CHO LAYOUT NGANG (LANDSCAPE)
  Widget _buildLandscapeLayout() {
    return SafeArea(
      child: Center(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIcon(),
                    const SizedBox(height: 28),
                    _buildTitle(),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Card(
                elevation: 15,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                color: Colors.white,
                shadowColor: const Color(0xFF80CBC4).withOpacity(0.6),
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: SingleChildScrollView(child: _buildFormContent()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TÁCH CÁC PHẦN UI RA HÀM RIÊNG

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF80CBC4).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(Icons.person_add_alt_1_outlined, size: 45, color: Color(0xFF00796B)),
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Đăng Ký Tài Khoản',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF004D40),
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Color.fromRGBO(0, 0, 0, 0.1),
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Hãy cùng chúng tôi xây dựng một cộng đồng tuyệt vời!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Color(0xFF26A69A), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Toàn bộ Form đăng ký
  Widget _buildFormContent() {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPortrait) ...[
            _buildIcon(),
            const SizedBox(height: 28),
            _buildTitle(),
            const SizedBox(height: 40),
          ],
          TextFormField(
            controller: _nameCtrl,
            decoration: _buildInputDecoration(hint: 'Họ và tên', icon: Icons.person_outline),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Họ và tên là bắt buộc' : null,
            cursorColor: const Color(0xFF00897B),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _usernameCtrl,
            decoration: _buildInputDecoration(hint: 'Tên đăng nhập', icon: Icons.person_pin_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Tên đăng nhập là bắt buộc' : null,
            cursorColor: const Color(0xFF00897B),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailCtrl,
            decoration: _buildInputDecoration(hint: 'Email', icon: Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            // THAY ĐỔI: Sử dụng hàm validator mới
            validator: _validateEmail,
            cursorColor: const Color(0xFF00897B),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _phoneCtrl,
            decoration: _buildInputDecoration(hint: 'Số điện thoại', icon: Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            // THAY ĐỔI: Sử dụng hàm validator mới
            validator: _validatePhoneNumber,
            cursorColor: const Color(0xFF00897B),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _passCtrl,
            decoration: _buildInputDecoration(
              hint: 'Mật khẩu',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF00897B)),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              ),
            ),
            obscureText: _obscure1,
            // THAY ĐỔI: Sử dụng hàm validator mới
            validator: _validatePassword,
            cursorColor: const Color(0xFF00897B),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _confirmCtrl,
            decoration: _buildInputDecoration(
              hint: 'Nhập lại mật khẩu',
              icon: Icons.lock_reset_outlined,
              suffixIcon: IconButton(
                icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF00897B)),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),
            obscureText: _obscure2,
            validator: (v) => (v != _passCtrl.text) ? 'Mật khẩu không khớp' : null,
            cursorColor: const Color(0xFF00897B),
          ),
          const SizedBox(height: 35),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF26A69A)],
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          TextButton(
            onPressed: _busy ? null : () => Navigator.pushReplacementNamed(context, '/login'),
            child: RichText(
              text: const TextSpan(
                text: 'Đã có tài khoản? ',
                style: TextStyle(color: Color(0xFF26A69A), fontSize: 16, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: 'Đăng nhập',
                    style: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm helper để tạo InputDecoration, tránh lặp code
  InputDecoration _buildInputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
      prefixIcon: Icon(icon, color: const Color(0xFF26A69A)),
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
      suffixIcon: suffixIcon,
    );
  }
}