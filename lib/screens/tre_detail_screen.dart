import 'package:flutter/material.dart';
import '../models/tre.dart';
import '../services/tre_service.dart';
import 'reward_screen.dart';

// game (vẫn có thể giữ import nếu bạn muốn dùng lại hàm _startGame ở đâu đó)
// import 'package:mobileapp/game/core/types.dart';
// import 'package:mobileapp/game/recycle_sort/recycle_sort_launcher.dart';

class TreDetailScreen extends StatefulWidget {
  final Tre tre;
  const TreDetailScreen({super.key, required this.tre});

  @override
  State<TreDetailScreen> createState() => _TreDetailScreenState();
}

class _TreDetailScreenState extends State<TreDetailScreen> {
  late final _name = TextEditingController(text: widget.tre.hoTen);
  late final _sex  = TextEditingController(text: widget.tre.gioiTinh);
  late final _dob  = TextEditingController(text: widget.tre.ngaySinh);
  late final _fav  = TextEditingController(text: widget.tre.soThich);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose(); _sex.dispose(); _dob.dispose(); _fav.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.tre.copyWith(
        hoTen: _name.text.trim(),
        gioiTinh: _sex.text.trim(),
        ngaySinh: _dob.text.trim(),
        soThich: _fav.text.trim(),
      );
      await TreService().updateTre(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thay đổi')),
      );
      Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá hồ sơ?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await TreService().deleteTre(parentId: widget.tre.parentId, treId: widget.tre.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xoá')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  // Hàm này giờ sẽ không được dùng đến trong màn hình này nữa,
  // nhưng bạn có thể giữ lại để dùng ở nơi khác hoặc xóa đi nếu không cần.
  /*
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
  */

  @override
  Widget build(BuildContext context) {
    final title = widget.tre.hoTen.isEmpty ? 'Chi tiết trẻ' : widget.tre.hoTen;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Xem điểm thưởng',
            icon: const Icon(Icons.star),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RewardScreen(treId: widget.tre.id)),
            ),
          ),
          IconButton(
            tooltip: 'Xoá',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('Họ tên', _name),
          _field('Giới tính', _sex),
          _field('Ngày sinh', _dob),
          _field('Sở thích', _fav),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _saving
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            )
                : const Text('Lưu thay đổi'),
          ),
          // PHẦN GIAO DIỆN CHƠI GAME ĐÃ ĐƯỢC XÓA BỎ TẠI ĐÂY
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}