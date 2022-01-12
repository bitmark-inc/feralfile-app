import 'dart:math';

import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_state.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web3dart/web3dart.dart';

class SendCryptoBloc extends Bloc<SendCryptoEvent, SendCryptoState> {
  EthereumService _ethereumService;
  TezosService _tezosService;
  CurrencyService _currencyService;
  CryptoType _type;

  SendCryptoBloc(
    this._ethereumService,
    this._tezosService,
    this._currencyService,
    this._type,
  ) : super(SendCryptoState()) {
    on<GetBalanceEvent>((event, emit) async {
      final newState = state.clone();

      final exchangeRate = await _currencyService.getExchangeRates();
      newState.exchangeRate = exchangeRate;

      switch (_type) {

        case CryptoType.ETH:
          final address = await _ethereumService.getETHAddress();
          final balance = await _ethereumService.getBalance(address);

          newState.balance = balance.getInWei;

          if (state.fee != null) {
            final maxAllow = balance.getInWei - state.fee!;
            newState.maxAllow = maxAllow;
            newState.isValid = _isValid(newState);
          }
          break;
        case CryptoType.XTZ:
          final address = await _tezosService.getTezosAddress();
          final balance = await _tezosService.getBalance(address);

          newState.balance = BigInt.from(balance);
          if (state.fee != null) {
            final maxAllow = newState.balance! - state.fee!;
            newState.maxAllow = maxAllow;
            newState.isValid = _isValid(newState);
          }

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
        }
      }

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
          }
        }

        print(value);

        final amount = BigInt.from(value * pow(10, _type == CryptoType.ETH ? 18 : 6));

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

      emit(newState);
    });

    on<CurrencyTypeChangedEvent>((event, emit) async {
      final newState = state.clone();

      newState.isCrypto = event.isCrypto;
      emit(newState);
    });

    on<EstimateFeeEvent>((event, emit) async {
      final newState = state.clone();

      final BigInt fee;

      switch (_type) {
        case CryptoType.ETH:
          final address = EthereumAddress.fromHex(event.address);
          fee = await _ethereumService.estimateFee(
              address, EtherAmount.inWei(event.amount));
          break;
        case CryptoType.XTZ:
          final tezosFee = await _tezosService.estimateFee(event.address, event.amount.toInt());
          fee = BigInt.from(tezosFee);
          break;
      }

      newState.fee = fee;

      if (state.balance != null) {
        final maxAllow = state.balance! - fee;
        newState.maxAllow = maxAllow;
        newState.isValid = _isValid(newState);
      }

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
