//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_state.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:tezart/tezart.dart';
import 'package:web3dart/web3dart.dart';

class SendCryptoBloc extends AuBloc<SendCryptoEvent, SendCryptoState> {
  EthereumService _ethereumService;
  TezosService _tezosService;
  CurrencyService _currencyService;
  CryptoType _type;
  String? cachedAddress;
  BigInt? cachedAmount;
  bool isEstimating = false;

  final _safeBuffer = BigInt.from(10);

  SendCryptoBloc(
    this._ethereumService,
    this._tezosService,
    this._currencyService,
    this._type,
  ) : super(SendCryptoState()) {
    on<GetBalanceEvent>((event, emit) async {
      final newState = state.clone();
      newState.wallet = event.wallet;

      final exchangeRate = await _currencyService.getExchangeRates();
      newState.exchangeRate = exchangeRate;

      switch (_type) {
        case CryptoType.ETH:
          final ownerAddress = await event.wallet.getETHEip55Address();
          final balance = await _ethereumService.getBalance(ownerAddress);

          newState.balance = balance.getInWei;

          if (state.fee != null) {
            final maxAllow = balance.getInWei - state.fee! - _safeBuffer;
            newState.maxAllow = maxAllow;
            newState.isValid = _isValid(newState);
          }
          break;
        case CryptoType.XTZ:
          final tezosWallet = await event.wallet.getTezosWallet();
          final address = tezosWallet.address;
          final balance = await _tezosService.getBalance(address);

          newState.balance = BigInt.from(balance);
          if (state.fee != null) {
            final maxAllow = newState.balance! - state.fee! - _safeBuffer;
            newState.maxAllow = maxAllow;
            newState.isValid = _isValid(newState);
          }

          break;
        default:
          break;
      }

      emit(newState);
    });

    on<AddressChangedEvent>((event, emit) async {
      final newState = state.clone();
      newState.isScanQR = event.address.isEmpty;
      newState.isAddressError = false;

      if (event.address.isNotEmpty) {
        switch (_type) {
          case CryptoType.ETH:
            try {
              final address = EthereumAddress.fromHex(event.address);
              newState.address = address.hexEip55;
              newState.isAddressError = false;

              add(EstimateFeeEvent(address.hexEip55, BigInt.zero));
            } catch (err) {
              newState.isAddressError = true;
            }
            break;
          case CryptoType.XTZ:
            if (event.address.startsWith("tz")) {
              newState.address = event.address;
              newState.isAddressError = false;

              add(EstimateFeeEvent(event.address, BigInt.one));
            } else {
              newState.isAddressError = true;
            }
            break;
          default:
            break;
        }
      }

      cachedAddress = newState.address;
      emit(newState);
    });

    on<AmountChangedEvent>((event, emit) async {
      final newState = state.clone();

      if (event.amount.isNotEmpty) {
        double value = double.tryParse(event.amount) ?? 0;
        if (!state.isCrypto) {
          switch (_type) {
            case CryptoType.ETH:
              value *= double.parse(state.exchangeRate.eth);
              break;
            case CryptoType.XTZ:
              value *= double.parse(state.exchangeRate.xtz);
              break;
            default:
              break;
          }
        }

        final amount =
            BigInt.from(value * pow(10, _type == CryptoType.ETH ? 18 : 6));

        newState.amount = amount;
        newState.isValid = _isValid(newState);
        newState.isAmountError = !newState.isValid &&
            state.address != null &&
            state.maxAllow != null;
      } else {
        newState.amount = null;
        newState.isValid = false;
        newState.isAmountError = false;
      }

      cachedAmount = newState.amount;
      emit(newState);
    });

    on<CurrencyTypeChangedEvent>((event, emit) async {
      final newState = state.clone();

      newState.isCrypto = event.isCrypto;
      emit(newState);
    });

    on<EstimateFeeEvent>((event, emit) async {
      if (isEstimating) return;

      isEstimating = true;

      final newState = state.clone();

      BigInt fee;

      switch (_type) {
        case CryptoType.ETH:
          final address = EthereumAddress.fromHex(event.address);
          final wallet = state.wallet;
          if (wallet == null) return;
          fee = await _ethereumService.estimateFee(
              wallet, address, EtherAmount.inWei(event.amount), null);
          break;
        case CryptoType.XTZ:
          final wallet = state.wallet;
          if (wallet == null) return;
          final tezosWallet = await wallet.getTezosWallet();
          try {
            final tezosFee = await _tezosService.estimateFee(
                tezosWallet, event.address, event.amount.toInt());
            fee = BigInt.from(tezosFee);
          } on TezartNodeError catch (err) {
            UIHelper.showInfoDialog(
              injector<NavigationService>().navigatorKey.currentContext!,
              "Estimation failed",
              getTezosErrorMessage(err),
              isDismissible: true,
            );
            fee = BigInt.zero;
          } catch (err) {
            showErrorDialogFromException(err);
            fee = BigInt.zero;
          }
          break;
        default:
          fee = BigInt.zero;
      }

      newState.fee = fee;

      if (state.balance != null) {
        var maxAllow = state.balance! - fee - _safeBuffer;
        if (maxAllow < BigInt.zero) maxAllow = BigInt.zero;
        newState.maxAllow = maxAllow;
        newState.address = cachedAddress;
        newState.amount = cachedAmount;
        newState.isValid = _isValid(newState);
      }

      isEstimating = false;
      emit(newState);
    });
  }

  bool _isValid(SendCryptoState state) {
    if (state.amount == null) return false;
    if (state.address == null) return false;
    if (state.maxAllow == null) return false;

    final amount = state.amount!;

    return amount > BigInt.zero && amount <= state.maxAllow!;
  }
}
