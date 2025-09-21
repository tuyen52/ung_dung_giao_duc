// lib/game/plant_care/widgets/tool_button.dart

import 'package:flutter/material.dart';

class ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool disabled;
  final double size; // Kích thước của vòng tròn icon
  final double iconSize; // Kích thước của icon bên trong

  const ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
    this.size = 58, // Giữ nguyên size mặc định
  }) : iconSize = size * 0.5; // Kích thước icon bằng 1/2 size nút

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
          child: Icon(icon,
              size: iconSize, color: disabled ? Colors.grey : Colors.blueGrey),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(40),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: child,
      ),
    );
  }
}