part of 'record_controller_bloc.dart';

enum RecordProcessingStatus {
  transcribing,
  transcribed,
  thinking,
  intentReceived,
  dp1CallReceived,
  switchingDevice,
  displaying,
}

class RecordState {
  const RecordState({
    this.lastIntent,
    this.lastDP1Call,
  });

  final Map<String, dynamic>? lastIntent;
  final Map<String, dynamic>? lastDP1Call;

  RecordState copyWith({
    Map<String, dynamic>? lastIntent,
    Map<String, dynamic>? lastDP1Call,
  }) =>
      RecordState(
        lastIntent: lastIntent ?? this.lastIntent,
        lastDP1Call: lastDP1Call ?? this.lastDP1Call,
      );
}

class RecordInitialState extends RecordState {}

class RecordRecordingState extends RecordState {}

class RecordProcessingState extends RecordState {
  RecordProcessingState({
    required this.status,
    super.lastIntent,
    super.lastDP1Call,
    this.statusMessage,
  });

  final RecordProcessingStatus status;
  final String? statusMessage;

  @override
  RecordProcessingState copyWith({
    RecordProcessingStatus? status,
    Map<String, dynamic>? lastIntent,
    Map<String, dynamic>? lastDP1Call,
    String? statusMessage,
  }) =>
      RecordProcessingState(
        status: status ?? this.status,
        lastIntent: lastIntent ?? this.lastIntent,
        lastDP1Call: lastDP1Call ?? this.lastDP1Call,
        statusMessage: statusMessage ?? this.statusMessage,
      );

  String get processingMessage {
    if (statusMessage != null) return statusMessage!;
    switch (status) {
      case RecordProcessingStatus.transcribing:
        return 'Getting transcription...';
      case RecordProcessingStatus.transcribed:
        return 'Processing...';
      case RecordProcessingStatus.intentReceived:
        return 'Intent received.';
      case RecordProcessingStatus.thinking:
      case RecordProcessingStatus.dp1CallReceived:
      case RecordProcessingStatus.switchingDevice:
      case RecordProcessingStatus.displaying:
        return statusMessage ?? '';
    }
  }
}

class RecordErrorState extends RecordState {
  RecordErrorState({required this.error});

  final Exception error;
}

class RecordSuccessState extends RecordState {}

class RecordPermissionDeniedState extends RecordErrorState {
  RecordPermissionDeniedState()
      : super(error: AudioPermissionDeniedException());
}
