import 'package:flutter_bloc/flutter_bloc.dart';

class WCSendTransactionBloc extends Bloc<WCSendTransactionEvent, int> {
  WCSendTransactionBloc() : super(0) {
    on((event, emit) {
      if (event is EstimateFeeEvent) {
        emit(state + 1);
      }
    });
  }
}

abstract class WCSendTransactionEvent {}

class EstimateFeeEvent extends WCSendTransactionEvent {}