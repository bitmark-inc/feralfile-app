//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/address.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_state.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/domain_address_service.dart';
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
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/materialsset_token.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tezart/tezart.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';

class SendArtworkBloc extends AuBloc<SendArtworkEvent, SendArtworkState> {
  final EthereumService _ethereumService;
  final TezosService _tezosService;
  final CurrencyService _currencyService;
  final NavigationService _navigationService;
  final AssetToken _asset;
  final DomainAddressService _domainAddressService;
  String? cachedAddress;
  BigInt? cachedBalance;
  final _estimateLock = Lock();

  final _safeBuffer = BigInt.from(10);

  final _domainLock = Lock();

  SendArtworkBloc(
    this._ethereumService,
    this._tezosService,
    this._currencyService,
    this._navigationService,
    this._asset,
    this._domainAddressService,
  ) : super(SendArtworkState()) {
    final type =
        _asset.blockchain == 'ethereum' ? CryptoType.ETH : CryptoType.XTZ;
    on<GetBalanceEvent>((event, emit) async {
      await _estimateLock.synchronized(() async {
        final newState = state.clone()..wallet = event.wallet;

        final exchangeRate = await _currencyService.getExchangeRates();
        newState.exchangeRate = exchangeRate;

        switch (type) {
          case CryptoType.ETH:
            final ownerAddress =
                await event.wallet.getETHEip55Address(index: event.index);
            final balance =
                await _ethereumService.getBalance(ownerAddress!, doRetry: true);

            newState.balance = balance.getInWei;
            newState.isValid = _isValid(newState);
          case CryptoType.XTZ:
            final address =
                await event.wallet.getTezosAddress(index: event.index);
            final balance =
                await _tezosService.getBalance(address!, doRetry: true);

            newState.balance = BigInt.from(balance);
            newState.isValid = _isValid(newState);
          default:
            break;
        }

        cachedBalance = newState.balance;
        emit(newState);
      });
    });

    on<QuantityUpdateEvent>((event, emit) {
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
        final address = await _getAddressFromNS(event.address, type);
        if (address != null) {
          newState
            ..address = address.address
            ..domain = address.domain
            ..isAddressError = false;

          add(EstimateFeeEvent(address.address, event.index,
              _asset.contractAddress!, _asset.tokenId!, state.quantity));
        } else {
          newState.isAddressError = true;
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
      await _estimateLock.synchronized(() async {
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
                (await state.wallet!.getETHEip55Address(index: index))!);

            try {
              final data = _asset.contractType == 'erc1155'
                  ? await _ethereumService.getERC1155TransferTransactionData(
                      contractAddress, from, to, event.tokenId, event.quantity,
                      feeOption: state.feeOption)
                  : await _ethereumService.getERC721TransferTransactionData(
                      contractAddress, from, to, event.tokenId,
                      feeOption: state.feeOption);
              feeOptionValue = await _ethereumService.estimateFee(
                  wallet, index, contractAddress, EtherAmount.zero(), data);
              fee = feeOptionValue.getFee(state.feeOption);
            } on RPCError catch (e) {
              log.info('[SendArtworkBloc] RPCError: '
                  'errorCode: ${e.errorCode} '
                  'message: ${e.message}'
                  'data: ${e.data}');
              _navigationService.showErrorDialog(
                  ErrorEvent(e, 'estimation_failed'.tr(), e.errorMessage,
                      ErrorItemState.tryAgain), cancelAction: () {
                _navigationService.hideInfoDialog();
                return;
              }, defaultAction: () {
                add(event);
              });
            } catch (e) {
              log.info('[SendArtworkBloc] Error: $e');
              _navigationService.showErrorDialog(
                  ErrorEvent(e, 'estimation_failed'.tr(), e.toString(),
                      ErrorItemState.tryAgain), cancelAction: () {
                _navigationService.hideInfoDialog();
                return;
              }, defaultAction: () {
                add(event);
              });
            }
          case CryptoType.XTZ:
            final wallet = state.wallet;
            final index = event.index;
            if (wallet == null) {
              return;
            }
            try {
              final address = await wallet.getTezosAddress(index: index);
              final operation = await _tezosService.getFa2TransferOperation(
                  event.contractAddress,
                  address!,
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
                if (_navigationService.context.mounted) {
                  unawaited(UIHelper.showInfoDialog(
                    _navigationService.context,
                    'estimation_failed'.tr(),
                    getTezosErrorMessage(err),
                    isDismissible: true,
                  ));
                }
                fee = BigInt.zero;
                feeOptionValue =
                    FeeOptionValue(BigInt.zero, BigInt.zero, BigInt.zero);
              }
            } on TezartHttpError catch (err) {
              log.info(err);
              if (_navigationService.context.mounted) {
                unawaited(UIHelper.showInfoDialog(
                  _navigationService.context,
                  'estimation_failed'.tr(),
                  'cannot_connect_to_rpc'.tr(),
                  isDismissible: true,
                  closeButton: 'try_again'.tr(),
                  onClose: () {
                    add(event);
                    Navigator.of(_navigationService.context).pop();
                  },
                ));
              }
            } catch (err) {
              if (!emit.isDone) {
                unawaited(showErrorDialogFromException(err));
              }
              fee = BigInt.zero;
              feeOptionValue =
                  FeeOptionValue(BigInt.zero, BigInt.zero, BigInt.zero);
            }
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
      });
    },
        transformer: (events, mapper) => events
            .debounceTime(const Duration(milliseconds: 300))
            .switchMap(mapper));

    on<FeeOptionChangedEvent>((event, emit) {
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

  Future<Address?> _getAddressFromNS(String domain, CryptoType type) async =>
      await _domainLock.synchronized(() async => await _domainAddressService
          .verifyAddressOrDomainWithType(domain, type));
}
