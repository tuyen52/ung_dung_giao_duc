
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
  final _userService = UserService();

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  late AnimationController _iconAnimationController;
  late Animation<double> _iconAnimation;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _iconAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadInitial() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final profile = await _userService.getProfile(u.uid);
      _nameCtrl.text = (profile?['name'] ?? u.displayName ?? '').toString();
      _usernameCtrl.text = (profile?['username'] ?? _deriveUsername(u.email ?? 'user@${u.uid}', u.uid)).toString();
      _emailCtrl.text = (profile?['email'] ?? u.email ?? '').toString();
      _phoneCtrl.text = (profile?['phone'] ?? u.phoneNumber ?? '').toString();
      _addressCtrl.text = (profile?['address'] ?? '').toString();
    } catch (_) {
      _nameCtrl.text = (u.displayName ?? '').toString();
      _usernameCtrl.text = _deriveUsername(u.email ?? 'user@${u.uid}', u.uid);
      _emailCtrl.text = (u.email ?? '').toString();
      _phoneCtrl.text = (u.phoneNumber ?? '').toString();
      _addressCtrl.text = '';
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
      await _userService.upsertProfile(
        uid: u.uid,
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );
      if (_nameCtrl.text.trim().isNotEmpty) {
        await _userService.updateAuthDisplayName(_nameCtrl.text.trim());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu hồ sơ', style: GoogleFonts.balsamiqSans())),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu: $e', style: GoogleFonts.balsamiqSans())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
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
              Color(0xFF8EC5FC), // Màu xanh dương nhạt
              Color(0xFFE0C3FC), // Màu tím hồng nhạt
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
                      SizedBox(height: MediaQuery.of(context).padding.top + 20),
                      Text(
                        'Chỉnh Sửa Hồ Sơ Phụ Huynh',
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
                                enabled: false,
                                readOnly: true,
                                helperText: 'Muốn đổi email: dùng nút "Đổi email" ở màn Hồ sơ.',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _phoneCtrl,
                                labelText: 'Số điện thoại',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _addressCtrl,
                                labelText: 'Địa chỉ',
                                icon: Icons.home_outlined,
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _saving ? null : _save,
                                  icon: _saving
                                      ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                      : const Icon(Icons.save, color: Colors.white),
                                  label: Text(
                                    _saving ? 'Đang lưu...' : 'Lưu Thay Đổi',
                                    style: GoogleFonts.balsamiqSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: const Color(0xFF6A1B9A),
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
                      const Spacer(), // Lấp đầy khoảng trống còn lại
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
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

  String _deriveUsername(String emailOrElse, String uid) {
    final at = emailOrElse.indexOf('@');
    if (at > 0) return emailOrElse.substring(0, at);
    return 'user_${uid.substring(0, 6)}';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    bool enabled = true,
    bool readOnly = false,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: GoogleFonts.balsamiqSans(fontSize: 16),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.balsamiqSans(color: Colors.grey[700]),
        hintText: labelText,
        hintStyle: GoogleFonts.balsamiqSans(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: const Color(0xFFBA68C8)),
        helperText: helperText,
        helperStyle: GoogleFonts.balsamiqSans(color: Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}