//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:math';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/address.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_state.dart';
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
import 'package:synchronized/synchronized.dart';
import 'package:tezart/tezart.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';

class SendCryptoBloc extends AuBloc<SendCryptoEvent, SendCryptoState> {
  final EthereumService _ethereumService;
  final TezosService _tezosService;
  final CurrencyService _currencyService;
  final CryptoType _type;
  final NavigationService _navigationService;
  final DomainAddressService _domainAddressService;
  String? cachedAddress;
  BigInt? cachedAmount;
  final _estimateLock = Lock();

  final _xtzSafeBuffer = BigInt.from(10);
  final _ethSafeBuffer = BigInt.from(100);

  final _domainLock = Lock();

  SendCryptoBloc(
    this._ethereumService,
    this._tezosService,
    this._currencyService,
    this._type,
    this._navigationService,
    this._domainAddressService,
  ) : super(SendCryptoState()) {
    on<GetBalanceEvent>((event, emit) async {
      await _estimateLock.synchronized(() async {
        final newState = state.clone()
          ..wallet = event.wallet
          ..index = event.index;

        final exchangeRate = await _currencyService.getExchangeRates();
        newState.exchangeRate = exchangeRate;

        switch (_type) {
          case CryptoType.ETH:
            final ownerAddress =
                await event.wallet.getETHEip55Address(index: event.index);
            final balance =
                await _ethereumService.getBalance(ownerAddress, doRetry: true);

            newState.balance = balance.getInWei;

            if (state.feeOptionValue != null) {
              final maxAllow = balance.getInWei -
                  state.feeOptionValue!.high -
                  _ethSafeBuffer;
              newState
                ..maxAllow = maxAllow
                ..isValid = _isValid(newState);
            }
          case CryptoType.XTZ:
            final address =
                await event.wallet.getTezosAddress(index: event.index);
            final balance =
                await _tezosService.getBalance(address, doRetry: true);

            newState.balance = BigInt.from(balance);
            if (state.feeOptionValue != null) {
              final maxAllow = newState.balance! -
                  state.feeOptionValue!.high -
                  _xtzSafeBuffer;
              newState
                ..maxAllow = maxAllow
                ..isValid = _isValid(newState);
            }
          case CryptoType.USDC:
            final address =
                await event.wallet.getETHEip55Address(index: event.index);
            final ownerAddress = EthereumAddress.fromHex(address);
            final contractAddress =
                EthereumAddress.fromHex(usdcContractAddress);

            final balance = await _ethereumService.getERC20TokenBalance(
                contractAddress, ownerAddress);
            final ethBalance =
                await _ethereumService.getBalance(address, doRetry: true);

            newState.balance = balance;
            newState.ethBalance = ethBalance.getInWei;

            if (state.feeOptionValue != null) {
              final maxAllow = balance;
              newState
                ..maxAllow = maxAllow
                ..isValid = _isValid(newState);
            }
          default:
            break;
        }

        emit(newState);
      });
    });

    on<AddressChangedEvent>((event, emit) async {
      final newState = state.clone()
        ..isScanQR = event.address.isEmpty
        ..isAddressError = false;

      if (event.address.isNotEmpty) {
        final address = await _getAddressFromNS(event.address, _type);
        if (address != null) {
          newState
            ..address = address.address
            ..domain = address.domain
            ..isAddressError = false;
          add(EstimateFeeEvent(address.address,
              _type == CryptoType.XTZ ? BigInt.one : BigInt.zero));
        } else {
          newState.isAddressError = true;
        }
      }

      cachedAddress = newState.address;
      newState.isValid = _isValid(newState);
      emit(newState);
    });

    on<AmountChangedEvent>((event, emit) {
      final newState = state.clone();

      if (event.amount.isNotEmpty) {
        double value = double.tryParse(event.amount) ?? 0;
        if (!state.isCrypto) {
          switch (_type) {
            case CryptoType.ETH:
              value *= double.parse(state.exchangeRate.eth);
            case CryptoType.XTZ:
              value *= double.parse(state.exchangeRate.xtz);
            default:
              break;
          }
        }

        final amount =
            BigInt.from(value * pow(10, _type == CryptoType.ETH ? 18 : 6));

        newState
          ..amount = amount
          ..isValid = _isValid(newState)
          ..isAmountError = !newState.isValid &&
              state.address != null &&
              state.maxAllow != null;
      } else {
        newState
          ..amount = null
          ..isValid = false
          ..isAmountError = false;
      }

      cachedAmount = newState.amount;
      emit(newState);
    });

    on<CurrencyTypeChangedEvent>((event, emit) {
      final newState = state.clone()..isCrypto = event.isCrypto;
      emit(newState);
    });

    on<EstimateFeeEvent>((event, emit) async {
      await _estimateLock.synchronized(() async {
        log.info('EstimateFeeEvent: ${event.address}, ${event.amount}');
        final newState = state.clone();

        BigInt fee = BigInt.zero;
        FeeOptionValue feeOptionValue = FeeOptionValue(fee, fee, fee);

        switch (_type) {
          case CryptoType.ETH:
            final address = EthereumAddress.fromHex(event.address);
            final wallet = state.wallet;
            final index = state.index;
            if (wallet == null || index == null) {
              return;
            }
            feeOptionValue = await _ethereumService.estimateFee(
                wallet, index, address, EtherAmount.inWei(event.amount), null);
            fee = feeOptionValue.getFee(state.feeOption);
          case CryptoType.XTZ:
            final wallet = state.wallet;
            final index = state.index;
            if (wallet == null || index == null) {
              return;
            }
            try {
              final tezosFee = await _tezosService.estimateFee(
                  await wallet.getTezosPublicKey(index: index),
                  event.address,
                  event.amount.toInt(),
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
              unawaited(UIHelper.showInfoDialog(
                injector<NavigationService>().navigatorKey.currentContext!,
                'estimation_failed'.tr(),
                getTezosErrorMessage(err),
                isDismissible: true,
              ));
              fee = BigInt.zero;
              feeOptionValue =
                  FeeOptionValue(BigInt.zero, BigInt.zero, BigInt.zero);
            } catch (err) {
              unawaited(showErrorDialogFromException(err));
              fee = BigInt.zero;
              feeOptionValue =
                  FeeOptionValue(BigInt.zero, BigInt.zero, BigInt.zero);
            }
          case CryptoType.USDC:
            final wallet = state.wallet;
            final index = state.index;
            if (wallet == null || index == null) {
              return;
            }

            final address = await wallet.getETHEip55Address(index: index);
            final ownerAddress = EthereumAddress.fromHex(address);
            final toAddress = EthereumAddress.fromHex(event.address);
            final contractAddress =
                EthereumAddress.fromHex(usdcContractAddress);

            final data = await _ethereumService.getERC20TransferTransactionData(
                contractAddress, ownerAddress, toAddress, event.amount);
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
          default:
            fee = BigInt.zero;
            feeOptionValue =
                FeeOptionValue(BigInt.zero, BigInt.zero, BigInt.zero);
        }

        newState
          ..fee = fee
          ..feeOptionValue = feeOptionValue;

        if (state.balance != null) {
          var maxAllow = _type != CryptoType.USDC
              ? state.balance! -
                  fee -
                  (_type == CryptoType.ETH ? _ethSafeBuffer : _xtzSafeBuffer)
              : state.balance!;
          if (maxAllow < BigInt.zero) {
            maxAllow = BigInt.zero;
          }
          newState
            ..maxAllow = maxAllow
            ..address = cachedAddress
            ..amount = cachedAmount
            ..isValid = _isValid(newState);
        }

        log.info('EstimateFeeEvent: done');
        emit(newState);
      });
    });

    on<FeeOptionChangedEvent>((event, emit) {
      final newState = state.clone()..feeOption = event.feeOption;
      if (state.balance != null &&
          state.fee != null &&
          state.feeOptionValue != null) {
        var maxAllow = _type != CryptoType.USDC
            ? state.balance! -
                state.feeOptionValue!.getFee(event.feeOption) -
                (_type == CryptoType.ETH ? _ethSafeBuffer : _xtzSafeBuffer)
            : state.balance!;
        if (maxAllow < BigInt.zero) {
          maxAllow = BigInt.zero;
        }
        newState
          ..maxAllow = maxAllow
          ..isValid = _isValid(newState)
          ..isAmountError = !newState.isValid && newState.address != null;
      }
      newState.fee = newState.feeOptionValue?.getFee(event.feeOption);
      emit(newState);
    });
  }

  bool _isValid(SendCryptoState state) {
    if (state.amount == null) {
      return false;
    }
    if (state.address == null) {
      return false;
    }
    if (state.maxAllow == null) {
      return false;
    }

    final amount = state.amount!;

    return amount > BigInt.zero && amount <= state.maxAllow!;
  }

  Future<Address?> _getAddressFromNS(String domain, CryptoType type) async =>
      await _domainLock.synchronized(() async => await _domainAddressService
          .verifyAddressOrDomainWithType(domain, type));
}
