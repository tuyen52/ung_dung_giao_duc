import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/plant_care_data.dart';
import '../core/balance.dart';
import '../models/plant_entity.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final double fontSize;
  final bool isSelected;

  const PlantCard({
    super.key,
    required this.plant,
    required this.fontSize,
    required this.isSelected,
  });

  Color _zoneColor(Zone z) {
    switch (z) {
      case Zone.low:  return Colors.amber;
      case Zone.ok:   return Colors.green;
      case Zone.high: return Colors.redAccent;
    }
  }

  List<Widget> _needBubbles(Plant p) {
    final sp = plantSpeciesData[p.type]!;
    final wz = zoneOf(p.waterLevel, sp.optimalWater);
    final lz = zoneOf(p.lightLevel, sp.optimalLight);
    final nz = zoneOf(p.nutrientLevel, sp.optimalNutrient);

    Widget bubble(IconData icon, Zone z) {
      if (z == Zone.ok) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _zoneColor(z),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      );
    }

    return [
      if (wz != Zone.ok) bubble(Icons.water_drop, wz),
      if (lz != Zone.ok) bubble(Icons.light_mode, lz),
      if (nz != Zone.ok) bubble(Icons.eco, nz),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final species = plantSpeciesData[plant.type]!;
    final wz = zoneOf(plant.waterLevel, species.optimalWater);
    final lz = zoneOf(plant.lightLevel, species.optimalLight);
    final nz = zoneOf(plant.nutrientLevel, species.optimalNutrient);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
        border: isSelected ? Border.all(color: Colors.yellow.shade600, width: 4) : null,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: plant.isCompleted ? const Color(0xFFE8F5E9) : Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Stack(
                  children: [
                    Image.asset(
                      plantImagePaths[plant.type]![plant.stage]!,
                      height: fontSize * 2,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                    ),
                    Positioned(left: 0, top: 0, child: Row(children: _needBubbles(plant))),
                    Positioned(
                      right: 0, top: 0,
                      child: Row(
                        children: [
                          if (plant.pests) const Icon(Icons.bug_report, size: 20, color: Colors.redAccent),
                          if (plant.overgrown) const Icon(Icons.cut, size: 20, color: Colors.teal),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(plant.speciesName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown)),
                Text(plantStageDescriptiveNames[plant.stage]!,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    _buildProgressBar('Nước',       plant.waterLevel,    _zoneColor(wz)),
                    _buildProgressBar('Ánh sáng',   plant.lightLevel,    _zoneColor(lz)),
                    _buildProgressBar('Dinh dưỡng', plant.nutrientLevel, _zoneColor(nz)),
                    _buildProgressBar('Nở hoa',     plant.growthProgress.toDouble(), Colors.teal),
                  ],
                ),
                if (plant.isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Icon(Icons.check_circle, color: Colors.green.shade400, size: 36),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate(
      key: ValueKey('${plant.animationCounter}-${plant.animationTrigger}'),
      onComplete: (controller) => plant.animationTrigger = AnimationTrigger.idle,
      effects: plant.animationTrigger == AnimationTrigger.healthy
          ? [
        ScaleEffect(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOut),
        ThenEffect(delay: 50.ms),
        ScaleEffect(end: const Offset(1, 1), duration: 250.ms, curve: Curves.easeIn),
      ]
          : plant.animationTrigger == AnimationTrigger.unhealthy
          ? [
        ShakeEffect(hz: 8, duration: 500.ms, curve: Curves.easeInOut),
        TintEffect(color: Colors.red, duration: 300.ms, end: 0.2),
      ]
          : [],
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text('$label:', style: const TextStyle(fontSize: 12))),
          Expanded(
            child: LinearProgressIndicator(
              value: clamp100(value) / 100.0,
              color: color,
              backgroundColor: Colors.grey.shade300,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 40, child: Text('${value.toInt()}%', textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
