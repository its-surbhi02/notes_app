


// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:notes/core/features/notes/services/notification_service.dart';
// import 'package:provider/provider.dart';
// import 'firebase_options.dart';
// import 'core/app.dart'; 
// import 'core/features/auth/provider/auth_provider.dart'; 
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/foundation.dart';

// Future<void> main() async {
//   // Required for async operations before runApp()
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Initialize Firebase
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   // Load the environment variables from your .env file
//   await dotenv.load(fileName: ".env");

//   // --- INITIALIZE NOTIFICATIONS HERE ---
//   // We await this so we get the permission and token before the UI builds
//   await NotificationService().initNotifications();

//   if (kDebugMode) {
//     await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
//   }

//   // Run the app
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//       ],
//       // Make sure 'PrepBuddyApp' is your main app widget
//       child: const PrepBuddyApp(), 
//     ),
//   );
// }


import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:notes/core/features/notes/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/app.dart';
import 'core/features/auth/provider/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

// Supabase
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Required for async operations before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Load the environment variables from your .env file FIRST
  // (we need these for Supabase initialization)
  await dotenv.load(fileName: ".env");

  // Initialize Supabase (uses env vars from .env)
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    // Fail fast with helpful error
    throw Exception('Please set SUPABASE_URL and SUPABASE_ANON_KEY in your .env file');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    // optional: set local debug flag for dev
    debug: kDebugMode,
  );

  // Initialize Firebase AFTER Supabase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- INITIALIZE NOTIFICATIONS HERE ---
  // We await this so we get the permission and token before the UI builds
  await NotificationService().initNotifications();

  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }

  // Run the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      // Make sure 'PrepBuddyApp' is your main app widget
      child: const PrepBuddyApp(),
    ),
  );
}
