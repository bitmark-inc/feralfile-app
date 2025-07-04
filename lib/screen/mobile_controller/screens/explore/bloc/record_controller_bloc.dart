// Event
import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/audio_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/mobile_controller_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/log.dart';

part 'record_controller_event.dart';
part 'record_controller_state.dart';

// Bloc
class RecordBloc extends AuBloc<RecordEvent, RecordState> {
  RecordBloc(this.service, this.audioService) : super(RecordInitialState()) {
    // on<PermissionGrantedEvent>((event, emit) {
    //   if (state.error != null &&
    //       state.error is AudioPermissionDeniedException) {
    //     emit(state.copyWith(error: null));
    //   }
    // });

    on<StartRecordingEvent>((event, emit) async {
      _statusTimer?.cancel();
      emit(RecordInitialState().copyWith(messages: state.messages));
      final granted = await audioService.askMicrophonePermission();
      if (!granted) {
        emit(RecordPermissionDeniedState().copyWith(messages: state.messages));
        return;
      }

      await audioService.startRecording();
      emit(RecordRecordingState().copyWith(messages: state.messages));
    });

    on<StopRecordingEvent>((event, emit) async {
      final file = await audioService.stopRecording();
      emit(
        RecordProcessingState(
          status: RecordProcessingStatus.transcribing,
        ).copyWith(messages: state.messages),
      );

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
                  ...List<String>.from(state.messages),
                ];

                emit(
                  RecordProcessingState(
                    status: RecordProcessingStatus.transcribed,
                  ).copyWith(messages: newMessages),
                );

              case NLParserDataType.thinking:
                final thinking = nlParserData.content;
                emit(
                  RecordProcessingState(
                    status: RecordProcessingStatus.thinking,
                    statusMessage: thinking,
                  ).copyWith(messages: state.messages),
                );

              case NLParserDataType.intent:
                final intent =
                    Map<String, dynamic>.from(nlParserData.data as Map);
                emit(
                  RecordProcessingState(
                    status: RecordProcessingStatus.intentReceived,
                    lastIntent: intent,
                  ).copyWith(messages: state.messages),
                );

              case NLParserDataType.dp1Call:
                final dp1Call = Map<String, dynamic>.from(nlParserData.data);
                final intent = state.lastIntent!;
                final deviceName = intent['device_name'] as String?;
                final device = await BluetoothDeviceManager()
                    .pickADeviceToDisplay(deviceName ?? '');
                if (device == null) {
                  emit(
                    RecordErrorState(
                      error: AudioException('No device selected'),
                    ).copyWith(messages: state.messages),
                  );
                  return;
                }

                final items = dp1Call['items'] as List;
                if (items.isEmpty) {
                  emit(
                    RecordErrorState(
                      error: AudioException('No items to display'),
                    ).copyWith(messages: state.messages),
                  );
                  return;
                }

                try {
                  if (BluetoothDeviceManager().castingBluetoothDevice !=
                      device) {
                    emit(
                      RecordProcessingState(
                        status: RecordProcessingStatus.switchingDevice,
                        statusMessage:
                            'Switching to ${deviceName ?? 'FF-X1'}...',
                      ).copyWith(messages: state.messages),
                    );
                    await BluetoothDeviceManager().switchDevice(
                      device,
                    );
                  }

                  emit(
                    RecordProcessingState(
                      status: RecordProcessingStatus.displaying,
                      statusMessage:
                          'Displaying to ${deviceName ?? 'FF-X1'}...',
                    ).copyWith(messages: state.messages),
                  );
                  await injector<CanvasClientServiceV2>()
                      .sendDp1Call(device, dp1Call, intent);
                } catch (e) {
                  log.info(
                    'Error while displaying to ${deviceName ?? 'FF-X1'}: $e',
                  );
                  emit(
                    RecordErrorState(
                      error: AudioException(
                        'Error while displaying to ${deviceName ?? 'FF-X1'}',
                      ),
                    ).copyWith(messages: state.messages),
                  );
                  return;
                }

                emit(
                  RecordSuccessState().copyWith(
                    messages: state.messages,
                    lastIntent: intent,
                    lastDP1Call: dp1Call,
                  ),
                );

              case NLParserDataType.complete:
                log.info('Complete action received');
              // _statusTimer?.cancel();
              // _statusTimer =
              //     Timer.periodic(const Duration(seconds: 3), (timer) {
              //   emit(state.copyWith(status: ''));
              // });

              case NLParserDataType.error:
                final error = nlParserData.content;
                emit(
                  RecordErrorState(
                    error: AudioException(error),
                  ).copyWith(messages: state.messages),
                );

              default:
                log.warning('Unknown NLParserDataType: [${nlParserData.type}');
            }
          } catch (e) {
            log.info('Error processing data: $e');
            emit(
              RecordErrorState(
                error: AudioException('Error processing data: $e'),
              ).copyWith(messages: state.messages),
            );
          }
        }
      } catch (e) {
        emit(
          RecordErrorState(
            error: AudioException('Failed to process audio: $e'),
          ),
        );
      }
    });

    on<SubmitTextEvent>((event, emit) async {
      final newMessages = [
        event.text,
        ...List<String>.from(state.messages),
      ];
      emit(
        RecordProcessingState(
          status: RecordProcessingStatus.transcribed,
        ).copyWith(messages: newMessages),
      );

      // Gọi API lấy intent, dp1_call
      final result = await service.getDP1CallFromText(
        command: event.text,
        deviceNames: ["kitchen", "living_room", "bed room"],
      );
      emit(
        state.copyWith(
          lastIntent: result['intent'] == null
              ? null
              : Map<String, dynamic>.from(result['intent'] as Map),
          lastDP1Call: result['dp1_call'] == null
              ? null
              : Map<String, dynamic>.from(result['dp1_call'] as Map),
          messages: newMessages,
        ),
      );
    });
  }

  final MobileControllerService service;
  final AudioService audioService;
  Timer? _statusTimer;
}
