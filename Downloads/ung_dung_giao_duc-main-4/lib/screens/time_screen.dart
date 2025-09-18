import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/alarm_service.dart';
import '../main.dart'; // để dùng appNavigatorKey

class TimeScreen extends StatefulWidget {
  const TimeScreen({super.key});

  @override
  State<TimeScreen> createState() => _TimeScreenState();
}

class _TimeScreenState extends State<TimeScreen> with SingleTickerProviderStateMixin {
  TimeOfDay _selected = const TimeOfDay(hour: 21, minute: 0);
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Gắn navigatorKey cho AlarmService để điều hướng toàn cục
    AlarmService.instance.attachNavigatorKey(appNavigatorKey);

    // <<< TÍCH HỢP: Đăng ký callback để xử lý logic đăng xuất khi báo thức kích hoạt
    AlarmService.instance.setLogoutCallback(_handleLogout);

    // Khởi tạo animation cho các nút bấm
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.9,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // <<< TÍCH HỢP: Gỡ bỏ callback khi widget bị huỷ để tránh memory leak
    AlarmService.instance.setLogoutCallback(null);

    _animationController.dispose();
    super.dispose();
  }

  // <<< TÍCH HỢP: Hàm callback để xử lý việc thoát về màn hình đăng nhập
  void _handleLogout() {
    // Kiểm tra widget còn tồn tại trên cây widget không
    if (mounted) {
      // Điều hướng về màn hình login và xoá toàn bộ các màn hình trước đó
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selected,
      helpText: 'Chọn giờ giới hạn',
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6A1B9A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: GoogleFonts.quicksand(),
              ),
            ),
          ),
          child: child!,
        );
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
      SnackBar(
        content: Text(
          'Đã đặt giờ đăng xuất vào $hh:$mm',
          style: GoogleFonts.quicksand(),
        ),
      ),
    );
    setState(() {});
  }

  void _cancelAlarm() {
    AlarmService.instance.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã huỷ giờ đăng xuất',
          style: GoogleFonts.quicksand(),
        ),
      ),
    );
    setState(() {});
  }

  // ==================== CÁC HÀM HELPER (GIỮ NGUYÊN) ====================

  Widget _buildTimeDisplay(BuildContext context, TimeOfDay time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        time.format(context),
        textAlign: TextAlign.center,
        style: GoogleFonts.quicksand(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4.0,
              color: Colors.black.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animationController.status == AnimationStatus.reverse ? 1.0 : _scaleAnimation.value,
          child: ElevatedButton.icon(
            onPressed: () {
              if (onPressed != null) {
                _animationController.forward().then((_) => _animationController.reverse());
                onPressed();
              }
            },
            icon: Icon(icon, color: Colors.white),
            label: Text(
              label,
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 8,
              shadowColor: color.withOpacity(0.6),
            ),
          ),
        );
      },
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

  // ==================== CÁC HÀM DỰNG GIAO DIỆN (GIỮ NGUYÊN) ====================

  Widget _buildPortraitLayout() {
    final target = AlarmService.instance.target;
    final targetText = (target == null)
        ? 'Chưa đặt'
        : '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')} (${_friendlyDay(target)})';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Icon(Icons.watch_later_outlined, size: 80, color: Colors.white.withOpacity(0.8)),
                const SizedBox(height: 16),
                Text(
                  'Cài đặt giờ giới hạn',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(offset: Offset(2, 2), blurRadius: 4.0, color: Colors.black.withOpacity(0.2))],
                  ),
                ),
                const SizedBox(height: 24),
                _buildTimeDisplay(context, _selected),
                const SizedBox(height: 30),
                _buildButton(onPressed: _pickTime, label: 'Chọn giờ', icon: Icons.access_time_filled, color: const Color(0xFFFFA726)),
                const SizedBox(height: 16),
                _buildButton(onPressed: _setAlarm, label: 'ĐẶT GIỜ THOÁT', icon: Icons.notifications_active, color: const Color(0xFF66BB6A)),
                const SizedBox(height: 8),
                _buildButton(onPressed: _cancelAlarm, label: 'Huỷ giờ', icon: Icons.cancel_schedule_send, color: const Color(0xFFEF5350)),
                const SizedBox(height: 30),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: const Color(0xFF6A1B9A), size: 30),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Thời điểm đăng xuất dự kiến:\n$targetText', style: GoogleFonts.quicksand(color: const Color(0xFF666666)))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Lưu ý: Đến đúng giờ đã đặt, ứng dụng sẽ thông báo ngắn và tự đăng xuất về màn Đăng nhập.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    final target = AlarmService.instance.target;
    final targetText = (target == null)
        ? 'Chưa đặt'
        : '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')} (${_friendlyDay(target)})';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Giờ đã chọn:',
                        style: GoogleFonts.quicksand(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeDisplay(context, _selected),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Thời điểm đăng xuất dự kiến:\n$targetText',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.quicksand(color: const Color(0xFF666666)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildButton(
                        onPressed: _pickTime,
                        label: 'Chọn giờ',
                        icon: Icons.access_time_filled,
                        color: const Color(0xFFFFA726),
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        onPressed: _setAlarm,
                        label: 'ĐẶT GIỜ THOÁT',
                        icon: Icons.notifications_active,
                        color: const Color(0xFF66BB6A),
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        onPressed: _cancelAlarm,
                        label: 'Huỷ giờ',
                        icon: Icons.cancel_schedule_send,
                        color: const Color(0xFFEF5350),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Lưu ý: Đến đúng giờ đã đặt, ứng dụng sẽ tự đăng xuất.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Giờ Giới Hạn',
          style: GoogleFonts.quicksand(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return _buildPortraitLayout();
          } else {
            return _buildLandscapeLayout();
          }
        },
      ),
    );
  }
}