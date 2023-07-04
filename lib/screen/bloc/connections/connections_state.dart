//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

part of 'connections_bloc.dart';

abstract class ConnectionsEvent {}

// Refresh when gotoPage (PersonaConnectionsPage)
class GetETHConnectionsEvent extends ConnectionsEvent {
  final String personUUID;
  final int index;
  final String address;

  GetETHConnectionsEvent(this.personUUID, this.index, this.address);
}

class GetXTZConnectionsEvent extends ConnectionsEvent {
  final String personUUID;
  final int index;
  final String address;

  GetXTZConnectionsEvent(this.personUUID, this.index, this.address);
}

class DeleteConnectionsEvent extends ConnectionsEvent {
  final ConnectionItem connectionItem;

  DeleteConnectionsEvent(this.connectionItem);
}

class ConnectionItem {
  final Connection representative;
  final List<Connection> connections;

  ConnectionItem({
    required this.representative,
    required this.connections,
  });
}

class ConnectionsState {
  List<ConnectionItem>? connectionItems;

  ConnectionsState({
    this.connectionItems,
  });

  ConnectionsState copyWith({
    List<ConnectionItem>? connectionItems,
  }) {
    return ConnectionsState(
      connectionItems: connectionItems ?? this.connectionItems,
    );
  }

  ConnectionsState resetConnectionItems() {
    return ConnectionsState();
  }
}
