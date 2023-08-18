//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import "package:collection/collection.dart";

part 'connections_state.dart';

class ConnectionsBloc extends AuBloc<ConnectionsEvent, ConnectionsState> {
  final CloudDatabase _cloudDB;
  final Wc2Service _wc2Service;
  final TezosBeaconService _tezosBeaconService;
  final MetricClientService _metricClientService;

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
    this._metricClientService,
  ) : super(ConnectionsState()) {
    on<GetETHConnectionsEvent>((event, emit) async {
      emit(state.resetConnectionItems());
      // PersonaConnectionsPage is showing combined connections based on app
      final connectionItems = await _getWc2Connections(
          event.address, ConnectionType.walletConnect2);
      final wc2Connections =
          await _getWc2Connections(event.address, ConnectionType.dappConnect2);
      connectionItems.addAll(wc2Connections);

      emit(state.copyWith(connectionItems: connectionItems));
    });

    on<GetXTZConnectionsEvent>((event, emit) async {
      emit(state.resetConnectionItems());
      final personaUUID = event.personUUID;

      final connections = await _cloudDB.connectionDao
          .getConnectionsByType(ConnectionType.beaconP2PPeer.rawValue);

      List<Connection> personaConnections = [];
      for (var connection in connections) {
        if (connection.beaconConnectConnection?.personaUuid == personaUUID &&
            connection.beaconConnectConnection?.index == event.index) {
          personaConnections.add(connection);
        }
      }

      // PersonaConnectionsPage is showing combined connections based on app
      final resultGroup =
          groupBy(personaConnections, (Connection conn) => conn.appName);
      final connectionItems = resultGroup.values
          .map((conns) =>
              ConnectionItem(representative: conns.first, connections: conns))
          .toList();

      final auConnections = await _getWc2Connections(
          event.address, ConnectionType.walletConnect2);
      connectionItems.addAll(auConnections);
      final wc2Connections =
          await _getWc2Connections(event.address, ConnectionType.dappConnect2);
      connectionItems.addAll(wc2Connections);

      emit(state.copyWith(connectionItems: connectionItems));
    });

    on<DeleteConnectionsEvent>((event, emit) async {
      Set<P2PPeer> bcPeers = {};

      for (var connection in event.connectionItem.connections) {
        _cloudDB.connectionDao.deleteConnection(connection);
        _metricClientService.onRemoveConnection(connection);
        if ([
          ConnectionType.walletConnect2.rawValue,
          ConnectionType.dappConnect2.rawValue
        ].contains(connection.connectionType)) {
          final topic = connection.key.split(":").lastOrNull;
          if (topic != null) {
            await _wc2Service.deletePairing(topic: topic);
          }
        }

        final bcPeer = connection.beaconConnectConnection?.peer;
        if (bcPeer != null) bcPeers.add(bcPeer);
      }

      for (var peer in bcPeers) {
        _tezosBeaconService.removePeer(peer);
      }

      state.connectionItems?.remove(event.connectionItem);
      emit(state.copyWith(connectionItems: state.connectionItems));
    });
  }
}
