import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'signup_screen.dart';
import '../widgets/google_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
 
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
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
                      final res = await auth.login(email.text, password.text);
                      if (res != "success") {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res ?? "Error")));
                      }
                    },
              child: auth.loading ? const CircularProgressIndicator() : const Text("Login"),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
              },
              child: const Text("Don't have an account? Sign Up"),
            ),

            const SizedBox(height: 10),
            const GoogleButton(),
          ],
        ),
      ),
    );
  }
}
