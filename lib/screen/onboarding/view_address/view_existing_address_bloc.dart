import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/domain_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:synchronized/synchronized.dart';
import 'package:web3dart/credentials.dart';

class ViewExistingAddressBloc
    extends AuBloc<ViewExistingAddressEvent, ViewExistingAddressState> {
  final DomainService _domainService;
  final AccountService _accountService;

  final _checkDomainLock = Lock();

  ViewExistingAddressBloc(
    this._domainService,
    this._accountService,
  ) : super(ViewExistingAddressState()) {
    on<AddressChangeEvent>((event, emit) async {
      emit(state.copyWith(
        isError: false,
      ));
      if (event.address.isEmpty) {
        emit(state.copyWith(
          address: event.address,
          isValid: false,
        ));
        return;
      }

      final type = CryptoType.fromAddress(event.address);
      switch (type) {
        case CryptoType.ETH:
          final checksumAddress =
              EthereumAddress.fromHex(event.address).hexEip55;
          emit(state.copyWith(
            address: checksumAddress,
            isValid: true,
            type: type,
          ));
          return;
        case CryptoType.XTZ:
          emit(state.copyWith(
            address: event.address,
            isValid: true,
            type: type,
          ));
          return;
        default:
          log.info('check domain for ${event.address}');
          final pair = await _checkDomain(event.address);
          log.info(
              'pair: ${pair?.first}, ${pair?.second}, domain: ${event.address}');
          if (pair != null) {
            emit(state.copyWith(
              address: pair.first,
              domain: event.address,
              isValid: true,
              type: pair.second,
            ));
          } else {
            emit(state.copyWith(
              address: event.address,
              isValid: false,
            ));
          }
      }
    });

    on<AddConnectionEvent>((event, emit) async {
      if (!isValid) {
        emit(state.copyWith(
          isError: true,
        ));
        return;
      }
      emit(state.copyWith(
        isAddConnectionLoading: true,
      ));

      try {
        final connection = await _accountService.linkManuallyAddress(
            state.address, state.type!,
            name: state.domain);
        emit(ViewExistingAddressSuccessState(state, connection));
      } on LinkAddressException catch (e) {
        emit(state.copyWith(
          isError: true,
          exception: e,
        ));
      } catch (e) {
        emit(
          state.copyWith(isError: true),
        );
      }
      emit(state.copyWith(
        isAddConnectionLoading: false,
      ));
    });
  }

  bool get isValid =>
      state.isValid && state.address.isNotEmpty && state.type != null;

  Future<Pair<String, CryptoType>?> _checkDomain(String text) async =>
      await _checkDomainLock.synchronized(() async {
        if (text.isNotEmpty) {
          try {
            final ethAddress = await _domainService.getEthAddress(text);
            if (ethAddress != null) {
              final checksumAddress =
                  EthereumAddress.fromHex(ethAddress).hexEip55;
              return Pair(checksumAddress, CryptoType.ETH);
            }

            final xtzAddress = await _domainService.getTezosAddress(text);
            if (xtzAddress != null) {
              return Pair(xtzAddress, CryptoType.XTZ);
            }
          } catch (_) {
            return null;
          }
        }
        return null;
      });
}
