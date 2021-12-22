abstract class HomeEvent {}

class HomeConnectWCEvent extends HomeEvent {
  final String uri;

  HomeConnectWCEvent(this.uri);
}