//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:collection/collection.dart';

part 'connections_state.dart';

class ConnectionsBloc extends AuBloc<ConnectionsEvent, ConnectionsState> {
  final CloudDatabase _cloudDB;
  final Wc2Service _wc2Service;
  final TezosBeaconService _tezosBeaconService;

  Future<List<ConnectionItem>> _getWc2Connections(
      String address, ConnectionType type) async {
    final connections =
        await _cloudDB.connectionDao.getConnectionsByType(type.rawValue);
    List<Connection> personaConnections = [];
    for (var connection in connections) {
      if (connection.accountNumber.contains(address)) {
        personaConnections.add(connection);
      }
    }

    // PersonaConnectionsPage is showing combined connections based on appName
    final resultGroup =
        groupBy(personaConnections, (Connection conn) => conn.appName);
    final connectionItems = resultGroup.values
        .map((conns) =>
            ConnectionItem(representative: conns.first, connections: conns))
        .toList();
    return connectionItems;
  }

  Future<List<ConnectionItem>> _getBeaconConnections(
      String personaUUID, int index) async {
    final connections = await _cloudDB.connectionDao
        .getConnectionsByType(ConnectionType.beaconP2PPeer.rawValue);

    List<Connection> personaConnections = [];
    for (var connection in connections) {
      if (connection.beaconConnectConnection?.personaUuid == personaUUID &&
          connection.beaconConnectConnection?.index == index) {
        personaConnections.add(connection);
      }
    }

    // PersonaConnectionsPage is showing combined connections based on appName
    final resultGroup =
        groupBy(personaConnections, (Connection conn) => conn.appName);
    final connectionItems = resultGroup.values
        .map((conns) =>
            ConnectionItem(representative: conns.first, connections: conns))
        .toList();

    return connectionItems;
  }

  ConnectionsBloc(
    this._cloudDB,
    this._wc2Service,
    this._tezosBeaconService,
  ) : super(ConnectionsState()) {
    on<GetETHConnectionsEvent>((event, emit) async {
      emit(state.resetConnectionItems());

      final auConnections = await _getWc2Connections(
          event.address, ConnectionType.walletConnect2);
      final wc2Connections =
          await _getWc2Connections(event.address, ConnectionType.dappConnect2);

      final connectionItems = [...auConnections, ...wc2Connections];
      emit(state.copyWith(connectionItems: connectionItems));
    });

    on<GetXTZConnectionsEvent>((event, emit) async {
      emit(state.resetConnectionItems());

      final auConnections = await _getWc2Connections(
          event.address, ConnectionType.walletConnect2);
      final beaconConnections =
          await _getBeaconConnections(event.personUUID, event.index);

      final connectionItems = [...auConnections, ...beaconConnections];

      emit(state.copyWith(connectionItems: connectionItems));
    });

    on<DeleteConnectionsEvent>((event, emit) async {
      Set<P2PPeer> bcPeers = {};

      for (var connection in event.connectionItem.connections) {
        if ([
          ConnectionType.walletConnect2.rawValue,
          ConnectionType.dappConnect2.rawValue
        ].contains(connection.connectionType)) {
          final topic = connection.key.split(':').lastOrNull;
          if (topic != null) {
            await _wc2Service.deletePairing(topic: topic);
          }
        }

        if (connection.connectionType ==
            ConnectionType.beaconP2PPeer.rawValue) {
          unawaited(_cloudDB.connectionDao.deleteConnection(connection));

          final bcPeer = connection.beaconConnectConnection?.peer;
          if (bcPeer != null) {
            bcPeers.add(bcPeer);
          }
        }
      }

      if (event.connectionItem.representative.connectionType ==
          ConnectionType.beaconP2PPeer.rawValue) {
        for (var peer in bcPeers) {
          unawaited(_tezosBeaconService.removePeer(peer));
        }
        state.connectionItems?.remove(event.connectionItem);
        emit(state.copyWith(connectionItems: state.connectionItems));
      }
    });

    on<SessionDeletedEvent>((event, emit) async {
      unawaited(
          _cloudDB.connectionDao.deleteConnectionsByTopic('%${event.topic}%'));

      if (state.connectionItems == null || state.connectionItems!.isEmpty) {
        return;
      }

      for (var item in state.connectionItems!) {
        item.connections
            .removeWhere((connection) => connection.key.contains(event.topic));
      }

      state.connectionItems?.removeWhere((item) => item.connections.isEmpty);

      emit(state.copyWith(connectionItems: state.connectionItems));
    });

    _wc2Service.sessionDeleteNotifier.addListener(_onSessionDeletedFunc);
  }

  Future<void> _onSessionDeletedFunc() async {
    final topic = _wc2Service.sessionDeleteNotifier.value;
    if (topic == null) {
      return;
    }

    add(SessionDeletedEvent(topic));
  }

  @override
  Future<void> close() {
    _wc2Service.sessionDeleteNotifier.removeListener(_onSessionDeletedFunc);
    return super.close();
  }
}
