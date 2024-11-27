import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/address.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address_state.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/domain_address_service.dart';
import 'package:autonomy_flutter/util/exception.dart';
import 'package:synchronized/synchronized.dart';

class ViewExistingAddressBloc
    extends AuBloc<ViewExistingAddressEvent, ViewExistingAddressState> {
  final DomainAddressService _domainAddressService;
  final AddressService _addressService;

  final _checkDomainLock = Lock();

  ViewExistingAddressBloc(
    this._domainAddressService,
    this._addressService,
  ) : super(ViewExistingAddressState()) {
    on<AddressChangeEvent>((event, emit) async {
      emit(
        state.copyWith(
          isError: false,
        ),
      );
      if (event.address.isEmpty) {
        emit(
          state.copyWith(
            address: event.address,
            isValid: false,
          ),
        );
        return;
      }

      final address = await _checkDomain(event.address);

      if (address != null) {
        emit(
          state.copyWith(
            address: address.address,
            domain: address.domain,
            isValid: true,
            type: address.type,
          ),
        );
      } else {
        emit(
          state.copyWith(
            address: event.address,
            isValid: false,
          ),
        );
      }
    });

    on<AddConnectionEvent>((event, emit) async {
      if (!isValid) {
        emit(
          state.copyWith(
            isError: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isAddConnectionLoading: true,
        ),
      );

      try {
        final walletAddress = WalletAddress(
          address: state.address,
          name: state.domain,
          createdAt: DateTime.now(),
        );
        final connection = await _addressService.insertAddress(
          walletAddress,
        );
        emit(ViewExistingAddressSuccessState(state, connection));
      } on LinkAddressException catch (e) {
        emit(
          state.copyWith(
            isError: true,
            exception: e,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(isError: true),
        );
      }
      emit(
        state.copyWith(
          isAddConnectionLoading: false,
        ),
      );
    });
  }

  bool get isValid =>
      state.isValid && state.address.isNotEmpty && state.type != null;

  Future<Address?> _checkDomain(String text) async =>
      await _checkDomainLock.synchronized(
        () async => await _domainAddressService.verifyAddressOrDomain(text),
      );
}
