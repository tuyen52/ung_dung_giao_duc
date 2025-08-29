import 'package:flutter/material.dart';
import '../services/reward_service.dart';
import '../models/reward.dart';

class RewardScreen extends StatelessWidget {
  final String treId;
  const RewardScreen({super.key, required this.treId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Điểm Thưởng Của Bé")),
      body: StreamBuilder<Reward?>(
        stream: RewardService().watchReward(treId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reward = snap.data ?? Reward(treId: treId);

          return RefreshIndicator(
            onRefresh: () async {
              // reload từ Firebase
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Text("★", style: TextStyle(fontSize: 28, color: Colors.red)),
                        const SizedBox(width: 8),
                        Text("${reward.points}",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Text("Điểm"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _badge("🏆", "Vàng", reward.gold),
                        _badge("🥈", "Bạc", reward.silver),
                        _badge("🥉", "Đồng", reward.bronze),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Chi tiết huy chương...",
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Text("Cập nhật lần cuối: ${reward.lastUpdated ?? 'Chưa có'}",
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _badge(String emoji, String label, int count) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text("$count", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
