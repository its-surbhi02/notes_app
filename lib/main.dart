// lib/main.dart

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
  WidgetsFlutterBinding.ensureInitialized();


  await dotenv.load(fileName: ".env");

  // Initialize Supabase (uses env vars from .env)
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Please set SUPABASE_URL and SUPABASE_ANON_KEY in your .env file');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: kDebugMode,
  );

  // Initialize Firebase AFTER Supabase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- INITIALIZE NOTIFICATIONS HERE ---
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
      child: const PrepBuddyApp(),
    ),
  );
}
