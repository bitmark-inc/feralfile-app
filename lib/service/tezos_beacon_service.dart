import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/model/tezos_connection.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_sign_message_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';

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

  Future<String> getPostMessageConnectionURI() {
    return _beaconChannel.getPostMessageConnectionURI();
  }

  Future<List> handlePostMessageOpenChannel(String payload) {
    return _beaconChannel.handlePostMessageOpenChannel(payload);
  }

  Future<List> handlePostMessageMessage(
      String extensionPublicKey, String payload) {
    return _beaconChannel.handlePostMessageMessage(extensionPublicKey, payload);
  }

  Future addPeer(String link) async {
    final peer = await _beaconChannel.addPeer(link);
    _currentPeer = peer;
  }

  Future removePeer(P2PPeer peer) async {
    await _beaconChannel.removePeer(peer);
  }

  Future permissionResponse(
      String? uuid, String id, String? publicKey, String? address) async {
    await _beaconChannel.permissionResponse(id, publicKey, address);

    if (_currentPeer != null && uuid != null) {
      final peer = _currentPeer!;
      final bcConnection =
          BeaconConnectConnection(personaUuid: uuid, peer: peer);

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
      _navigationService.navigateTo(WCConnectPage.tag, arguments: request);
    } else if (request.type == "signPayload") {
      _navigationService.navigateTo(TBSignMessagePage.tag, arguments: request);
    } else if (request.type == "operation") {
      _navigationService.navigateTo(TBSendTransactionPage.tag,
          arguments: request);
    }
  }

  @override
  void onAbort() {
    log.info("TezosBeaconService: onAbort");
    UIHelper.hideInfoDialog(_navigationService.navigatorKey.currentContext!);
  }

  @override
  Future<void> onLinked(TezosConnection tezosConnection) async {
    log.info("TezosBeaconService: ${tezosConnection.toJson()}");

    final connection = Connection(
      key: tezosConnection.address,
      name: "",
      data: json.encode(tezosConnection),
      connectionType: ConnectionType.walletBeacon.rawValue,
      accountNumber: tezosConnection.address,
      createdAt: DateTime.now(),
    );

    await injector<CloudDatabase>().connectionDao.insertConnection(connection);

    injector<AWSService>().storeEventWithDeviceData(
      "link_tezos_beacon",
      hashingData: {"address": tezosConnection.address},
    );

    UIHelper.hideInfoDialog(_navigationService.navigatorKey.currentContext!);
    _navigationService.navigateTo(AppRouter.nameLinkedAccountPage,
        arguments: connection);
  }

  @override
  void onRequestedPermission(Peer peer) {
    log.info("TezosBeaconService: ${peer.toJson()}");
    UIHelper.showInfoDialog(
        _navigationService.navigatorKey.currentContext!,
        "Link requested",
        "Autonomy has sent a request to ${peer.name} to link to your account. Please open the wallet and authorize the request. ");
  }

  Future<Connection> onPostMessageLinked(
      String tzAddress, Peer peer, PermissionResponse response) async {
    final alreadyLinkedAccount = await getExistingAccount(tzAddress);
    if (alreadyLinkedAccount != null) {
      throw AlreadyLinkedException(alreadyLinkedAccount);
    }

    final tezosConnection = TezosConnection(
        address: tzAddress, peer: peer, permissionResponse: response);

    final connection = Connection(
      key: tzAddress,
      name: "",
      data: json.encode(tezosConnection),
      connectionType: ConnectionType.walletBeacon.rawValue,
      accountNumber: tzAddress,
      createdAt: DateTime.now(),
    );

    await _cloudDB.connectionDao.insertConnection(connection);
    return connection;
  }

  Future<Connection?> getExistingAccount(String accountNumber) async {
    final existingConnections = await _cloudDB.connectionDao
        .getConnectionsByAccountNumber(accountNumber);

    if (existingConnections.isEmpty) return null;
    return existingConnections.first;
  }
}
