import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'home_shell.dart';
import 'game/recycle_sort/recycle_sort_launcher.dart';
import 'game/traffic_safety/traffic_safety_launcher.dart';
import 'game/plant_care/plant_care_launcher.dart';
import 'game/core/types.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MobileApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF00796B)),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/shell': (_) => const HomeShell(),
      },
      onGenerateRoute: (settings) {
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

        // THAY ĐỔI ROUTE TỪ 'room_cleanup' SANG 'plant_care'
        if (settings.name == '/game/plant_care') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            // GỌI ĐÚNG LAUNCHER CỦA GAME MỚI
            builder: (_) => PlantCareGameLauncher(
              treId: args['treId'] as String,
              treName: args['treName'] as String,
              difficulty: args['difficulty'] as GameDifficulty,
            ),
          );
        }

        return null;
      },
    );
  }
}