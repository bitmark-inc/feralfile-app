//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_state.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/local_auth_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/nft_collection.dart';

class WCSendTransactionBloc
    extends AuBloc<WCSendTransactionEvent, WCSendTransactionState> {
  final NavigationService _navigationService;
  final EthereumService _ethereumService;
  final CurrencyService _currencyService;

  WCSendTransactionBloc(
    this._navigationService,
    this._ethereumService,
    this._currencyService,
  ) : super(WCSendTransactionState()) {
    on<WCSendTransactionEstimateEvent>((event, emit) async {
      final WalletStorage persona = LibAukDart.getWallet(event.uuid);
      final newState = state.clone();
      final exchangeRate = await _currencyService.getExchangeRates();
      newState.exchangeRate = exchangeRate;
      try {
        newState.feeOptionValue = await _ethereumService.estimateFee(
            persona, event.index, event.address, event.amount, event.data);
      } catch (e) {
        _navigationService.showErrorDialog(
            ErrorEvent(e, "estimation_failed".tr(), e.toString(),
                ErrorItemState.tryAgain), cancelAction: () {
          _navigationService.hideInfoDialog();
          return;
        }, defaultAction: () {
          add(event);
        });
      }
      newState.fee = newState.feeOptionValue!.getFee(state.feeOption);

      final balance =
          await _ethereumService.getBalance(await persona.getETHEip55Address());
      newState.balance = balance.getInWei;
      emit(newState);
    });

    on<WCSendTransactionSendEvent>((event, emit) async {
      log.info('[WCSendTransactionBloc][Start] send transaction');
      final sendingState = state.clone();
      sendingState.isSending = true;
      emit(sendingState);

      final didAuthenticate = await LocalAuthenticationService.checkLocalAuth();

      if (!didAuthenticate) {
        final newState = sendingState.clone();
        newState.isSending = false;
        emit(newState);
        return;
      }

      final WalletStorage persona = LibAukDart.getWallet(event.uuid);
      final index = event.index;
      final balance = await _ethereumService
          .getBalance(await persona.getETHEip55Address(index: index));
      try {
        final txHash = await _ethereumService.sendTransaction(
            persona, index, event.to, event.value, event.data,
            feeOption: state.feeOption);
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final signature = await _ethereumService.signPersonalMessage(
            persona, index, Uint8List.fromList(utf8.encode(timestamp)));

        log.info(
            '[WCSendTransactionBloc][End] send transaction success, txHash: $txHash');
        injector<PendingTokenService>()
            .checkPendingEthereumTokens(
          await persona.getETHEip55Address(index: index),
          txHash,
          timestamp,
          signature,
        )
            .then((tokens) {
          if (tokens.isNotEmpty) {
            NftCollectionBloc.eventController
                .add(UpdateTokensEvent(tokens: tokens));
          }
        });
        _navigationService.goBack(result: txHash);
      } catch (e) {
        log.info(
            '[WCSendTransactionBloc][End] send transaction error, error: $e');
        final newState = sendingState.clone();
        newState.balance = balance.getInWei;
        newState.isSending = false;
        newState.isError = true;
        emit(newState);
        return;
      }
    });

    on<FeeOptionChangedEvent>((event, emit) async {
      final newState = state.clone();
      newState.feeOption = event.feeOption;
      newState.fee = newState.feeOptionValue!.getFee(newState.feeOption);
      emit(newState);
    });
  }
}
