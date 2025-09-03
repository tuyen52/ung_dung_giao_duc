// lib/game/recycle_sort/data/trash_data.dart
import 'package:mobileapp/game/recycle_sort/recycle_sort_play_screen.dart';

/// Defines the pool of trash items for the Recycle Sort game.
const List<TrashItem> recycleSortTrashPool = [
  TrashItem('apple', 'Vỏ táo', '🍎', TrashType.organic),
  TrashItem('banana', 'Vỏ chuối', '🍌', TrashType.organic),
  TrashItem('bone', 'Xương gà', '🍗', TrashType.organic),
  TrashItem('veggie', 'Rau thừa', '🥬', TrashType.organic),
  TrashItem('coffee', 'Bã cà phê', '☕', TrashType.organic),
  TrashItem('egg', 'Vỏ trứng', '🥚', TrashType.organic),
  TrashItem('bottle', 'Chai nhựa', '🥤', TrashType.inorganic),
  TrashItem('can', 'Lon kim loại', '🥫', TrashType.inorganic),
  TrashItem('nylon', 'Túi nylon', '🛍️', TrashType.inorganic),
  TrashItem('foam', 'Hộp xốp', '📦', TrashType.inorganic),
  TrashItem('battery', 'Pin hỏng', '🔋', TrashType.inorganic),
  TrashItem('bulb', 'Bóng đèn', '💡', TrashType.inorganic),
];