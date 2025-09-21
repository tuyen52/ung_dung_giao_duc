import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Services
import 'services/settings_service.dart'; // MỚI: Import service cài đặt

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'home_shell.dart';

// Game launchers
import 'game/recycle_sort/recycle_sort_launcher.dart';
import 'game/traffic_safety/traffic_safety_launcher.dart';
import 'game/plant_care/plant_care_launcher.dart';
import 'game/swimming_safety/swimming_safety_launcher.dart';

// Core
import 'game/core/types.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Đảm bảo các binding của Flutter đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // MỚI: Khởi tạo service cài đặt để đọc/ghi lựa chọn của người dùng
  await SettingsService.instance.init();

  // Chạy ứng dụng
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MobileApp',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF00796B),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/shell' : (_) => const HomeShell(),
      },
      onGenerateRoute: (settings) {
        // Recycle Sort
        if (settings.name == '/game/recycle') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => RecycleSortGameLauncher(
              treId: args['treId'] as String,
              treName: args['treName'] as String,
              difficulty: args['difficulty'] as GameDifficulty,
            ),
          );
        }

        // Traffic Safety
        if (settings.name == '/game/traffic_safety') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => TrafficSafetyGameLauncher(
              treId: args['treId'] as String,
              treName: args['treName'] as String,
              difficulty: args['difficulty'] as GameDifficulty,
            ),
          );
        }

        // Plant Care
        if (settings.name == '/game/plant_care') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => PlantCareGameLauncher(
              treId: args['treId'] as String,
              treName: args['treName'] as String,
              difficulty: args['difficulty'] as GameDifficulty,
            ),
          );
        }

        // Swimming Safety
        if (settings.name == '/game/swimming_safety') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => SwimmingSafetyGameLauncher(
              treId: args['treId'] as String,
              treName: args['treName'] as String,
              difficulty: args['difficulty'] as GameDifficulty,
            ),
          );
        }

        // Nếu không khớp route nào, trả về null để Flutter xử lý
        return null;
      },
    );
  }
}
