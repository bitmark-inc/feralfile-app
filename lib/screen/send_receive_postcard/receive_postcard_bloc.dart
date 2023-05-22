import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReceivePostcardBloc
    extends Bloc<ReceivePostcardEvent, ReceivePostcardState> {
  ReceivePostcardBloc() : super(ReceivePostcardState()) {
    on<AcceptPostcardEvent>((event, emit) async {
      emit(state.copyWith(isReceiving: true));
    });

    on<GetPostcardEvent>((event, emit) async {});

    on<GetLocationEvent>((event, emit) async {});
  }
}
