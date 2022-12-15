import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AuBloc<Event, State> extends Bloc<Event, State> {
  AuBloc(State initialState) : super(initialState);

  @override
  void add(Event event) {
    if (isClosed) return;
    super.add(event);
  }
}
