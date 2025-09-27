import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tre.dart';
import '../services/tre_service.dart';
import 'reward_screen.dart';

// game
import 'package:mobileapp/game/core/types.dart';
import 'package:mobileapp/game/recycle_sort/recycle_sort_launcher.dart';

class TreDetailScreen extends StatefulWidget {
  final Tre tre;
  const TreDetailScreen({super.key, required this.tre});

  @override
  State<TreDetailScreen> createState() => _TreDetailScreenState();
}

class _TreDetailScreenState extends State<TreDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.tre.hoTen);
  late final _gioiTinh = TextEditingController(text: widget.tre.gioiTinh);
  late final _ngaySinh = TextEditingController(text: widget.tre.ngaySinh);
  late final _soThich = TextEditingController(text: widget.tre.soThich);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _gioiTinh.dispose();
    _ngaySinh.dispose();
    _soThich.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);
      try {
        final updated = widget.tre.copyWith(
          hoTen: _name.text.trim(),
          gioiTinh: _gioiTinh.text.trim(),
          ngaySinh: _ngaySinh.text.trim(),
          soThich: _soThich.text.trim(),
        );
        await TreService().updateTre(updated);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu thay đổi', style: GoogleFonts.balsamiqSans()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updated);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e', style: GoogleFonts.balsamiqSans()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xoá hồ sơ?', style: GoogleFonts.balsamiqSans(fontWeight: FontWeight.bold)),
        content: Text('Hành động này không thể hoàn tác.', style: GoogleFonts.balsamiqSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Huỷ', style: GoogleFonts.balsamiqSans()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Xoá', style: GoogleFonts.balsamiqSans()),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await TreService().deleteTre(parentId: widget.tre.parentId, treId: widget.tre.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xoá', style: GoogleFonts.balsamiqSans()),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e', style: GoogleFonts.balsamiqSans()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startGame(GameDifficulty diff) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecycleSortGameLauncher(
          treId: widget.tre.id,
          treName: widget.tre.hoTen.isEmpty ? 'Bé' : widget.tre.hoTen,
          difficulty: diff,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Xem điểm thưởng',
            icon: const Icon(Icons.star, color: Colors.yellow, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RewardScreen(treId: widget.tre.id)),
            ),
          ),
          IconButton(
            tooltip: 'Xoá hồ sơ',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
            onPressed: _delete,
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.portrait
              ? _buildPortraitLayout()
              : _buildLandscapeLayout();
        },
      ),
    );
  }

  // ================= Portrait =================
  Widget _buildPortraitLayout() {
    final isMale = widget.tre.gioiTinh.toLowerCase() == 'nam';
    return Container(
      // >>> ép nền phủ full viewport, hết hở nền
      constraints: const BoxConstraints.expand(),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: isMale ? Colors.lightBlueAccent : Colors.pinkAccent,
                        child: Icon(isMale ? Icons.boy_rounded : Icons.girl_rounded,
                            size: 80, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(24),
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
                              _buildTextFormField('Họ tên', _name, Icons.person_outline, isRequired: true),
                              _buildTextFormField('Giới tính', _gioiTinh, isMale ? Icons.male : Icons.female),
                              _buildTextFormField('Ngày sinh', _ngaySinh, Icons.cake_outlined),
                              _buildTextFormField('Sở thích', _soThich, Icons.favorite_outline),
                              const SizedBox(height: 20),
                              _buildSaveButton(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24), // thay cho Spacer để tránh co layout
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

  // ================= Landscape =================
  Widget _buildLandscapeLayout() {
    final isMale = widget.tre.gioiTinh.toLowerCase() == 'nam';
    return Container(
      // >>> ép nền phủ full viewport
      constraints: const BoxConstraints.expand(),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: isMale ? Colors.lightBlueAccent : Colors.pinkAccent,
                      child: Icon(isMale ? Icons.boy_rounded : Icons.girl_rounded,
                          size: 80, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.tre.hoTen.isEmpty ? 'Hồ sơ của bé' : widget.tre.hoTen,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.balsamiqSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(blurRadius: 5.0, color: Colors.black45, offset: Offset(2.0, 2.0)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.only(top: 20, bottom: 20, right: 20),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTextFormField('Họ tên', _name, Icons.person_outline, isRequired: true),
                        _buildTextFormField('Giới tính', _gioiTinh, isMale ? Icons.male : Icons.female),
                        _buildTextFormField('Ngày sinh', _ngaySinh, Icons.cake_outlined),
                        _buildTextFormField('Sở thích', _soThich, Icons.favorite_outline),
                        const SizedBox(height: 20),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- Fields & Button -----------------
  Widget _buildTextFormField(String label, TextEditingController c, IconData icon,
      {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        style: GoogleFonts.balsamiqSans(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
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
            borderSide: const BorderSide(color: Color(0xFF8EC5FC), width: 2),
          ),
        ),
        validator: isRequired
            ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Họ tên không được để trống';
          }
          return null;
        }
            : null,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
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
          _saving ? 'Đang lưu...' : 'Lưu thay đổi',
          style: GoogleFonts.balsamiqSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 8,
        ),
      ),
    );
  }
}
