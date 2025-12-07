

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AssemblyAIService {
  final String _apiKey = dotenv.env['ASSEMBLYAI_API_KEY'] ?? ''; 
  final String _baseUrl = 'https://api.assemblyai.com/v2';

  Future<String?> transcribeAudio(String audioUrl) async {
    print("DEBUG: API Key found? ${_apiKey.isNotEmpty}");
    
    if (_apiKey.isEmpty) {
      print('ERROR: API Key is missing.');
      return null;
    }

    try {
      // 1. Submit
      print("DEBUG: Submitting audio...");
      final response = await http.post(
        Uri.parse('$_baseUrl/transcript'),
        headers: {'authorization': _apiKey, 'content-type': 'application/json'},
        body: jsonEncode({'audio_url': audioUrl}),
      );

      if (response.statusCode != 200) {
        print('ERROR: Submit Failed: ${response.body}');
        return null;
      }

      final String transcriptId = jsonDecode(response.body)['id'];
      print("DEBUG: Started ID: $transcriptId");

      // 2. Poll
      while (true) {
        final pollingResponse = await http.get(
          Uri.parse('$_baseUrl/transcript/$transcriptId'),
          headers: {'authorization': _apiKey},
        );

        final statusData = jsonDecode(pollingResponse.body);
        final status = statusData['status'];
        print("DEBUG: Status: $status");

        if (status == 'completed') {
         
          final String finalText = statusData['text'] ?? ""; 
          
          if (finalText.isEmpty) {
            print("WARNING: Transcription completed but text is empty. (Did you record silence?)");
            return "[No speech detected]";
          }
          
          return finalText;
          
        } else if (status == 'error') {
          print('ERROR: Failed: ${statusData['error']}');
          return null;
        }

        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      print('ERROR: Exception: $e');
      return null;
    }
  }
}