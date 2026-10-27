import 'package:flutter/material.dart';
import 'screens/game_screen.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await SoundService.instance.init();
  ThemeService.instance.init();
  runApp(ReactionTimerApp());
}

class ReactionTimerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Reaction Timer Game',
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: mode,
          home: child,
        );
      },
      child: GameScreen(),
    );
  }
}