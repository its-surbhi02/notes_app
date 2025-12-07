
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; 

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFF46D3A);
    const Color backgroundColor = Color(0xFFFFF6F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "General",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: "App Version",
            subtitle: "1.0.0",
            onTap: () {},
          ),
          const SizedBox(height: 20),

          const Text(
            "Monitoring & Debugging",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.bug_report_outlined,
            title: "Test Crash (Crashlytics)",
            subtitle: "Force app crash for testing",
            color: Colors.red,
            onTap: () {
              
              Fluttertoast.showToast(msg: "App will crash in 3 seconds...");
              Future.delayed(const Duration(seconds: 3), () {
                FirebaseCrashlytics.instance.crash();
              });
            },
          ),
          const SizedBox(height: 30),

          const Text(
            "Help & Support",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          // ============================
          // Contact tile with robust mail handling
          // ============================
          _buildSettingTile(
            icon: Icons.email_outlined,
            title: "Contact Us",
            subtitle: "kumarisurbhi.ctps@gmail.com",
            onTap: () async {
              
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'kumarisurbhi.ctps@gmail.com',
                queryParameters: {
                  'subject': 'Support Needed',
                  'body': 'Hi,\n\nI would like help with...',
                },
              );

              try {
                // Prefer opening external mail app
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                } else {
                  // Fallback: copy the email to clipboard and notify the user
                  await Clipboard.setData(
                      const ClipboardData(text: 'kumarisurbhi.ctps@gmail.com'));

                  // Use ScaffoldMessenger for an in-app message (works reliably)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No mail app found — email copied to clipboard.'),
                    ),
                  );
                }
              } catch (e) {
                // Show a minimal toast on error
                Fluttertoast.showToast(msg: 'Could not open email app: $e');

                // And copy to clipboard as a second fallback
                await Clipboard.setData(
                    const ClipboardData(text: 'kumarisurbhi.ctps@gmail.com'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email copied to clipboard.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // -----------------------------------------
  // Reusable Setting Tile
  // -----------------------------------------
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFF46D3A).withOpacity(0.15),
          child: Icon(icon, size: 28, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
