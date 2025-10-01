// lib/game/plant_care/widgets/tool_button.dart
import 'package:flutter/material.dart';

class ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool disabled;     // true = khóa/không bấm
  final double size;       // đường kính nút tròn
  final double iconSize;   // = size * 0.5
  final String? lockedHint; // gợi ý khi bị khóa

  const ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
    this.size = 58,
    this.lockedHint,
  }) : iconSize = size * 0.5;

  @override
  Widget build(BuildContext context) {
    // Vòng tròn nền + icon
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade300 : Colors.blue.shade50,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: disabled ? Colors.grey : Colors.blueGrey,
      ),
    );

    // Overlay ổ khóa (khi disabled)
    final withLock = Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        if (disabled)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.lock, size: 16, color: Colors.grey),
            ),
          ),
      ],
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        withLock,
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: disabled ? Colors.grey : Colors.black87,
          ),
        ),
      ],
    );

    final button = InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(40),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: column,
      ),
    );

    // Tooltip: khi khóa hiện hint mở khóa
    return Tooltip(
      message: disabled ? (lockedHint ?? 'Chưa mở ở giai đoạn này') : label,
      child: button,
    );
  }
}
