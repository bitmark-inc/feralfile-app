part of 'record_controller_bloc.dart';

// class RecordState {
//   RecordState({
//     this.isRecording = false,
//     this.messages = const [],
//     this.status,
//     this.lastIntent,
//     this.lastDP1Call,
//     this.error,
//     this.isProcessing = false,
//   });

//   final bool isRecording;
//   final bool isProcessing;
//   final List<String> messages;
//   final String? status;
//   final Map<String, dynamic>? lastIntent;
//   final Map<String, dynamic>? lastDP1Call;
//   final Exception? error;

//   static const _sentinel = Object();

//   RecordState copyWith({
//     bool? isRecording,
//     bool? isProcessing,
//     List<String>? messages,
//     Object? status = _sentinel,
//     Map<String, dynamic>? lastIntent,
//     Map<String, dynamic>? lastDP1Call,
//     Object? error = _sentinel,
//     bool forceUpdateErrorIfNull = false,
//   }) =>
//       RecordState(
//         isRecording: isRecording ?? this.isRecording,
//         isProcessing: isProcessing ?? this.isProcessing,
//         messages: messages ?? this.messages,
//         status: status != _sentinel ? status as String? : this.status,
//         lastIntent: lastIntent ?? this.lastIntent,
//         lastDP1Call: lastDP1Call ?? this.lastDP1Call,
//         error: error != _sentinel ? error as Exception? : this.error,
//       );
// }

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
  const RecordState(
      {this.lastIntent, this.lastDP1Call, this.messages = const []});

  final Map<String, dynamic>? lastIntent;
  final Map<String, dynamic>? lastDP1Call;
  final List<String> messages;

  RecordState copyWith({
    Map<String, dynamic>? lastIntent,
    Map<String, dynamic>? lastDP1Call,
    List<String>? messages,
  }) =>
      RecordState(
        lastIntent: lastIntent ?? this.lastIntent,
        lastDP1Call: lastDP1Call ?? this.lastDP1Call,
        messages: messages ?? this.messages,
      );
}

class RecordInitialState extends RecordState {}

class RecordRecordingState extends RecordState {}

class RecordProcessingState extends RecordState {
  RecordProcessingState({
    required this.status,
    super.lastIntent,
    super.lastDP1Call,
    super.messages,
    this.statusMessage,
  });

  final RecordProcessingStatus status;
  final String? statusMessage;

  @override
  RecordProcessingState copyWith({
    RecordProcessingStatus? status,
    Map<String, dynamic>? lastIntent,
    Map<String, dynamic>? lastDP1Call,
    List<String>? messages,
    String? statusMessage,
  }) =>
      RecordProcessingState(
        status: status ?? this.status,
        lastIntent: lastIntent ?? this.lastIntent,
        lastDP1Call: lastDP1Call ?? this.lastDP1Call,
        messages: messages ?? this.messages,
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
