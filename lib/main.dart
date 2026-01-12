import 'package:flutter/material.dart';
import 'screens/game_screen.dart';
import 'services/storage_service.dart'; // ADD THIS IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ADD THIS
  await StorageService.init(); // ADD THIS - CRITICAL!
  runApp(ReactionTimerApp());
}

class ReactionTimerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reaction Timer Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: GameScreen(),
    );
  }
}