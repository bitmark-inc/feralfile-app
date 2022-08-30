import 'package:autonomy_flutter/model/tzkt_operation.dart';

class TZKTTransactionState {
  //List<TZKTTokenTransfer>? tokenItems;
  List<TZKTTransactionIF> newItems;
  //List<TZKTOperation>? operationItem;
  bool? isLastPage;
  TZKTTransactionState({required this.newItems, this.isLastPage});
}

abstract class TZKTTransactionEvent {}

class GetPageNewItems extends TZKTTransactionEvent {
  int pageSize;
  int pageKey;
  String address;
  String initiator;

  GetPageNewItems({required this.address, required this.initiator, required this.pageSize, required this.pageKey});
}
