import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_connect_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_sign_message_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';

class TezosBeaconService implements BeaconHandler {
  final NavigationService _navigationService;
  final CloudDatabase _cloudDB;

  late TezosBeaconChannel _beaconChannel;
  P2PPeer? _currentPeer;

  TezosBeaconService(this._navigationService, this._cloudDB) {
    _beaconChannel = TezosBeaconChannel(handler: this);
    _beaconChannel.connect();
  }

  Future<String> getConnectionURI() {
    return _beaconChannel.getConnectionURI();
  }

  Future addPeer(String link) async {
    final peer = await _beaconChannel.addPeer(link);
    _currentPeer = peer;
  }

  Future permissionResponse(String? uuid, String id, String? publicKey) async {
    await _beaconChannel.permissionResponse(id, publicKey);

    if (_currentPeer != null && uuid != null) {
      final peer = _currentPeer!;
      final bcConnection = BeaconConnectConnection(
          personaUuid: uuid, peer: peer);

      final connection = Connection(
        key: peer.id,
        name: peer.name,
        data: json.encode(bcConnection),
        connectionType: ConnectionType.beaconP2PPeer.rawValue,
        accountNumber: "",
        createdAt: DateTime.now(),
      );
      _cloudDB.connectionDao.insertConnection(connection);
    }
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

  @override
  void onAbort() {
    // TODO: implement onAbort
  }

  @override
  void onLinked() {
    // TODO: implement onLinked
  }

  @override
  void onRequestedPermission() {
    // TODO: implement onRequestedPermission
  }

}