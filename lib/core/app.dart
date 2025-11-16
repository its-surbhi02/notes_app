import 'package:flutter/material.dart';
import 'package:notes/core/features/auth/screen/home_screen.dart';
import 'package:notes/core/features/auth/screen/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:notes/core/features/auth/provider/auth_provider.dart';

class PrepBuddyApp extends StatelessWidget {
  const PrepBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PrepBuddy Auth",
      home: auth.user == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
