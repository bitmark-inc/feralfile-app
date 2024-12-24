import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/address.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address_state.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/domain_address_service.dart';
import 'package:autonomy_flutter/util/exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:bloc/bloc.dart';
import 'package:synchronized/synchronized.dart';

class ViewExistingAddressBloc
    extends AuBloc<ViewExistingAddressEvent, ViewExistingAddressState> {
  final DomainAddressService _domainAddressService;
  final AddressService _addressService;
  int _operationId = 0; // Unique identifier for each operation

  final _checkDomainLock = Lock();

  ViewExistingAddressBloc(
    this._domainAddressService,
    this._addressService,
  ) : super(ViewExistingAddressState()) {
    on<AddressChangeEvent>(_onAddressChanged);

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

  Future<Address?> _checkDomain(String text) async {
    return _domainAddressService.verifyAddressOrDomain(text);
  }

  Future<void> _onAddressChanged(
    AddressChangeEvent event,
    Emitter<ViewExistingAddressState> emit,
  ) async {
    final address = event.address.trim();

    // Increment operation ID for each new operation
    final currentOperationId = ++_operationId;

    // Emit initial state for address processing
    emit(
      state.copyWith(
        isError: false,
        isValid: false,
        address: address,
      ),
    );

    // Early exit if address is empty
    if (address.isEmpty) {
      return;
    }

    // Wait for the operation to finish and emit the final state
    final domainInfo = await _checkDomain(address);

    // If this operation ID doesn't match the latest one, skip the result
    if (_operationId != currentOperationId) {
      return; // Ignore results from previous operations
    }
    log.info('Domain info for ${event.address}: $domainInfo');

    if (domainInfo != null) {
      emit(
        state.copyWith(
          address: domainInfo.address,
          domain: domainInfo.domain,
          isValid: true,
          type: domainInfo.type,
          isError: false,
        ),
      );
    } else {
      emit(
        state.copyWith(
          address: address,
          isValid: false,
          isError: true, // Invalid address
        ),
      );
    }
  }
}
