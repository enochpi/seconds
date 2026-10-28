import 'package:flutter/material.dart';
import 'screens/game_screen.dart';
import 'services/cosmetics_service.dart';
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
    // Rebuild the theme when dark mode changes or a new font is equipped.
    return ValueListenableBuilder<int>(
      valueListenable: CosmeticsService.changes,
      builder: (context, _, gameScreen) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.instance.themeMode,
          builder: (context, mode, child) {
            return MaterialApp(
              title: 'Reaction Timer Game',
              theme: ThemeService.lightTheme,
              darkTheme: ThemeService.darkTheme,
              // Shop backgrounds are all dark, so they need light text.
              themeMode: CosmeticsService.background.colors.isNotEmpty
                  ? ThemeMode.dark
                  : mode,
              home: child,
            );
          },
          child: gameScreen,
        );
      },
      child: GameScreen(),
    );
  }
}
