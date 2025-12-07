


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


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