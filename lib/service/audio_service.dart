import 'dart:async';
import 'dart:io';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  FlutterSoundRecorder? _recorder;
  String? _filePath;

  Future<bool> askMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    if (_recorder == null) {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
    }
    final dir = await getTemporaryDirectory();
    _filePath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(
      toFile: _filePath,
      codec: Codec.aacADTS,
    );
  }

  Future<File?> stopRecording() async {
    if (_recorder == null) return null;
    await _recorder!.stopRecorder();
    if (_filePath == null) return null;
    return File(_filePath!);
  }

  Future<void> dispose() async {
    await _recorder?.closeRecorder();
    _recorder = null;
  }
}

enum AudioExceptionType {
  permissionDenied,
  recordingFailed,
  fileNotFound,
  unknown;

  String get message {
    switch (this) {
      case AudioExceptionType.permissionDenied:
        return 'Microphone permission denied';
      case AudioExceptionType.recordingFailed:
        return 'Failed to start recording';
      case AudioExceptionType.fileNotFound:
        return 'Recorded file not found';
      case AudioExceptionType.unknown:
      default:
        return 'An unknown error occurred';
    }
  }
}

class AudioServiceException implements Exception {
  final AudioExceptionType type;

  AudioServiceException(this.type);

  @override
  String toString() => 'AudioServiceException: ${type.message}';
}
