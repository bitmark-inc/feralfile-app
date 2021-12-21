import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, int> {
  HomeBloc() : super(0) {
    on((event, emit) {
      if (event is HomeEvent1) {
        emit(state + 1);
      }
    });
  }
}

abstract class HomeEvent {}

class HomeEvent1 extends HomeEvent {}