

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- MODEL CLASS FOR CHAT SESSIONS ---
class ChatSession {
  String id;
  String title;
  List<Map<String, String>> messages;
  DateTime timestamp;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      messages: List<Map<String, String>>.from(
        (json['messages'] as List).map((item) => Map<String, String>.from(item)),
      ),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// --- MAIN SCREEN ---
class AiToolsScreen extends StatefulWidget {
  const AiToolsScreen({super.key});

  @override
  State<AiToolsScreen> createState() => _AiToolsScreenState();
}

class _AiToolsScreenState extends State<AiToolsScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = false;
  String _apiKey = "";
  
  // History State
  List<ChatSession> _sessions = []; 
  String? _currentSessionId; 
  List<Map<String, String>> _currentMessages = []; 

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['API_KEY'] ?? "API_KEY_NOT_FOUND";
    
    _loadHistory().then((_) {
      if (_sessions.isEmpty) {
        _startNewChat();
      } else {
        _startNewChat(); // Start fresh by default, or remove this to load last chat
      }
    });

    if (_apiKey == "API_KEY_NOT_FOUND") {
      _currentMessages.add({
        "role": "ai",
        "text": "Error: API_KEY is not configured. Please contact support."
      });
    }
  }

  // --- STORAGE LOGIC ---
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('chat_history');
    
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      setState(() {
        _sessions = decoded.map((json) => ChatSession.fromJson(json)).toList();
        _sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString('chat_history', encoded);
  }

  // --- SESSION MANAGEMENT ---
  void _startNewChat() {
    setState(() {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentMessages = [];
      _isLoading = false;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  void _loadSession(ChatSession session) {
    setState(() {
      _currentSessionId = session.id;
      _currentMessages = List.from(session.messages);
    });
    Navigator.pop(context);
  }

  void _updateCurrentSessionInHistory() {
    final index = _sessions.indexWhere((s) => s.id == _currentSessionId);
    
    String title = "New Chat";
    if (_currentMessages.isNotEmpty) {
      title = _currentMessages[0]['text'] ?? "Chat";
      if (title.length > 20) title = "${title.substring(0, 20)}...";
    }

    final updatedSession = ChatSession(
      id: _currentSessionId!,
      title: title,
      messages: _currentMessages,
      timestamp: DateTime.now(),
    );

    setState(() {
      if (index != -1) {
        _sessions[index] = updatedSession;
        _sessions.removeAt(index);
        _sessions.insert(0, updatedSession);
      } else {
        _sessions.insert(0, updatedSession);
      }
    });
    
    _saveHistory();
  }

  // --- API LOGIC ---
  Future<void> _generateContent() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _currentMessages.add({"role": "user", "text": prompt});
      _isLoading = true;
      _promptController.clear();
    });

    _updateCurrentSessionInHistory(); // Save user prompt

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$_apiKey",
    );

    final requestBody = {
      "contents": [
        {
          "parts": [{"text": prompt}]
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
        final aiText = json["candidates"][0]["content"]["parts"][0]["text"] ?? "No response";

        setState(() {
          _currentMessages.add({"role": "ai", "text": aiText});
        });
      } else {
        final error = jsonDecode(response.body);
        final msg = error['error']?['message'] ?? "Unknown error";
        setState(() {
          _currentMessages.add({"role": "ai", "text": "❌ Error: $msg"});
        });
      }
    } catch (e) {
      setState(() {
        _currentMessages.add({"role": "ai", "text": "🚫 Failed: $e"});
      });
    }

    setState(() => _isLoading = false);
    _updateCurrentSessionInHistory(); // Save AI response
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      
      // SIDEBAR (DRAWER)
      drawer: Drawer(
        backgroundColor: const Color(0xFFF8F9FA),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startNewChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2934A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("New Chat"),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Recent", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, size: 20),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () => _loadSession(session),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      onPressed: () {
                         setState(() {
                           _sessions.removeAt(index);
                           _saveHistory();
                           if(_currentSessionId == session.id) _startNewChat();
                         });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // TOP BAR
      appBar: AppBar(
        title: const Text(
          "AI Assistant",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE2934A),
        elevation: 1,
        
        // Left Menu Button
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),

        // Right Back Button (Your Request)
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: 'Go Back',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8), // Little padding
        ],
      ),

      // CHAT AREA
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _currentMessages.length,
              itemBuilder: (context, index) {
                final msg = _currentMessages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF4A90E2) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
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
          
          // INPUT AREA
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
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
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