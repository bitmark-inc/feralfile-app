abstract class ForgetExistEvent {}

class UpdateCheckEvent extends ForgetExistEvent {
  final bool isChecked;

  UpdateCheckEvent(this.isChecked);
}

class ConfirmForgetExistEvent extends ForgetExistEvent {}

class ForgetExistState {
  final bool isChecked;
  final bool? isProcessing;

  ForgetExistState(this.isChecked, this.isProcessing);
}