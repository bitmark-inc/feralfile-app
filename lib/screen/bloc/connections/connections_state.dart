part of 'connections_bloc.dart';

abstract class ConnectionsEvent {}

// Refresh when gotoPage (PersonaConnectionsPage)
class GetETHConnectionsEvent extends ConnectionsEvent {
  final String personUUID;

  GetETHConnectionsEvent(this.personUUID);
}

class GetXTZConnectionsEvent extends ConnectionsEvent {
  final String personUUID;

  GetXTZConnectionsEvent(this.personUUID);
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
    return ConnectionsState(
      connectionItems: null,
    );
  }
}
