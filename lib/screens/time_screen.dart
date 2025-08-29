import 'package:flutter/material.dart';
import '../services/alarm_service.dart';
import '../main.dart'; // để dùng appNavigatorKey

class TimeScreen extends StatefulWidget {
  const TimeScreen({super.key});

  @override
  State<TimeScreen> createState() => _TimeScreenState();
}

class _TimeScreenState extends State<TimeScreen> {
  TimeOfDay _selected = const TimeOfDay(hour: 21, minute: 0); // mặc định 21:00

  @override
  void initState() {
    super.initState();
    // gắn navigatorKey cho AlarmService (1 lần là đủ, nhưng gọi an toàn ở đây)
    AlarmService.instance.attachNavigatorKey(appNavigatorKey);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selected,
      helpText: 'Chọn giờ giới hạn',
      builder: (ctx, child) {
        // có thể tuỳ biến theme ở đây nếu muốn
        return child!;
      },
    );
    if (picked != null) {
      setState(() => _selected = picked);
    }
  }

  void _setAlarm() {
    AlarmService.instance.scheduleDaily(_selected);
    final target = AlarmService.instance.target!;
    final hh = target.hour.toString().padLeft(2, '0');
    final mm = target.minute.toString().padLeft(2, '0');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã đặt giờ đăng xuất vào $hh:$mm')),
    );
    setState(() {});
  }

  void _cancelAlarm() {
    AlarmService.instance.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã huỷ giờ đăng xuất')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final target = AlarmService.instance.target;
    final targetText = (target == null)
        ? 'Chưa đặt'
        : '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')} (${_friendlyDay(target)})';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text('Cài đặt giờ giới hạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Giờ đã chọn: ${_selected.format(context)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF666666))),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: const Text('Chọn giờ'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _setAlarm,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: const Text('ĐẶT GIỜ THOÁT'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _cancelAlarm,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Huỷ'),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Thời điểm đăng xuất dự kiến: $targetText'),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text('Lưu ý: Đến đúng giờ đã đặt, ứng dụng sẽ thông báo ngắn và tự đăng xuất về màn Đăng nhập.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF777777))),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyDay(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return 'hôm nay';
    if (day == today.add(const Duration(days: 1))) return 'ngày mai';
    return '${day.day}/${day.month}/${day.year}';
  }
}
