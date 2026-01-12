import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seconds/main.dart';

void main() {
  group('Reaction Timer App Tests', () {
    testWidgets('App should display initial state correctly', (WidgetTester tester) async {
      // Set a larger screen size for tests to prevent overflow
      await tester.binding.setSurfaceSize(Size(800, 1200));

      // Build our app and trigger a frame
      await tester.pumpWidget(ReactionTimerApp());

      // Verify that initial UI elements are present
      expect(find.text('Reaction Timer Game'), findsOneWidget);
      expect(find.text('Ready to start?'), findsOneWidget);
      expect(find.text('Tap the button at exactly:\n1s, 3s, 5s, and 7s'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Verify the main game button is present
      expect(find.byIcon(Icons.touch_app), findsOneWidget);
    });

    testWidgets('Start Game button should initiate countdown', (WidgetTester tester) async {
      // Set a larger screen size for tests
      await tester.binding.setSurfaceSize(Size(800, 1200));

      // Build our app
      await tester.pumpWidget(ReactionTimerApp());

      // Verify initial state
      expect(find.text('Ready to start?'), findsOneWidget);

      // Tap the Start Game button
      await tester.tap(find.text('Start Game'));
      await tester.pump();

      // The text should change from "Ready to start?" to something else
      // It might be "Get ready..." or "3" or other countdown text
      expect(find.text('Ready to start?'), findsNothing);

      // Verify Start Game button is still there (but should be disabled)
      expect(find.text('Start Game'), findsOneWidget);

      // Check that countdown has started by looking for any of these possible texts
      final bool hasCountdownText =
          find.text('Get ready...').evaluate().isNotEmpty ||
              find.text('3').evaluate().isNotEmpty ||
              find.text('2').evaluate().isNotEmpty ||
              find.text('1').evaluate().isNotEmpty ||
              find.textContaining('ready').evaluate().isNotEmpty;

      expect(hasCountdownText, isTrue, reason: 'Countdown should have started');
    });

    testWidgets('Reset button should work at any time', (WidgetTester tester) async {
      // Set a larger screen size for tests
      await tester.binding.setSurfaceSize(Size(800, 1200));

      // Build our app
      await tester.pumpWidget(ReactionTimerApp());

      // Start the game
      await tester.tap(find.text('Start Game'));
      await tester.pump();

      // Reset should be available
      expect(find.text('Reset'), findsOneWidget);

      // Tap reset
      await tester.tap(find.text('Reset'));
      await tester.pump();

      // Should return to initial state
      expect(find.text('Ready to start?'), findsOneWidget);
    });

    testWidgets('Instructions should always be visible', (WidgetTester tester) async {
      // Set a larger screen size for tests
      await tester.binding.setSurfaceSize(Size(800, 1200));

      // Build our app
      await tester.pumpWidget(ReactionTimerApp());

      // Instructions should be visible
      expect(find.text('Tap the button at exactly:\n1s, 3s, 5s, and 7s'), findsOneWidget);

      // Start game and instructions should still be there
      await tester.tap(find.text('Start Game'));
      await tester.pump();

      expect(find.text('Tap the button at exactly:\n1s, 3s, 5s, and 7s'), findsOneWidget);
    });

    testWidgets('Game button should be present and have touch icon', (WidgetTester tester) async {
      // Set a larger screen size for tests
      await tester.binding.setSurfaceSize(Size(800, 1200));

      // Build our app
      await tester.pumpWidget(ReactionTimerApp());

      // Verify the game button icon is present
      expect(find.byIcon(Icons.touch_app), findsOneWidget);

      // Find the actual ElevatedButton that contains the icon
      final buttonFinder = find.ancestor(
        of: find.byIcon(Icons.touch_app),
        matching: find.byType(ElevatedButton),
      );
      expect(buttonFinder, findsOneWidget);
    });

    testWidgets('Control buttons should be present', (WidgetTester tester) async {
      // Set a larger screen size for tests
      await tester.binding.setSurfaceSize(Size(800, 1200));

      // Build our app
      await tester.pumpWidget(ReactionTimerApp());

      // Both control buttons should be present
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // They should be ElevatedButtons
      expect(find.widgetWithText(ElevatedButton, 'Start Game'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reset'), findsOneWidget);
    });
  });

  group('Game Logic Tests', () {
    testWidgets('Game should show target times correctly', (WidgetTester tester) async {
      // Set a larger screen size for tests
      await tester.binding.setSurfaceSize(Size(800, 1200));

      await tester.pumpWidget(ReactionTimerApp());

      // The target times should be displayed in the instructions
      expect(find.textContaining('1s'), findsWidgets);
      expect(find.textContaining('3s'), findsWidgets);
      expect(find.textContaining('5s'), findsWidgets);
      expect(find.textContaining('7s'), findsWidgets);
    });

    testWidgets('App title should be correct', (WidgetTester tester) async {
      // Set a larger screen size for tests
      await tester.binding.setSurfaceSize(Size(800, 1200));

      await tester.pumpWidget(ReactionTimerApp());

      // Check app bar title
      expect(find.text('Reaction Timer Game'), findsOneWidget);
    });
  });
}
