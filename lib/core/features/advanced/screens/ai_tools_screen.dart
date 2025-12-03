// import 'package:flutter/material.dart';

// class AiToolsScreen extends StatelessWidget {
//   const AiToolsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const Color primaryColor = Color(0xFFF46D3A);
//     const Color backgroundColor = Color(0xFFFFF6F0);

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         title: const Text("AI Tools"),
//         backgroundColor: primaryColor,
//         elevation: 0,
//       ),

//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: ListView(
//           children: [

//             const SizedBox(height: 10),

//             _buildToolCard(
//               title: "AI Note Assistant",
//               subtitle: "Generate smart notes, summaries, and quick ideas.",
//               icon: Icons.psychology_alt,
//               onTap: () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Coming Soon…")),
//                 );
//               },
//             ),

//             const SizedBox(height: 12),

//             _buildToolCard(
//               title: "Voice to Text",
//               subtitle: "Convert speech into text using AI transcription.",
//               icon: Icons.mic,
//               onTap: () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Voice tool coming soon 🎤")),
//                 );
//               },
//             ),

//             const SizedBox(height: 12),

//             _buildToolCard(
//               title: "AI Text Improve",
//               subtitle: "Fix grammar, rewrite notes, or enhance writing.",
//               icon: Icons.upgrade,
//               onTap: () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Enhancement tool coming soon ✨")),
//                 );
//               },
//             ),

//             const SizedBox(height: 12),

//             _buildToolCard(
//               title: "AI Chat",
//               subtitle: "Ask anything to your personal assistant.",
//               icon: Icons.chat_bubble_outline,
//               onTap: () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("AI Chat coming soon 🤖")),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildToolCard({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       elevation: 3,
//       shadowColor: Colors.black12,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(18),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 28,
//                 backgroundColor: const Color(0xFFF46D3A).withOpacity(0.15),
//                 child: Icon(icon, size: 32, color: const Color(0xFFF46D3A)),
//               ),
//               const SizedBox(width: 18),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         )),
//                     const SizedBox(height: 6),
//                     Text(subtitle,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey,
//                         )),
//                   ],
//                 ),
//               ),
//               const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

//-------------------------------------------------------------------------------


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ❌ The top-level variable has been REMOVED

class AiToolsScreen extends StatefulWidget {
  const AiToolsScreen({super.key});

  @override
  State<AiToolsScreen> createState() => _AiToolsScreenState();
}

class _AiToolsScreenState extends State<AiToolsScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  final List<Map<String, String>> _messages = [];

  // ✅ Store the API key in the widget's state
  String _apiKey = "";

  @override
  void initState() {
    super.initState();
    // ✅ Load the key here, after main.dart has loaded the .env file
    _apiKey = dotenv.env['API_KEY'] ?? "API_KEY_NOT_FOUND";

    if (_apiKey == "API_KEY_NOT_FOUND") {
      // Optional: Show an error in your chat or console
      print("Error: API_KEY not found in .env file.");
      _messages.add({
        "role": "ai",
        "text": "Error: API_KEY is not configured. Please contact support."
      });
    }
  }

  /// 🔥 Gemini API Call
  Future<void> _generateContent() async {
    final prompt = _promptController.text.trim();

    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a message."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Add user message
    setState(() {
      _messages.add({"role": "user", "text": prompt});
      _isLoading = true;
      _promptController.clear();
    });

    // API URL
    final url = Uri.parse(
      // ✅ Use the state variable _apiKey
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$_apiKey",
    );

    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final aiText =
            json["candidates"][0]["content"]["parts"][0]["text"] ?? "No response";

        setState(() {
          _messages.add({"role": "ai", "text": aiText});
        });
      } else {
        final error = jsonDecode(response.body);
        final msg = error['error']?['message'] ?? "Unknown error";

        setState(() {
          _messages.add({"role": "ai", "text": "❌ API Error: $msg"});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "text": "🚫 Failed: $e"});
      });
    }

    setState(() => _isLoading = false);

    // Auto-scroll to latest
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),

      /// Top AppBar
      appBar: AppBar(
        title: const Text(
          "Your AI Assistant",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE2934A),
        elevation: 1,
      ),

      /// Body: Chat messages + Input
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF4A90E2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),

                    /// SELECTABLE TEXT
                    child: SelectableText(
                      msg["text"] ?? "",
                      style: TextStyle(
                        fontSize: 15,
                        color: isUser ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _generateContent(),
                  ),
                ),

                /// Send Button
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Color(0xFF4A90E2)),
                  onPressed: _isLoading ? null : _generateContent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}