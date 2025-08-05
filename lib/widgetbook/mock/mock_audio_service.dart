import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/service/audio_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MockAudioService extends AudioService {
  FlutterSoundRecorder? _recorder;
  String? _filePath;
  bool _isRecording = false;

  @override
  Future<bool> askMicrophonePermission() async {
    // Mock permission granted
    return true;
  }

  StreamSubscription? _recorderSubscription;
  bool _didTalk = false;

  @override
  Future<FlutterSoundRecorder> getRecorder() async {
    if (_recorder == null) {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
    }
    return _recorder!;
  }

  @override
  Future<void> startRecording({
    double silenceThreshold = 50,
    Duration silenceDuration = const Duration(seconds: 2),
    Duration noSpeechDuration = const Duration(seconds: 5),
    FutureOr<void> Function()? onSilenceDetected,
  }) async {
    _didTalk = false;
    _isRecording = true;

    final recorder = await getRecorder();
    final dir = await getTemporaryDirectory();
    _filePath =
        '${dir.path}/mock_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

    var lastLoudTime = DateTime.now();

    await recorder.setSubscriptionDuration(const Duration(milliseconds: 500));

    // Mock recording progress
    _recorderSubscription = Stream.periodic(
      const Duration(milliseconds: 500),
      (index) {
        if (index < 10) {
          // Simulate speech for first 5 seconds
          _didTalk = true;
          lastLoudTime = DateTime.now();
          return RecordingDisposition(
            Duration(milliseconds: index * 500),
            60.0 + (index * 2.0), // Simulate varying volume
          );
        } else {
          // Simulate silence after 5 seconds
          if (DateTime.now().difference(lastLoudTime).inSeconds >=
              silenceDuration.inSeconds) {
            log.info('Mock silence detected');
            _recorderSubscription?.cancel();
            onSilenceDetected?.call();
          }
          return RecordingDisposition(
            Duration(milliseconds: index * 500),
            20.0, // Low volume for silence
          );
        }
      },
    ).listen((event) {
      log.info('Mock recording progress: ${event.toString()}');
    });

    await recorder.startRecorder(
      toFile: _filePath,
      codec: Codec.aacADTS,
    );
  }

  @override
  Future<File?> stopRecording() async {
    if (_recorder == null) {
      throw AudioRecorderNotOpenedException();
    }

    _isRecording = false;
    await _recorder!.stopRecorder();
    _recorderSubscription?.cancel();

    if (_filePath != null && _didTalk) {
      // Create a mock audio file
      final file = File(_filePath!);
      await file.writeAsBytes(
          List.generate(1024, (index) => index % 256)); // Mock audio data
      return file;
    } else if (_filePath != null) {
      // If no speech detected, delete the file and return null
      final file = File(_filePath!);
      if (await file.exists()) {
        await file.delete();
        log.info('Deleted mock silent audio file: $_filePath');
      }
      return null;
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    await _recorder?.closeRecorder();
    _recorder = null;
    _isRecording = false;
  }

  bool get isRecording => _isRecording;
}
