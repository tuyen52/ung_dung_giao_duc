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
  late final _name = TextEditingController(text: widget.tre.hoTen);
  late final _gioiTinh = TextEditingController(text: widget.tre.gioiTinh);
  late final _ngaySinh = TextEditingController(text: widget.tre.ngaySinh);
  late final _soThich = TextEditingController(text: widget.tre.soThich);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose(); _gioiTinh.dispose(); _ngaySinh.dispose(); _soThich.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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
          content: Text(
            'Đã lưu thay đổi',
            style: GoogleFonts.balsamiqSans(),
          ),
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
    final title = widget.tre.hoTen.isEmpty ? 'Chi tiết của bé' : widget.tre.hoTen;
    final isMale = widget.tre.gioiTinh.toLowerCase() == 'nam';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.balsamiqSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: isMale ? Colors.lightBlueAccent : Colors.pinkAccent,
                    child: Icon(
                      isMale ? Icons.boy_rounded : Icons.girl_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                    child: Column(
                      children: [
                        _buildTextField('Họ tên', _name, Icons.person_outline),
                        _buildTextField('Giới tính', _gioiTinh, isMale ? Icons.male : Icons.female),
                        _buildTextField('Ngày sinh', _ngaySinh, Icons.cake_outlined),
                        _buildTextField('Sở thích', _soThich, Icons.favorite_outline),
                        const SizedBox(height: 20),
                        _buildSaveButton(),

                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController c, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
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
