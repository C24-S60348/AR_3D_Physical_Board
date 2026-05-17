import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ar_demo_screen.dart';
import 'screens/game_board_screen.dart';
import 'screens/scanner_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const IGBApp());
}

class IGBApp extends StatelessWidget {
  const IGBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'i.-GB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B1A1A),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/ar-demo': (_) => const ARDemoScreen(),
        '/game': (_) => const GameBoardScreen(),
        '/scanner': (_) => const ScannerScreen(),
      },
    );
  }
}
