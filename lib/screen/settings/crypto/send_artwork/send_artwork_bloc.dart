//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_state.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/rpc_error_extension.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tezart/tezart.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';

class SendArtworkBloc extends AuBloc<SendArtworkEvent, SendArtworkState> {
  final EthereumService _ethereumService;
  final TezosService _tezosService;
  final CurrencyService _currencyService;
  final NavigationService _navigationService;
  final AssetToken _asset;
  String? cachedAddress;
  BigInt? cachedBalance;

  final _safeBuffer = BigInt.from(10);

  SendArtworkBloc(
    this._ethereumService,
    this._tezosService,
    this._currencyService,
    this._navigationService,
    this._asset,
  ) : super(SendArtworkState()) {
    final type =
        _asset.blockchain == 'ethereum' ? CryptoType.ETH : CryptoType.XTZ;
    on<GetBalanceEvent>((event, emit) async {
      final newState = state.clone()..wallet = event.wallet;

      final exchangeRate = await _currencyService.getExchangeRates();
      newState.exchangeRate = exchangeRate;

      switch (type) {
        case CryptoType.ETH:
          final ownerAddress =
              await event.wallet.getETHEip55Address(index: event.index);
          final balance = await _ethereumService.getBalance(ownerAddress);

          newState.balance = balance.getInWei;
          newState.isValid = _isValid(newState);
          break;
        case CryptoType.XTZ:
          final address =
              await event.wallet.getTezosAddress(index: event.index);
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

    on<QuantityUpdateEvent>((event, emit) async {
      log.info('[SendArtworkBloc] QuantityUpdateEvent: ${event.quantity}');
      final newState = state.clone()
        ..quantity = event.quantity
        ..isQuantityError =
            event.quantity <= 0 || event.quantity > event.maxQuantity
        ..isEstimating = false
        ..fee = null;
      newState.isValid = _isValid(newState);
      emit(newState);
      if (cachedAddress != null && !newState.isQuantityError) {
        add(AddressChangedEvent(cachedAddress!, event.index));
      }
    },
        transformer: (events, mapper) => events
            .debounceTime(const Duration(milliseconds: 300))
            .distinct()
            .switchMap(mapper));

    on<AddressChangedEvent>((event, emit) async {
      log.info('AddressChangedEvent: ${event.address}');
      final newState = state.clone()
        ..isScanQR = event.address.isEmpty
        ..isAddressError = false
        ..isEstimating = false
        ..fee = null;

      if (event.address.isNotEmpty) {
        switch (type) {
          case CryptoType.ETH:
            try {
              final address = EthereumAddress.fromHex(event.address);
              newState
                ..address = address.hexEip55
                ..isAddressError = false;

              add(EstimateFeeEvent(address.hexEip55, event.index,
                  _asset.contractAddress!, _asset.tokenId!, state.quantity));
            } catch (err) {
              newState.isAddressError = true;
            }
            break;
          case CryptoType.XTZ:
            if (event.address.isValidTezosAddress) {
              newState
                ..address = event.address
                ..isAddressError = false;

              add(EstimateFeeEvent(event.address, event.index,
                  _asset.contractAddress!, _asset.tokenId!, state.quantity));
            } else {
              newState.isAddressError = true;
            }
            break;
          default:
            break;
        }
      } else {
        newState
          ..isAddressError = true
          ..address = '';
      }
      newState.isValid = _isValid(newState);
      cachedAddress = newState.address;
      emit(newState);
    });

    on<EstimateFeeEvent>((event, emit) async {
      log.info('[SendArtworkBloc] Estimate fee: ${event.quantity}');
      emit(state.copyWith(isEstimating: true));

      BigInt? fee;
      FeeOptionValue? feeOptionValue;
      switch (type) {
        case CryptoType.ETH:
          final wallet = state.wallet;
          final index = event.index;
          if (wallet == null) {
            return;
          }

          final contractAddress =
              EthereumAddress.fromHex(event.contractAddress);
          final to = EthereumAddress.fromHex(event.address);
          final from = EthereumAddress.fromHex(
              await state.wallet!.getETHEip55Address(index: index));

          final data = _asset.contractType == 'erc1155'
              ? await _ethereumService.getERC1155TransferTransactionData(
                  contractAddress, from, to, event.tokenId, event.quantity,
                  feeOption: state.feeOption)
              : await _ethereumService.getERC721TransferTransactionData(
                  contractAddress, from, to, event.tokenId,
                  feeOption: state.feeOption);

          try {
            feeOptionValue = await _ethereumService.estimateFee(
                wallet, index, contractAddress, EtherAmount.zero(), data);
            fee = feeOptionValue.getFee(state.feeOption);
          } on RPCError catch (e) {
            _navigationService.showErrorDialog(
                ErrorEvent(e, 'estimation_failed'.tr(), e.errorMessage,
                    ErrorItemState.tryAgain), cancelAction: () {
              _navigationService.hideInfoDialog();
              return;
            }, defaultAction: () {
              add(event);
            });
          } catch (e) {
            _navigationService.showErrorDialog(
                ErrorEvent(e, 'estimation_failed'.tr(), e.toString(),
                    ErrorItemState.tryAgain), cancelAction: () {
              _navigationService.hideInfoDialog();
              return;
            }, defaultAction: () {
              add(event);
            });
          }
          break;
        case CryptoType.XTZ:
          final wallet = state.wallet;
          final index = event.index;
          if (wallet == null) {
            return;
          }
          try {
            final operation = await _tezosService.getFa2TransferOperation(
                event.contractAddress,
                await wallet.getTezosAddress(index: index),
                event.address,
                event.tokenId,
                event.quantity);
            final tezosFee = await _tezosService.estimateOperationFee(
                await wallet.getTezosPublicKey(index: index), [operation],
                baseOperationCustomFee:
                    state.feeOption.tezosBaseOperationCustomFee);
            fee = BigInt.from(tezosFee);
            feeOptionValue = FeeOptionValue(
                BigInt.from(tezosFee -
                    state.feeOption.tezosBaseOperationCustomFee +
                    baseOperationCustomFeeLow),
                BigInt.from(tezosFee -
                    state.feeOption.tezosBaseOperationCustomFee +
                    baseOperationCustomFeeMedium),
                BigInt.from(tezosFee -
                    state.feeOption.tezosBaseOperationCustomFee +
                    baseOperationCustomFeeHigh));
          } on TezartNodeError catch (err) {
            if (!emit.isDone) {
              unawaited(UIHelper.showInfoDialog(
                injector<NavigationService>().navigatorKey.currentContext!,
                'estimation_failed'.tr(),
                getTezosErrorMessage(err),
                isDismissible: true,
              ));
              fee = BigInt.zero;
              feeOptionValue =
                  FeeOptionValue(BigInt.zero, BigInt.zero, BigInt.zero);
            }
          } catch (err) {
            if (!emit.isDone) {
              unawaited(showErrorDialogFromException(err));
            }
            fee = BigInt.zero;
            feeOptionValue =
                FeeOptionValue(BigInt.zero, BigInt.zero, BigInt.zero);
          }
          break;
        default:
          fee = BigInt.zero;
          feeOptionValue =
              FeeOptionValue(BigInt.zero, BigInt.zero, BigInt.zero);
          break;
      }

      if (!emit.isDone) {
        final newState =
            event.newState == null ? state.clone() : event.newState!.clone()
              ..fee = fee
              ..feeOptionValue = feeOptionValue
              ..isEstimating = false;
        newState.isValid = _isValid(newState);
        emit(newState);
      }
    },
        transformer: (events, mapper) => events
            .debounceTime(const Duration(milliseconds: 300))
            .switchMap(mapper));

    on<FeeOptionChangedEvent>((event, emit) async {
      final newState = state.clone()..feeOption = event.feeOption;
      newState.fee = newState.feeOptionValue?.getFee(event.feeOption);
      emit(newState);
    });
  }

  bool _isValid(SendArtworkState state) {
    if (state.address == null) {
      return false;
    }
    if (state.balance == null) {
      return false;
    }
    if (state.fee == null) {
      return false;
    }
    if (state.isQuantityError) {
      return false;
    }

    return state.fee! <= state.balance! - _safeBuffer;
  }
}
