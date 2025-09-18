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
    // Đã tích hợp logic validation mới, chỉ cần gọi validate()
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

  // LOGIC MỚI: Hàm kiểm tra định dạng email chặt chẽ hơn
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    // Sử dụng Regular Expression để kiểm tra định dạng email chuẩn
    const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    final regExp = RegExp(pattern);
    if (!regExp.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  // LOGIC MỚI: Hàm kiểm tra mật khẩu
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu tối thiểu 6 ký tự';
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
        // SỬ DỤNG OrientationBuilder ĐỂ TỰ ĐỘNG THAY ĐỔI LAYOUT
        child: OrientationBuilder(
          builder: (context, orientation) {
            // Nếu màn hình dọc, sử dụng layout cũ
            if (orientation == Orientation.portrait) {
              return _buildPortraitLayout();
            }
            // Nếu màn hình ngang, sử dụng layout mới
            else {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildCardContent(), // Tách nội dung card ra để tái sử dụng
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
            // Phần bên trái: Icon và tiêu đề
            Expanded(
              flex: 2, // Chiếm 2/5 không gian
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(), // Tách Icon ra widget riêng
                  const SizedBox(height: 32),
                  _buildAppTitle(), // Tách tiêu đề ra widget riêng
                ],
              ),
            ),
            // Phần bên phải: Form đăng nhập
            Expanded(
              flex: 3, // Chiếm 3/5 không gian
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildCardContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TÁCH CÁC PHẦN UI RA HÀM RIÊNG ĐỂ DỄ QUẢN LÝ VÀ TÁI SỬ DỤNG

  // Phần Icon
  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: const Icon(
        Icons.child_care_outlined,
        size: 50,
        color: Color(0xFF00796B),
      ),
    );
  }

  // Phần tiêu đề ứng dụng
  Widget _buildAppTitle() {
    return const Column(
      children: [
        Text(
          'Cùng Bé',
          style: TextStyle(
            fontSize: 32,
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
        Text(
          'Trưởng Thành',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF00897B),
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
          'Phát triển toàn diện, tự tin vươn xa!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            color: Color(0xFF26A69A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Nội dung bên trong Card (Form đăng nhập)
  Widget _buildCardContent() {
    // Lấy orientation hiện tại để quyết định có hiển thị icon và title hay không
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Card(
      elevation: 15,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(35),
      ),
      margin: EdgeInsets.zero,
      color: Colors.white,
      shadowColor: const Color(0xFF80CBC4).withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chỉ hiển thị icon và title trong layout dọc
              if (isPortrait) ...[
                _buildIcon(),
                const SizedBox(height: 32),
                _buildAppTitle(),
                const SizedBox(height: 40),
              ],
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  hintText: 'Email',
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
                keyboardType: TextInputType.emailAddress,
                // THAY ĐỔI: Sử dụng hàm validator mới
                validator: _validateEmail,
                cursorColor: const Color(0xFF00897B),
              ),
              const SizedBox(height: 20),
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
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF00897B),
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                // THAY ĐỔI: Sử dụng hàm validator mới
                validator: _validatePassword,
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
              TextButton(
                onPressed: _busy ? null : () => Navigator.pushReplacementNamed(context, '/signup'),
                child: RichText(
                  text: const TextSpan(
                    text: 'Chưa có tài khoản? ',
                    style: TextStyle(
                      color: Color(0xFF26A69A),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: 'Đăng Ký',
                        style: TextStyle(
                          color: Color(0xFF00897B),
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
    );
  }
}