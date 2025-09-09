import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class EditParentScreen extends StatefulWidget {
  const EditParentScreen({super.key});

  @override
  State<EditParentScreen> createState() => _EditParentScreenState();
}

class _EditParentScreenState extends State<EditParentScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  late AnimationController _iconAnimationController;
  late Animation<double> _iconAnimation;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _iconAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dbData = await UserService().getProfile(user.uid);
    if (dbData != null) {
      _nameCtrl.text = dbData['name'] ?? '';
      _usernameCtrl.text = dbData['username'] ?? '';
      _emailCtrl.text = dbData['email'] ?? user.email ?? '';
      _phoneCtrl.text = dbData['phone'] ?? user.phoneNumber ?? '';
    } else {
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8EC5FC),
              Color(0xFFE0C3FC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      Text(
                        'Chỉnh Sửa Hồ Sơ',
                        style: GoogleFonts.balsamiqSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4.0,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _iconAnimationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _iconAnimation.value,
                            child: const Icon(
                              Icons.person_pin,
                              size: 120,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _nameCtrl,
                                labelText: 'Họ và tên',
                                icon: Icons.person_outline,
                                validator: (v) => (v == null || v.isEmpty) ? 'Không được để trống' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _usernameCtrl,
                                labelText: 'Tên đăng nhập',
                                icon: Icons.account_circle_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailCtrl,
                                labelText: 'Email',
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _phoneCtrl,
                                labelText: 'Số điện thoại',
                                icon: Icons.phone_outlined,
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _save,
                                  icon: const Icon(Icons.save, color: Colors.white),
                                  label: Text(
                                    'Lưu Thay Đổi',
                                    style: GoogleFonts.balsamiqSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: const Color(0xFF8E24AA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    elevation: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(), // ✨ Đẩy nội dung lên trên và lấp đầy khoảng trống
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.balsamiqSans(fontSize: 16),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.balsamiqSans(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: const Color(0xFFE0C3FC)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF8EC5FC), width: 2),
        ),
      ),
    );
  }
}
