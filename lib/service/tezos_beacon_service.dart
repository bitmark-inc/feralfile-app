import 'dart:async';

import 'package:autonomy_flutter/screen/tezos_beacon/tb_connect_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_sign_message_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';

class TezosBeaconService implements BeaconHandler {
  final NavigationService _navigationService;
  final ConfigurationService _configurationService;

  late TezosBeaconChannel _beaconChannel;

  TezosBeaconService(this._navigationService, this._configurationService) {
    _beaconChannel = TezosBeaconChannel(handler: this);
    _beaconChannel.connect();
  }

  Future addPeer(String link) async {
    final peer = await _beaconChannel.addPeer(link);
    //TODO: save peer
  }

  Future permissionResponse(String id, String? publicKey) {
    return _beaconChannel.permissionResponse(id, publicKey);
  }

  Future signResponse(String id, String? signature) {
    return _beaconChannel.signResponse(id, signature);
  }

  Future operationResponse(String id, String? txHash) {
    return _beaconChannel.operationResponse(id, txHash);
  }

  @override
  void onRequest(BeaconRequest request) {
    if (request.type == "permission") {
      _navigationService.navigateTo(TBConnectPage.tag, arguments: request);
    } else if (request.type == "signPayload") {
      _navigationService.navigateTo(TBSignMessagePage.tag, arguments: request);
    } else if (request.type == "operation") {
      _navigationService.navigateTo(TBSendTransactionPage.tag, arguments: request);
    }
  }
}