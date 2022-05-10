abstract class KeySyncEvent {}

class ToggleKeySyncEvent extends KeySyncEvent {
  final bool isLocal;

  ToggleKeySyncEvent(this.isLocal);
}

class ProceedKeySyncEvent extends KeySyncEvent {}

class KeySyncState {
  final bool isLocalSelected;
  final bool? isProcessing;

  KeySyncState(this.isLocalSelected, this.isProcessing);
}
