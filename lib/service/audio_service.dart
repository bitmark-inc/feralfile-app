import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/util/log.dart';
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

  StreamSubscription? _recorderSubscription;
  bool _didTalk = false; // Add a flag to track if user spoke

  Future<FlutterSoundRecorder> getRecorder() async {
    if (_recorder == null) {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
    }
    return _recorder!;
  }

  Future<void> startRecording(
      {double silenceThreshold = 50,
      Duration silenceDuration = const Duration(seconds: 2),
      Duration noSpeechDuration = const Duration(seconds: 5),
      FutureOr<void> Function()? onSilenceDetected}) async {
    _didTalk = false; // Reset the flag
    final recorder = await getRecorder();
    final dir = await getTemporaryDirectory();
    _filePath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    var lastLoudTime = DateTime.now();
    await recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
    _recorderSubscription = recorder.onProgress!.listen((event) {
      log.info('Recording progress: ${event.toString()}');
      final double? decibels = event.decibels;
      final now = DateTime.now();

      if (decibels != null) {
        if (decibels > silenceThreshold) {
          // User is talking
          lastLoudTime = now;
          _didTalk = true; // Set flag to true if speech is detected
        } else {
          // Check if silence has lasted more than 3 seconds
          if (now.difference(lastLoudTime).inSeconds >=
              (_didTalk
                  ? silenceDuration.inSeconds
                  : noSpeechDuration.inSeconds)) {
            log.info('Silence detected');
            _recorderSubscription?.cancel();
            onSilenceDetected?.call();
          }
        }
      }
    });
    await recorder.startRecorder(
      toFile: _filePath,
      codec: Codec.aacADTS,
    );
  }

  Future<File?> stopRecording() async {
    if (_recorder == null) return throw AudioRecorderNotOpenedException();
    await _recorder!.stopRecorder();
    _recorderSubscription?.cancel();
    if (_filePath != null && _didTalk) {
      return File(_filePath!);
    } else if (_filePath != null) {
      // If no speech detected, delete the file and return null
      final file = File(_filePath!);
      if (await file.exists()) {
        await file.delete();
        log.info('Deleted silent audio file: $_filePath');
      }
      return null;
    }
    return null; // Should not happen if _filePath is always set in startRecording
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
  noSpeech,
  failedToParseCommand,
  unknown;

  String get message {
    switch (this) {
      case AudioExceptionType.permissionDenied:
        return 'Microphone permission is required.';
      case AudioExceptionType.recordingFailed:
        return 'Failed to start recording';
      case AudioExceptionType.fileNotFound:
        return 'Recorded file not found';
      case AudioExceptionType.noSpeech:
        return 'No speech detected';
      case AudioExceptionType.failedToParseCommand:
        return "Didn't quite get that. Could you ask again how I can help you live with art?";
      case AudioExceptionType.unknown:
      default:
        return 'An unknown error occurred';
    }
  }
}

class AudioException implements Exception {
  final String message;

  AudioException(
    this.message,
  );
}

class AudioPermissionDeniedException implements AudioException {
  @override
  String get message => AudioExceptionType.permissionDenied.message;
}

class AudioRecordingFailedException implements AudioException {
  @override
  String get message => AudioExceptionType.recordingFailed.message;

  final Object? error;

  AudioRecordingFailedException(this.error);
}

class AudioFileNotFoundException implements AudioException {
  @override
  String get message => AudioExceptionType.fileNotFound.message;

  final String filePath;

  AudioFileNotFoundException({required this.filePath});
}

class AudioRecorderNotOpenedException implements AudioException {
  @override
  String get message => 'Audio recorder is not opened';
}

class AudioRecordNoSpeechException implements AudioException {
  @override
  String get message => AudioExceptionType.noSpeech.message;
}

//Failed to parse and validate command
class AudioFailedToParseCommandException implements AudioException {
  @override
  String get message => AudioExceptionType.failedToParseCommand.message;
}
