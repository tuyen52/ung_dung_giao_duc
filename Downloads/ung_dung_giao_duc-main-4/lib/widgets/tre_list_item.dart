import 'package:flutter/material.dart';
import '../models/tre.dart';

class TreListItem extends StatelessWidget {
  final Tre tre;
  final VoidCallback? onTap; // xem chi tiết

  const TreListItem({super.key, required this.tre, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: avatar + tên + badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Text(
                      (tre.hoTen.isNotEmpty ? tre.hoTen[0] : '👶'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tre.hoTen.isEmpty ? 'Bé chưa đặt tên' : tre.hoTen,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text('🏆', style: TextStyle(fontSize: 20)),
                ],
              ),

              const SizedBox(height: 12),
              _infoLine('⚪ Giới tính', tre.gioiTinh),
              const SizedBox(height: 4),
              _infoLine('🎂 Ngày sinh', tre.ngaySinh),
              const SizedBox(height: 4),
              _infoLine('❤️ Sở thích', tre.soThich),

              const SizedBox(height: 12),
              // “Chạm để xem chi tiết”
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.insights, size: 18, color: Color(0xFF3F51B5)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Đã có bảng thưởng • Chạm để xem chi tiết / chỉnh sửa',
                          style: TextStyle(fontSize: 13, color: Color(0xFF3F51B5))),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF3F51B5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    final has = value.trim().isNotEmpty;
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF666666))),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            has ? value : '—',
            style: TextStyle(color: has ? const Color(0xFF333333) : const Color(0xFFAAAAAA)),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
