// Event
import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/service/audio_service.dart';
import 'package:autonomy_flutter/service/mobile_controller_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/log.dart';

abstract class RecordEvent {}

class StartRecordingEvent extends RecordEvent {}

class StopRecordingEvent extends RecordEvent {}

class SubmitTextEvent extends RecordEvent {
  final String text;

  SubmitTextEvent(this.text);
}

// State
class RecordState {
  final bool isRecording;
  final List<String> messages;
  final String? status;
  final String? lastIntent;
  final Map<String, dynamic>? lastDP1Call;
  final String? error;

  RecordState({
    this.isRecording = false,
    this.messages = const [],
    this.status,
    this.lastIntent,
    this.lastDP1Call,
    this.error,
  });

  RecordState copyWith({
    bool? isRecording,
    List<String>? messages,
    String? status,
    String? lastIntent,
    Map<String, dynamic>? lastDP1Call,
    String? error,
  }) =>
      RecordState(
        isRecording: isRecording ?? this.isRecording,
        messages: messages ?? this.messages,
        status: status ?? this.status,
        lastIntent: lastIntent ?? this.lastIntent,
        lastDP1Call: lastDP1Call ?? this.lastDP1Call,
        error: error,
      );
}

// Bloc
class RecordBloc extends AuBloc<RecordEvent, RecordState> {
  final MobileControllerService service;
  final AudioService audioService;
  Timer? _statusTimer;

  RecordBloc(this.service, this.audioService) : super(RecordState()) {
    on<StartRecordingEvent>((event, emit) async {
      _statusTimer?.cancel();
      emit(state.copyWith(error: null, status: ''));
      final granted = await audioService.askMicrophonePermission();
      if (!granted) {
        emit(state.copyWith(error: 'Microphone permission denied'));
        return;
      }
      await audioService.startRecording();
      emit(state.copyWith(isRecording: true));
    });
    on<StopRecordingEvent>((event, emit) async {
      emit(state.copyWith(isRecording: false, error: null));
      final file = await audioService.stopRecording();
      if (file == null) {
        emit(state.copyWith(
            error: 'Recorded file not found, please try again.'));
        return;
      }

      emit(state.copyWith(status: 'Getting transcription...'));

      // Gửi file audio qua service để lấy text và dp1_call
      try {
        final devicesName =
            BluetoothDeviceManager.pairedDevices.map((e) => e.name).toList();
        final stream = await service.getDP1CallFromVoice(
          file: file,
          deviceNames: devicesName,
          withStream: true,
        );
        await for (final json in stream) {
          try {
            final nlParserData =
                NLParserData.fromJson(Map<String, dynamic>.from(json));
            switch (nlParserData.type) {
              case NLParserDataType.transcription:
                final transcribe =
                    nlParserData.data['corrected_text'] as String;
                final newMessages = [
                  transcribe,
                  ...List<String>.from(state.messages)
                ];
                emit(state.copyWith(
                    messages: newMessages,
                    error: null,
                    status: 'Processing...'));
              case NLParserDataType.thinking:
                final thinking = nlParserData.content;
                emit(state.copyWith(status: thinking, error: null));
              case NLParserDataType.intent:
                final data = nlParserData.data;
                final action = data['action'] as String;
              case NLParserDataType.complete:
                log.info('Complete action received');
                _statusTimer?.cancel();
                _statusTimer =
                    Timer.periodic(const Duration(seconds: 3), (timer) {
                  emit(state.copyWith(status: ''));
                });

              case NLParserDataType.result:
                emit(state.copyWith(status: 'Sending to device...'));
                final data = nlParserData.data;
                final intent = data['intent'];
                final deviceName = intent['device_name'] as String?;
                final scheduleTime = intent['schedule_time'] == null
                    ? null
                    : DateTime.parse(intent['schedule_time'] as String);
                // convert scheduleTime to local time. Example 2025-06-23T18:00:00.000Z -> 2025-06-23 18:00:00 in local time, means that remove the Z at the end
                final scheduleTimeInLocal = scheduleTime?.localTimeWithoutShift;

                final dp1Call = data['dp1_call'];
                await Future.delayed(const Duration(seconds: 2));
                emit(state.copyWith(
                  lastIntent: intent?.toString(),
                  lastDP1Call: dp1Call as Map<String, dynamic>?,
                  error: null,
                  status:
                      'Sent to device: ${deviceName ?? 'Unknown'} at ${scheduleTimeInLocal?.toString() ?? 'now'}',
                ));
                break;
              case NLParserDataType.error:
                final error = nlParserData.content;
                emit(state.copyWith(error: error));
                break;
              default:
                log.warning('Unknown NLParserDataType: [${nlParserData.type}');
            }
          } catch (e) {
            log.info('Error processing data: $e');
            emit(state.copyWith(error: 'Error processing data: $e'));
          }
        }
      } catch (e) {
        emit(state.copyWith(error: 'Lỗi xử lý audio: $e'));
      }
    });
    on<SubmitTextEvent>((event, emit) async {
      final newMessages = List<String>.from(state.messages)..add(event.text);
      emit(state.copyWith(messages: newMessages, error: null));
      // Gọi API lấy intent, dp1_call
      final result = await service.getDP1CallFromText(
        command: event.text,
        deviceNames: ["kitchen", "living_room", "bed room"],
      );
      emit(state.copyWith(
        lastIntent: result['intent']?.toString(),
        lastDP1Call: result['dp1_call'] == null
            ? null
            : Map<String, dynamic>.from(result['dp1_call'] as Map),
      ));
    });
  }
}
