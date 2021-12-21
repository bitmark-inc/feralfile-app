import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_state.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WCSendTransactionBloc
    extends Bloc<WCSendTransactionEvent, WCSendTransactionState> {
  final NavigationService _navigationService;
  final EthereumService _ethereumService;
  final WalletConnectService _walletConnectService;

  WCSendTransactionBloc(this._navigationService, this._ethereumService,
      this._walletConnectService)
      : super(WCSendTransactionState()) {
    on<WCSendTransactionEstimateEvent>((event, emit) async {
      state.fee =
          await _ethereumService.estimateFee(event.address, event.amount);
      emit(state);
    });

    on<WCSendTransactionSendEvent>((event, emit) async {
      final txHash = await _ethereumService.sendTransaction(
          event.to, event.value, event.gas, event.data);
      _walletConnectService.approveRequest(event.requestId, txHash);
      _navigationService.goBack();
    });

    on<WCSendTransactionRejectEvent>((event, emit) async {
      _walletConnectService.rejectRequest(event.requestId);
      _navigationService.goBack();
    });
  }
}
