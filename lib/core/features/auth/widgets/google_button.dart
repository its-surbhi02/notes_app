import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return ElevatedButton.icon(
      icon: const Icon(Icons.login),
      label: const Text("Sign in with Google"),
      onPressed: auth.loading
          ? null
          : () async {
              final res = await auth.googleSignIn();
              if (res != "success") {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res ?? "Error")));
              }
            },
    );
  }
}
