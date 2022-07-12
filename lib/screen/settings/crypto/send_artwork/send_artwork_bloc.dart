//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_state.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tezart/tezart.dart';
import 'package:web3dart/web3dart.dart';

class SendArtworkBloc extends Bloc<SendArtworkEvent, SendArtworkState> {
  EthereumService _ethereumService;
  TezosService _tezosService;
  CurrencyService _currencyService;
  AssetToken _asset;
  String? cachedAddress;
  BigInt? cachedBalance;
  bool isEstimating = false;

  final _safeBuffer = BigInt.from(10);

  SendArtworkBloc(
    this._ethereumService,
    this._tezosService,
    this._currencyService,
    this._asset,
  ) : super(SendArtworkState()) {
    final type =
        _asset.blockchain == "ethereum" ? CryptoType.ETH : CryptoType.XTZ;
    on<GetBalanceEvent>((event, emit) async {
      final newState = state.clone();
      newState.wallet = event.wallet;

      final exchangeRate = await _currencyService.getExchangeRates();
      newState.exchangeRate = exchangeRate;

      switch (type) {
        case CryptoType.ETH:
          final ownerAddress = await event.wallet.getETHEip55Address();
          final balance = await _ethereumService.getBalance(ownerAddress);

          newState.balance = balance.getInWei;
          newState.isValid = _isValid(newState);
          break;
        case CryptoType.XTZ:
          final tezosWallet = await event.wallet.getTezosWallet();
          final address = tezosWallet.address;
          final balance = await _tezosService.getBalance(address);

          newState.balance = BigInt.from(balance);
          newState.isValid = _isValid(newState);
          break;
        default:
          break;
      }

      cachedBalance = newState.balance;
      emit(newState);
    });

    on<AddressChangedEvent>((event, emit) async {
      final newState = state.clone();
      newState.isScanQR = event.address.isEmpty;
      newState.isAddressError = false;

      if (event.address.isNotEmpty) {
        switch (type) {
          case CryptoType.ETH:
            try {
              final address = EthereumAddress.fromHex(event.address);
              newState.address = address.hexEip55;
              newState.isAddressError = false;

              add(EstimateFeeEvent(
                  address.hexEip55, _asset.contractAddress!, _asset.tokenId!));
            } catch (err) {
              newState.isAddressError = true;
            }
            break;
          case CryptoType.XTZ:
            if (event.address.startsWith("tz")) {
              newState.address = event.address;
              newState.isAddressError = false;

              add(EstimateFeeEvent(event.address, _asset.contractAddress!, _asset.tokenId!));
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

    on<EstimateFeeEvent>((event, emit) async {
      if (isEstimating) return;

      isEstimating = true;
      final newState = state.clone();

      BigInt? fee;
      switch (type) {
        case CryptoType.ETH:
          final wallet = state.wallet;
          if (wallet == null) return;

          final contractAddress =
              EthereumAddress.fromHex(event.contractAddress);
          final to = EthereumAddress.fromHex(event.address);
          final from =
              EthereumAddress.fromHex(await state.wallet!.getETHAddress());

          final data = await _ethereumService.getERC721TransferTransactionData(
              contractAddress, from, to, event.tokenId);

          fee = await _ethereumService.estimateFee(
              wallet, contractAddress, EtherAmount.zero(), data);
          break;
        case CryptoType.XTZ:
          final wallet = state.wallet;
          if (wallet == null) return;
          final tezosWallet = await wallet.getTezosWallet();
          try {
            final operation = await _tezosService.getFa2TransferOperation(event.contractAddress, tezosWallet.address, event.address, int.parse(event.tokenId));
            final tezosFee = await _tezosService.estimateOperationFee(tezosWallet, [operation]);
            fee = BigInt.from(tezosFee);
          } on TezartNodeError catch (err) {
            UIHelper.showInfoDialog(
              injector<NavigationService>().navigatorKey.currentContext!,
              "Estimation failed",
              getTezosErrorMessage(err),
              isDismissible: true,
            );
          } catch (err) {
            showErrorDialogFromException(err);
          }
          break;
        default:
          break;
      }

      newState.fee = fee;
      newState.balance = cachedBalance;
      newState.address = cachedAddress;
      newState.isValid = _isValid(newState);

      isEstimating = false;
      emit(newState);
    });
  }

  bool _isValid(SendArtworkState state) {
    if (state.address == null) return false;
    if (state.balance == null) return false;
    if (state.fee == null) return false;

    return state.fee! <= state.balance! - _safeBuffer;
  }
}
