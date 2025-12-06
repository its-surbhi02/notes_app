import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    if (!await hasPermission()) return;
    
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String filePath = '${appDir.path}/temp_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    
    // Start recording to file
    await _audioRecorder.start(const RecordConfig(), path: filePath);
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}