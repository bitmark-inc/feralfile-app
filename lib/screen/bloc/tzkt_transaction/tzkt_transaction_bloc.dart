import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/tzkt_api.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/bloc/tzkt_transaction/tzkt_transaction_state.dart';

class TZKTTransactionBloc
    extends AuBloc<TZKTTransactionEvent, TZKTTransactionState> {
  List<TZKTTokenTransfer>? tokenItems;
  List<TZKTTokenTransfer>? newTokenItems;
  //**********************************************************************

  TZKTTransactionBloc()
      : super(TZKTTransactionState(newItems: [])) {
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
        //limit: _pageSize,
        //lastId: pageKey > 0 ? pageKey : null,
      );
      newTokenItems ??= tokenItems;
      DateTime lastOperationDatetime = newOperationItems.last.timestamp;
      List<TZKTTokenTransfer>? addTokenItems =
      _getTokenAfter(newTokenItems, lastOperationDatetime);
      newTokenItems = _getTokenBefore(newTokenItems, lastOperationDatetime);
      final newItems = mergeOperation(addTokenItems, newOperationItems);

      bool isLastPage = newOperationItems.length < event.pageSize;
      emit(TZKTTransactionState(newItems: newItems, isLastPage: isLastPage ));
    });
  }

  //**********************************************************************

  List<TZKTTransactionIF> mergeOperation(
      List<TZKTTokenTransfer>? token, List<TZKTOperation> operation) {
    List<TZKTTransactionIF> tx = [];
    int tokenIndex = 0;
    int operationIndex = 0;
    int tokenLen = token == null ? 0 : token.length;
    //int totalLen = token.length + operation.length;
    while (tokenIndex < tokenLen && operationIndex < operation.length) {
      if (operationIndex >= operation.length) {
        tx.add(token![tokenIndex]);
        tokenIndex++;
      } else if (tokenIndex >= tokenLen) {
        tx.add(operation[operationIndex]);
        operationIndex++;
      } else {
        if (token![tokenIndex].id > operation[operationIndex].id) {
          tx.add(token[tokenIndex]);
          tokenIndex++;
        } else {
          tx.add(operation[operationIndex]);
          operationIndex++;
        }
      }
    }

    return removePairedToken(tx);
  }

  //if found tokenTransfer tx[i].transactionID equal operation tx[j].id, set  tx[j].tokenTransfer = tx[i] and remove tx[i]
  List<TZKTTransactionIF> removePairedToken(List<TZKTTransactionIF> tx) {
    int i = 0;
    while (i < tx.length - 1) {
      if (tx[i] is TZKTTokenTransfer) {
        TZKTTokenTransfer tempT = tx[i] as TZKTTokenTransfer;
        if (tempT.transactionId != null) {
          for (int j = i + 1; j < tx.length; j++) {
            if (tx[j] is TZKTOperation) {
              TZKTOperation tempO = tx[j] as TZKTOperation;
              if (tempT.transactionId == tempO.id) {
                tempO.tokenTransfer = tempT;
                tx.removeAt(i);
                break;
              } else if (tempT.transactionId! < tempO.id) {
                break;
              }
            }
          }
        }
      }
      i++;
    }
    return tx;
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
