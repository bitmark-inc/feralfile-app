//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/biometrics_util.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nft_collection/nft_collection.dart';

class WCSendTransactionBloc
    extends AuBloc<WCSendTransactionEvent, WCSendTransactionState> {
  final NavigationService _navigationService;
  final EthereumService _ethereumService;
  final WalletConnectService _walletConnectService;
  final Wc2Service _wc2Service;
  final ConfigurationService _configurationService;
  final CurrencyService _currencyService;

  WCSendTransactionBloc(
    this._navigationService,
    this._ethereumService,
    this._wc2Service,
    this._walletConnectService,
    this._configurationService,
    this._currencyService,
  ) : super(WCSendTransactionState()) {
    on<WCSendTransactionEstimateEvent>((event, emit) async {
      final WalletStorage persona = LibAukDart.getWallet(event.uuid);
      final newState = state.clone();
      final exchangeRate = await _currencyService.getExchangeRates();
      newState.exchangeRate = exchangeRate;
      newState.feeOptionValue = await _ethereumService.estimateFee(
          persona, event.address, event.amount, event.data);
      newState.fee = newState.feeOptionValue!.getFee(state.feeOption);
      emit(newState);
    });

    on<WCSendTransactionSendEvent>((event, emit) async {
      final sendingState = state.clone();
      sendingState.isSending = true;
      emit(sendingState);

      if (_configurationService.isDevicePasscodeEnabled() &&
          await authenticateIsAvailable()) {
        final localAuth = LocalAuthentication();
        final didAuthenticate = await localAuth.authenticate(
            localizedReason: "authen_for_autonomy".tr());

        if (!didAuthenticate) {
          final newState = sendingState.clone();
          newState.isSending = false;
          emit(newState);
          return;
        }
      }

      final WalletStorage persona = LibAukDart.getWallet(event.uuid);
      final balance =
          await _ethereumService.getBalance(await persona.getETHAddress());
      try {
        final txHash = await _ethereumService.sendTransaction(
            persona, event.to, event.value, event.data,
            feeOption: state.feeOption);
        if (event.isWalletConnect2) {
          await _wc2Service.respondOnApprove(event.topic ?? "", txHash);
        } else {
          _walletConnectService.approveRequest(
              event.peerMeta, event.requestId, txHash);
        }
        injector<PendingTokenService>()
            .checkPendingEthereumTokens(
                await persona.getETHEip55Address(), txHash)
            .then((hasPendingTokens) {
          if (hasPendingTokens) {
            injector<NftCollectionBloc>().add(RefreshNftCollection());
          }
        });
        _navigationService.goBack();
      } catch (e) {
        final newState = sendingState.clone();
        newState.balance = balance.getInWei;
        newState.isSending = false;
        newState.isError = true;
        emit(newState);
        return;
      }
    });

    on<WCSendTransactionRejectEvent>((event, emit) async {
      if (event.isWalletConnect2) {
        _wc2Service.rejectSession(event.topic ?? "");
      } else {
        _walletConnectService.rejectRequest(event.peerMeta, event.requestId);
      }
      _navigationService.goBack();
    });

    on<FeeOptionChangedEvent>((event, emit) async {
      final newState = state.clone();
      newState.feeOption = event.feeOption;
      newState.fee = newState.feeOptionValue!.getFee(newState.feeOption);
      emit(newState);
    });
  }
}
