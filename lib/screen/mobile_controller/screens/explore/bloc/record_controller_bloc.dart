// Event
import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/device/ff_bluetooth_device.dart';
import 'package:autonomy_flutter/screen/mobile_controller/extensions/record_processing_status_ext.dart';
import 'package:autonomy_flutter/service/audio_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/mobile_controller_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:bloc/bloc.dart';

part 'record_controller_event.dart';
part 'record_controller_state.dart';

// Bloc
class RecordBloc extends AuBloc<RecordEvent, RecordState> {
  RecordBloc(this.service, this.audioService, this.configurationService)
      : super(const RecordInitialState()) {
    on<PermissionGrantedEvent>(_onPermissionGranted);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingEvent>(_onStopRecording);
    on<SubmitTextEvent>(_onSubmitText);
  }

  final MobileControllerService service;
  final AudioService audioService;
  final ConfigurationService configurationService;
  Timer? _statusTimer;

  void _onPermissionGranted(
    PermissionGrantedEvent event,
    Emitter<RecordState> emit,
  ) {
    if (state is RecordErrorState &&
        (state as RecordErrorState).error is AudioPermissionDeniedException) {
      emit(RecordInitialState());
    }
  }

  Future<void> _onStartRecording(
    StartRecordingEvent event,
    Emitter<RecordState> emit,
  ) async {
    _statusTimer?.cancel();
    emit(const RecordInitialState());

    final granted = await audioService.askMicrophonePermission();
    if (!granted) {
      emit(RecordErrorState(error: AudioPermissionDeniedException()));
      return;
    }

    await audioService.startRecording();
    emit(const RecordRecordingState());
  }

  Future<void> _onStopRecording(
    StopRecordingEvent event,
    Emitter<RecordState> emit,
  ) async {
    final file = await audioService.stopRecording();
    emit(
      RecordProcessingState(
        status: RecordProcessingStatus.transcribing,
      ),
    );

    try {
      final devicesName =
          BluetoothDeviceManager.pairedDevices.map((e) => e.name).toList();
      final stream = await service.getDP1CallFromVoice(
        file: file,
        deviceNames: devicesName,
        withStream: true,
      );
      await _processVoiceStream(stream, emit);
    } catch (e) {
      emit(
        RecordErrorState(
          error: AudioException('Failed to process audio: $e'),
        ),
      );
    }
  }

  Future<void> _onSubmitText(
    SubmitTextEvent event,
    Emitter<RecordState> emit,
  ) async {
    await configurationService.addRecordedMessage(event.text);
    emit(
      RecordProcessingState(
        status: RecordProcessingStatus.transcribed,
      ),
    );

    try {
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
        ),
      );
    } catch (e) {
      emit(
        RecordErrorState(
          error: AudioException('Failed to process text: $e'),
        ),
      );
    }
  }

  Future<void> _processVoiceStream(
    Stream<Map<String, dynamic>> stream,
    Emitter<RecordState> emit,
  ) async {
    await for (final json in stream) {
      try {
        final nlParserData =
            NLParserData.fromJson(Map<String, dynamic>.from(json));
        await _handleNLParserData(nlParserData, emit);
      } catch (e) {
        log.info('Error processing data: $e');
        emit(
          RecordErrorState(
            error: AudioException('Error processing data: $e'),
          ),
        );
      }
    }
  }

  Future<void> _handleNLParserData(
    NLParserData nlParserData,
    Emitter<RecordState> emit,
  ) async {
    switch (nlParserData.type) {
      case NLParserDataType.transcription:
        await _handleTranscription(nlParserData, emit);
      case NLParserDataType.thinking:
        await _handleThinking(nlParserData, emit);
      case NLParserDataType.intent:
        await _handleIntent(nlParserData, emit);
      case NLParserDataType.dp1Call:
        await _handleDP1Call(nlParserData, emit);
      case NLParserDataType.response:
        await _handleResponse(nlParserData, emit);
      case NLParserDataType.complete:
        await _handleComplete(nlParserData, emit);
      case NLParserDataType.error:
        await _handleError(nlParserData, emit);
      default:
        log.warning('Unknown NLParserDataType: [${nlParserData.type}');
    }
  }

  Future<void> _handleTranscription(
    NLParserData nlParserData,
    Emitter<RecordState> emit,
  ) async {
    final transcribe = nlParserData.data['corrected_text'] as String;
    await configurationService.addRecordedMessage(transcribe);
    emit(
      RecordProcessingState(
        status: RecordProcessingStatus.transcribed,
      ),
    );
  }

  Future<void> _handleThinking(
    NLParserData nlParserData,
    Emitter<RecordState> emit,
  ) async {
    final thinking = nlParserData.content;
    emit(
      RecordProcessingState(
        status: RecordProcessingStatus.thinking,
        statusMessage: thinking,
      ),
    );
  }

  Future<void> _handleIntent(
    NLParserData nlParserData,
    Emitter<RecordState> emit,
  ) async {
    final intent = Map<String, dynamic>.from(nlParserData.data as Map);
    emit(
      RecordProcessingState(
        status: RecordProcessingStatus.intentReceived,
        lastIntent: intent,
      ),
    );
  }

  Future<void> _handleDP1Call(
    NLParserData nlParserData,
    Emitter<RecordState> emit,
  ) async {
    final dp1Call = Map<String, dynamic>.from(nlParserData.data);
    final intent = state.lastIntent;

    if (intent == null) {
      emit(
        RecordErrorState(
          error: AudioException('No intent available for DP1 call'),
        ),
      );
      return;
    }

    final items = dp1Call['items'] as List;
    if (items.isEmpty) {
      emit(
        RecordErrorState(
          error: AudioException('No items to display'),
        ),
      );
      return;
    }

    final deviceName = intent['device_name'] as String?;
    final device =
        await BluetoothDeviceManager().pickADeviceToDisplay(deviceName ?? '');

    if (device == null) {
      emit(
        RecordErrorState(
          error: AudioException('No device selected'),
        ),
      );
      return;
    }

    try {
      await _ensureDeviceConnection(device, deviceName, emit);
      await _displayToDevice(device, dp1Call, intent, deviceName, emit);
    } catch (e) {
      log.info('Error while displaying to ${deviceName ?? 'FF-X1'}: $e');
      emit(
        RecordErrorState(
          error: AudioException(
            'Error while displaying to ${deviceName ?? 'FF-X1'}',
          ),
        ),
      );
    }
  }

  Future<void> _ensureDeviceConnection(
    FFBluetoothDevice device,
    String? deviceName,
    Emitter<RecordState> emit,
  ) async {
    if (BluetoothDeviceManager().castingBluetoothDevice != device) {
      emit(
        RecordProcessingState(
          status: RecordProcessingStatus.switchingDevice,
          statusMessage: 'Switching to ${deviceName ?? 'FF-X1'}...',
        ),
      );
      await BluetoothDeviceManager().switchDevice(device);
    }
  }

  Future<void> _displayToDevice(
    FFBluetoothDevice device,
    Map<String, dynamic> dp1Call,
    Map<String, dynamic> intent,
    String? deviceName,
    Emitter<RecordState> emit,
  ) async {
    emit(
      RecordProcessingState(
        status: RecordProcessingStatus.displaying,
        statusMessage: 'Displaying to ${deviceName ?? 'FF-X1'}...',
      ),
    );

    await injector<CanvasClientServiceV2>()
        .sendDp1Call(device, dp1Call, intent);

    emit(
      RecordSuccessState().copyWith(
        lastIntent: intent,
        lastDP1Call: dp1Call,
      ),
    );
  }

  Future<void> _handleResponse(
    NLParserData nlParserData,
    Emitter<RecordState> emit,
  ) async {
    log.info('Response action received: ${nlParserData.data}');
  }

  Future<void> _handleComplete(
    NLParserData nlParserData,
    Emitter<RecordState> emit,
  ) async {
    log.info('Complete action received');
  }

  Future<void> _handleError(
    NLParserData nlParserData,
    Emitter<RecordState> emit,
  ) async {
    final error = nlParserData.content;
    emit(
      RecordErrorState(
        error: AudioException(error),
      ),
    );
  }
}
