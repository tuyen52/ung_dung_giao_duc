import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String? _selectedGioiTinh;
  DateTime? _selectedNgaySinh;
  final _soThichCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _hoTenCtrl.dispose();
    _soThichCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectNgaySinh(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedNgaySinh ?? DateTime(DateTime.now().year - 5),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6A1B9A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedNgaySinh) {
      setState(() {
        _selectedNgaySinh = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedGioiTinh == null || _selectedNgaySinh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin bắt buộc.')),
      );
      return;
    }
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
        gioiTinh: _selectedGioiTinh!,
        ngaySinh: _selectedNgaySinh!.toIso8601String().substring(0, 10),
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
            colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return _buildLandscapeLayout();
            }
            return _buildPortraitLayout();
          },
        ),
      ),
    );
  }

  // --- WIDGET GIAO DIỆN DỌC - ĐÃ CẬP NHẬT ---
  Widget _buildPortraitLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // Đảm bảo chiều cao tối thiểu bằng chiều cao của viewport
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 25),
                _buildForm(),
                // Spacer giờ sẽ hoạt động đúng, đẩy form lên trên
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget cho layout xoay ngang (không thay đổi)
  Widget _buildLandscapeLayout() {
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildHeader(),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  // Widget chứa phần Header (không thay đổi)
  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text(
          'Thêm Hồ Sơ Của Bé',
          style: GoogleFonts.balsamiqSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: const Offset(2, 2),
                blurRadius: 4.0,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        const Icon(
          Icons.child_care_rounded,
          size: 100,
          color: Colors.white,
        ),
      ],
    );
  }

  // Widget chứa Form nhập liệu (không thay đổi)
  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              controller: _hoTenCtrl,
              labelText: 'Họ và Tên',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Họ tên không được để trống' : null,
            ),
            const SizedBox(height: 16),
            _buildGioiTinhDropdown(),
            const SizedBox(height: 16),
            _buildNgaySinhField(context),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _soThichCtrl,
              labelText: 'Sở Thích',
              icon: Icons.favorite_outline,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _save,
                icon: _busy
                    ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _busy ? 'Đang Lưu...' : 'Lưu Hồ Sơ',
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
    );
  }

  // Các widget con không thay đổi
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
        prefixIcon: Icon(icon, color: const Color(0xFFBA68C8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF8E24AA), width: 2),
        ),
      ),
    );
  }

  Widget _buildGioiTinhDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGioiTinh,
      items: ['Nam', 'Nữ'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: GoogleFonts.balsamiqSans()),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedGioiTinh = newValue;
        });
      },
      validator: (v) => (v == null) ? 'Vui lòng chọn giới tính' : null,
      decoration: InputDecoration(
        labelText: 'Giới Tính',
        labelStyle: GoogleFonts.balsamiqSans(color: Colors.grey[700]),
        prefixIcon: Icon(
          _selectedGioiTinh == 'Nam' ? Icons.boy : (_selectedGioiTinh == 'Nữ' ? Icons.girl : Icons.wc_outlined),
          color: const Color(0xFFBA68C8),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      style: GoogleFonts.balsamiqSans(color: Colors.black),
    );
  }

  Widget _buildNgaySinhField(BuildContext context) {
    return TextFormField(
      readOnly: true,
      onTap: () => _selectNgaySinh(context),
      controller: TextEditingController(
        text: _selectedNgaySinh == null
            ? ''
            : '${_selectedNgaySinh!.day}/${_selectedNgaySinh!.month}/${_selectedNgaySinh!.year}',
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng chọn ngày sinh' : null,
      decoration: InputDecoration(
        labelText: 'Ngày Sinh',
        labelStyle: GoogleFonts.balsamiqSans(color: Colors.grey[700]),
        prefixIcon: const Icon(Icons.cake_outlined, color: Color(0xFFBA68C8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF8E24AA), width: 2),
        ),
      ),
      style: GoogleFonts.balsamiqSans(fontSize: 16),
    );
  }
}