// Import your app's main widget
import 'package:flutter/material.dart';
import 'package:notes/core/app.dart'; // Adjust this path if needed
// Import your provider
import 'package:notes/core/features/auth/provider/auth_provider.dart';
import 'package:notes/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PrepBuddyApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We wrap the app in MultiProvider, just like in main.dart
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const PrepBuddyApp(),
      ),
    );

    // --- (This is the new test logic) ---
    // This is a simple smoke test.
    // It just checks that your app built *something*.
    // A good common widget to look for is the MaterialApp.
    expect(find.byType(MaterialApp), findsOneWidget);

    // If you know your app shows a specific screen first
    // (like a Login page), you could test for that instead.
    // For example:
    // expect(find.text('Login'), findsOneWidget);
  });
}
