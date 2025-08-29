import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tre.dart';
import '../services/tre_service.dart';
import '../services/reward_service.dart';
import '../widgets/tre_reward_item.dart';
import 'reward_screen.dart';

class RewardListScreen extends StatelessWidget {
  const RewardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Danh sách điểm thưởng',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Danh Sách Trẻ Có Bảng Thưởng'),
              const SizedBox(height: 8),

              if (user == null)
                const Expanded(child: Center(child: Text('Vui lòng đăng nhập')))
              else
                Expanded(
                  child: StreamBuilder<List<Tre>>(
                    stream: TreService().watchTreList(user.uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final list = snap.data ?? const <Tre>[];
                      if (list.isEmpty) {
                        return const Center(child: Text('Chưa có trẻ nào.'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final tre = list[i];
                          // Lồng stream điểm thưởng theo từng bé
                          return StreamBuilder(
                            stream: RewardService().watchReward(tre.id),
                            builder: (context, rewardSnap) {
                              final reward = rewardSnap.data;
                              return TreRewardItem(
                                tre: tre,
                                points: reward?.points,
                                gold: reward?.gold,
                                silver: reward?.silver,
                                bronze: reward?.bronze,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => RewardScreen(treId: tre.id)),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
