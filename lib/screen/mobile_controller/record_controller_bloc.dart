// Event
import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/audio_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/mobile_controller_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
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
  final Map<String, dynamic>? lastIntent;
  final Map<String, dynamic>? lastDP1Call;
  final Exception? error;

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
    Map<String, dynamic>? lastIntent,
    Map<String, dynamic>? lastDP1Call,
    Exception? error,
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
        emit(state.copyWith(error: AudioPermissionDeniedException()));
        return;
      }
      await audioService.startRecording();
      emit(state.copyWith(isRecording: true));
    });
    on<StopRecordingEvent>((event, emit) async {
      emit(state.copyWith(isRecording: false, error: null));
      final file = await audioService.stopRecording();
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
                final intent =
                    Map<String, dynamic>.from(nlParserData.data as Map);
                emit(state.copyWith(
                    status: 'Intent received.',
                    lastIntent: intent,
                    error: null));
              case NLParserDataType.complete:
                log.info('Complete action received');
              // _statusTimer?.cancel();
              // _statusTimer =
              //     Timer.periodic(const Duration(seconds: 3), (timer) {
              //   emit(state.copyWith(status: ''));
              // });

              case NLParserDataType.dp1Call:
                final dp1Call = Map<String, dynamic>.from(nlParserData.data);
                final intent = state.lastIntent!;
                final deviceName = intent['device_name'] as String?;
                final device = await BluetoothDeviceManager()
                    .pickADeviceToDisplay(deviceName ?? '');
                if (device == null) {
                  emit(state.copyWith(
                      error: AudioException('No device selected')));
                  return;
                }
                emit(state.copyWith(
                    status: 'Sending to device ${deviceName ?? 'FF-X1'}...'));
                try {
                  await injector<CanvasClientServiceV2>()
                      .sendDp1Call(device, dp1Call, intent);
                } catch (e) {
                  log.info('Error sending DP1 call: $e');
                  emit(state.copyWith(
                      error: AudioException(
                          'Error sending to ${deviceName ?? 'FF-X1'}: $e')));
                  return;
                }
                emit(state.copyWith(
                  lastIntent: intent,
                  lastDP1Call: dp1Call,
                  error: null,
                  status: 'Sent to device: ${deviceName ?? 'FF-X1'}',
                ));
              case NLParserDataType.error:
                final error = nlParserData.content;
                emit(state.copyWith(error: AudioException(error)));
                break;
              default:
                log.warning('Unknown NLParserDataType: [${nlParserData.type}');
            }
          } catch (e) {
            log.info('Error processing data: $e');
            emit(state.copyWith(
                error: AudioException('Error processing data: $e')));
          }
        }
      } catch (e) {
        emit(state.copyWith(
            error: AudioException('Failed to process audio: $e')));
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
        lastIntent: result['intent'] == null
            ? null
            : Map<String, dynamic>.from(result['intent'] as Map),
        lastDP1Call: result['dp1_call'] == null
            ? null
            : Map<String, dynamic>.from(result['dp1_call'] as Map),
      ));
    });
  }
}
