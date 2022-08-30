import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/tzkt_api.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/bloc/tzkt_transaction/tzkt_transaction_state.dart';

class TZKTTransactionBloc
    extends AuBloc<TZKTTransactionEvent, TZKTTransactionState> {
  List<TZKTTokenTransfer>? tokenItems;
  List<TZKTTokenTransfer>? newTokenItems;

  TZKTTransactionBloc() : super(TZKTTransactionState(newItems: [])) {
    on<GetPageNewItems>((event, emit) async {
      final newOperationItems = await injector<TZKTApi>().getOperations(
        event.address,
        type: "transaction,origination,reveal",
        limit: event.pageSize,
        lastId: event.pageKey > 0 ? event.pageKey : null,
        initiator: event.initiator,
      );
      tokenItems ??= await injector<TZKTApi>().getTokenTransfer(
        anyOf: event.address,
      );
      newTokenItems ??= tokenItems;
      DateTime lastOperationDatetime = newOperationItems.last.timestamp;
      List<TZKTTokenTransfer>? addTokenItems =
          _getTokenAfter(newTokenItems, lastOperationDatetime);
      newTokenItems = _getTokenBefore(newTokenItems, lastOperationDatetime);
      final newItems = mergeOperation(addTokenItems, newOperationItems);

      bool isLastPage = newOperationItems.length < event.pageSize;
      emit(TZKTTransactionState(newItems: newItems, isLastPage: isLastPage));
    });
  }

  List<TZKTTransactionInterface> mergeOperation(
      List<TZKTTokenTransfer>? tokens, List<TZKTOperation> operation) {
    List<TZKTOperation> tx = operation;
    int tokenIndex = 0;
    for (int i = 0; i < tx.length; i++) {
      if (tokens?.isEmpty == true) return tx;
      int tokenNo = findTokenByTxId(tokenIndex, tx[i].getID(), tokens!);
      if (tokenNo > -1) {
        tx[i].tokenTransfer = tokens[tokenNo];
        tokenIndex = tokenNo;
        tokens.removeAt(tokenNo);
      } else {
        tokenIndex = tokenNo + 1;
      }
    }
    List<TZKTTransactionInterface> tx_ = List<TZKTTransactionInterface>.from(tx)..addAll(tokens!);
    tx_.sort((a, b) => b.getID().compareTo(a.getID()));
    return tx_;
  }

  int findTokenByTxId(int from, int id, List<TZKTTokenTransfer> tokens) {
    for (int i = from; i < tokens.length; i++){
      if (tokens[i].transactionId == null ) return -1;
      if (tokens[i].transactionId == id) return i;
      if (tokens[i].transactionId! < id) return -1;
    }
    return -1;
  }

  List<TZKTTokenTransfer> _getTokenBefore(
      List<TZKTTokenTransfer>? txs, DateTime timestamp) {
    List<TZKTTokenTransfer> re = [];
    if (txs == null) return re;
    for (var tx in txs) {
      if (tx.timestamp.isBefore(timestamp)) re.add(tx);
    }
    return re;
  }

  List<TZKTTokenTransfer> _getTokenAfter(
      List<TZKTTokenTransfer>? txs, DateTime timestamp) {
    List<TZKTTokenTransfer> re = [];
    if (txs == null) return re;
    for (var tx in txs) {
      if (tx.timestamp.isAfter(timestamp) ||
          tx.timestamp.isAtSameMomentAs(timestamp)) re.add(tx);
    }
    return re;
  }
}
