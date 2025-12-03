// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../provider/auth_provider.dart';

// class GoogleButton extends StatelessWidget {
//   const GoogleButton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final auth = Provider.of<AuthProvider>(context);

//     return ElevatedButton.icon(
//       icon: const Icon(Icons.login),
//       label: const Text("Sign in with Google"),
//       onPressed: auth.loading
//           ? null
//           : () async {
//               final res = await auth.googleSignIn();
//               if (res != "success") {
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res ?? "Error")));
//               }
//             },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:notes/core/features/auth/screen/home_screen.dart';
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
              
              // Check if widget is still in the tree after async gap
              if (!context.mounted) return; 

              if (res == "success") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              } else {
                // Handle Error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res ?? "Error")),
                );
              }
            },
    );
  }
}