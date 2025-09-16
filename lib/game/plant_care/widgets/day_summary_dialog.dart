import 'package:flutter/material.dart';

import '../core/balance.dart';
import '../models/plant_entity.dart';
import '../models/weather.dart';
import '../data/plant_care_data.dart';

Future<void> showDaySummaryDialog({
  required BuildContext context,
  required int dayIndex,
  required List<Plant> plants,
  required Map<Sticker, int> stickerBag,
  required Weather nextWeather,
}) async {
  final wx = kWeather[nextWeather]!;
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Kết thúc ngày $dayIndex'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stickerLegend(Sticker.gold,   stickerBag[Sticker.gold] ?? 0),
                  _stickerLegend(Sticker.silver, stickerBag[Sticker.silver] ?? 0),
                  _stickerLegend(Sticker.bronze, stickerBag[Sticker.bronze] ?? 0),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              ...plants.map((p) {
                final sp = plantSpeciesData[p.type]!;
                final wz = zoneOf(p.waterLevel, sp.optimalWater);
                final lz = zoneOf(p.lightLevel, sp.optimalLight);
                final nz = zoneOf(p.nutrientLevel, sp.optimalNutrient);
                final greens = [wz, lz, nz].where((z) => z == Zone.ok).length;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.speciesName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _zoneChip(Icons.water_drop, wz),
                                const SizedBox(width: 6),
                                _zoneChip(Icons.light_mode, lz),
                                const SizedBox(width: 6),
                                _zoneChip(Icons.eco, nz),
                                const SizedBox(width: 10),
                                Text('$greens vùng xanh'),
                              ],
                            ),
                            if (p.quests.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6, runSpacing: 4,
                                children: p.quests.map((q) =>
                                    Chip(label: Text(q.label()), visualDensity: VisualDensity.compact)
                                ).toList(),
                              ),
                            ]
                          ],
                        ),
                      ),
                      _stickerIcon(p.lastSticker),
                    ],
                  ),
                );
              }),
              const Divider(),
              const SizedBox(height: 6),
              ListTile(
                dense: true,
                leading: Icon(wx.icon, color: Colors.blue),
                title: Text('Thời tiết ngày mới: ${wx.name}'),
                subtitle: Text(wx.hint),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tiếp tục ngày mới'),
          ),
        ],
      );
    },
  );
}

Widget _stickerLegend(Sticker s, int count) {
  return Row(children: [_stickerIcon(s), const SizedBox(width: 4), Text('x$count')]);
}

Widget _stickerIcon(Sticker s) {
  switch (s) {
    case Sticker.gold:   return const Icon(Icons.emoji_events, color: Colors.amber, size: 24);
    case Sticker.silver: return const Icon(Icons.emoji_events, color: Colors.blueGrey, size: 24);
    case Sticker.bronze: return const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 24);
    case Sticker.none:   return const Icon(Icons.block, color: Colors.grey, size: 20);
  }
}

Widget _zoneChip(IconData icon, Zone z) {
  Color bg;
  switch (z) {
    case Zone.low:  bg = Colors.amber; break;
    case Zone.ok:   bg = Colors.green; break;
    case Zone.high: bg = Colors.redAccent; break;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Icon(icon, size: 14, color: Colors.white),
  );
}
