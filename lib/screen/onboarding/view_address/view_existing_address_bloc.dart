import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/address.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/domain_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:synchronized/synchronized.dart';
import 'package:web3dart/credentials.dart';

class ViewExistingAddressBloc
    extends AuBloc<ViewExistingAddressEvent, ViewExistingAddressState> {
  final DomainAddressService _domainService;
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

      final address = await _checkDomain(event.address);

      if (address != null) {
        emit(state.copyWith(
          address: address.address,
          domain: address.domain,
          isValid: true,
          type: address.type,
        ));
      } else {
        emit(state.copyWith(
          address: event.address,
          isValid: false,
        ));
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

  Future<Address?> _checkDomain(String text) async =>
      await _checkDomainLock.synchronized(
          () async => await _domainService.verifyAddressOrDomain(text));
}
