import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_state.dart';
import 'package:autonomy_flutter/service/iap_service.dart';

class SubscriptionBloc extends AuBloc<SubscriptionEvent, SubscriptionState> {
  final IAPService _iapService;
  SubscriptionBloc(this._iapService) : super(SubscriptionState()) {
    on<GetSubscriptionEvent>((event, emit) async {
      final isSubscribed = await _iapService.isSubscribed();
      emit(state.copyWith(
        isSubscribed: isSubscribed,
      ));
    });
  }
}
