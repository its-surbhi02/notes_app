import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      final res = await auth.signup(email.text, password.text);
                      if (res != "success") {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res ?? "Error")));
                      }
                    },
              child: auth.loading ? const CircularProgressIndicator() : const Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
