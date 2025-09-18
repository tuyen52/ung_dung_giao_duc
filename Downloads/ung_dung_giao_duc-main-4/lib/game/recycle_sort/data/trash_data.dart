// lib/game/recycle_sort/data/trash_data.dart
import 'package:mobileapp/game/recycle_sort/recycle_sort_play_screen.dart';

/// Defines the pool of trash items for the Recycle Sort game.
const List<TrashItem> recycleSortTrashPool = [
  // Hữu cơ
  TrashItem('apple', 'Vỏ táo', 'assets/images/environment/apple.png', TrashType.organic),
  TrashItem('banana', 'Vỏ chuối', 'assets/images/environment/banana.png', TrashType.organic),
  TrashItem('bone', 'Xương gà', 'assets/images/environment/bone.png', TrashType.organic),
  TrashItem('veggie', 'Rau thừa', 'assets/images/environment/veggie.png', TrashType.organic),
  TrashItem('coffee', 'Bã cà phê', 'assets/images/environment/coffee.png', TrashType.organic),
  TrashItem('egg', 'Vỏ trứng', 'assets/images/environment/egg.png', TrashType.organic),

  // Vô cơ
  TrashItem('bottle', 'Chai nhựa', 'assets/images/environment/bottle.png', TrashType.inorganic),
  TrashItem('can', 'Lon kim loại', 'assets/images/environment/can.png', TrashType.inorganic),
  TrashItem('nylon', 'Túi nylon', 'assets/images/environment/nylon.png', TrashType.inorganic),
  TrashItem('foam', 'Hộp xốp', 'assets/images/environment/foam.png', TrashType.inorganic),
  TrashItem('battery', 'Pin hỏng', 'assets/images/environment/battery.png', TrashType.inorganic),
  TrashItem('bulb', 'Bóng đèn', 'assets/images/environment/bulb.png', TrashType.inorganic),
];