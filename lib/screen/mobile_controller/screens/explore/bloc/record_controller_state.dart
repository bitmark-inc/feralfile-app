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

  final DP1Intent? lastIntent;
  final DP1Call? lastDP1Call;

  RecordState copyWith({
    DP1Intent? lastIntent,
    DP1Call? lastDP1Call,
  }) =>
      RecordState(
        lastIntent: lastIntent ?? this.lastIntent,
        lastDP1Call: lastDP1Call ?? this.lastDP1Call,
      );
}

class RecordInitialState extends RecordState {
  const RecordInitialState();
}

class RecordRecordingState extends RecordState {
  const RecordRecordingState();
}

class RecordProcessingState extends RecordState {
  RecordProcessingState({
    required this.status,
    super.lastIntent,
    super.lastDP1Call,
    this.statusMessage,
    this.transcription,
  });

  final RecordProcessingStatus status;
  final String? statusMessage;
  final String? transcription;

  @override
  RecordProcessingState copyWith({
    RecordProcessingStatus? status,
    DP1Intent? lastIntent,
    DP1Call? lastDP1Call,
    String? statusMessage,
    String? transcription,
  }) =>
      RecordProcessingState(
        status: status ?? this.status,
        statusMessage: statusMessage ?? this.statusMessage,
        transcription: transcription ?? this.transcription,
        lastIntent: lastIntent ?? this.lastIntent,
        lastDP1Call: lastDP1Call ?? this.lastDP1Call,
      );

  String get processingMessage => statusMessage ?? status.message;
}

class RecordErrorState extends RecordState {
  RecordErrorState({required this.error});

  final Exception error;
}

class RecordSuccessState extends RecordState {
  final String response;
  final String transcription;

  const RecordSuccessState({
    required DP1Intent lastIntent,
    required DP1Call lastDP1Call,
    required this.response,
    required this.transcription,
  }) : super(lastIntent: lastIntent, lastDP1Call: lastDP1Call);
}
