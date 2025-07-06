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
        statusMessage: statusMessage ?? this.statusMessage,
      ).copyWith(
        lastIntent: lastIntent,
        lastDP1Call: lastDP1Call,
      );

  String get processingMessage => statusMessage ?? status.message;
}

class RecordErrorState extends RecordState {
  RecordErrorState({required this.error});

  final Exception error;
}

class RecordSuccessState extends RecordState {}
