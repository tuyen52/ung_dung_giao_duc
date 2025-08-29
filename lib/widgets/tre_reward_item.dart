import 'package:flutter/material.dart';
import '../models/tre.dart';

class TreRewardItem extends StatelessWidget {
  final Tre tre;
  final int? points;
  final int? gold;
  final int? silver;
  final int? bronze;
  final VoidCallback? onTap;

  const TreRewardItem({
    super.key,
    required this.tre,
    this.points,
    this.gold,
    this.silver,
    this.bronze,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(radius: 20, child: Text('⭐')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tre.hoTen, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('ID: ${tre.id}', style: const TextStyle(fontSize: 12, color: Color(0xFF777777))),
                    if (points != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('★ ${points!}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Text('🏆 ${gold ?? 0}'),
                          const SizedBox(width: 8),
                          Text('🥈 ${silver ?? 0}'),
                          const SizedBox(width: 8),
                          Text('🥉 ${bronze ?? 0}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
