import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:libauk_dart/libauk_dart.dart';

class ScanWalletBloc extends AuBloc<ScanWalletEvent, ScanWalletState> {
  final EthereumService _ethereumService;
  final TezosService _tezosService;

  ScanWalletBloc(this._ethereumService, this._tezosService)
      : super(ScanWalletState(addresses: [])) {
    on<ScanEthereumWalletEvent>(
      (event, emit) async {
        emit(state.addNewAddresses([], isScanning: true));
        List<EthereumAddressInfo> ethereumAddresses = [];
        int gapCount = 0;
        int index = event.startIndex;
        final wallet = event.wallet;
        bool hitStopGap = false;
        final addressIndexes =
            List.generate(event.maxLength, (index) => index + event.startIndex);
        final addresses =
            await wallet.getETHEip55Addresses(indexes: addressIndexes);
        for (final entry in addresses.entries) {
          final address = entry.value;
          final index = entry.key;
          final balance = await _ethereumService.getBalance(address);
          final hasBalance = balance.getInWei.compareTo(BigInt.zero) > 0;
          if (hasBalance || event.showEmptyAddresses) {
            ethereumAddresses.add(EthereumAddressInfo(index, address, balance));
          }
        }

        if (event.isAdd) {
          emit(state.addNewAddresses(ethereumAddresses,
              hitStopGap: hitStopGap, isScanning: false));
        } else {
          emit(ScanWalletState(
              addresses: ethereumAddresses, hitStopGap: hitStopGap));
        }
        log.info(
            "ScanEthereumWalletEvent: addresses: $ethereumAddresses hitStopGap: $hitStopGap");
      },
    );

    on<ScanTezosWalletEvent>(
      (event, emit) async {
        emit(state.addNewAddresses([], isScanning: true));
        List<TezosAddressInfo> tezosAddresses = [];
        int gapCount = 0;
        int index = event.startIndex;
        final wallet = event.wallet;
        bool hitStopGap = false;
        while (!hitStopGap && tezosAddresses.length < event.maxLength) {
          final address = await wallet.getTezosAddress(index: index);
          final balance = await _tezosService.getBalance(address!);
          final hasBalance = balance > 0;

          if (hasBalance) {
            gapCount = 0;
          } else {
            gapCount++;
          }
          if (hasBalance || event.showEmptyAddresses) {
            tezosAddresses.add(TezosAddressInfo(index, address, balance));
          }

          hitStopGap = gapCount >= event.gapLimit;
          index++;
        }

        if (event.isAdd) {
          emit(state.addNewAddresses(tezosAddresses,
              hitStopGap: hitStopGap, isScanning: false));
        } else {
          emit(ScanWalletState(
              addresses: tezosAddresses, hitStopGap: hitStopGap));
        }

        log.info(
            "ScanTezosWalletEvent: addresses: $tezosAddresses hitStopGap: $hitStopGap");
      },
    );
  }
}
