import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/tzkt_api.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/bloc/tzkt_transaction/tzkt_transaction_state.dart';
import 'package:collection/collection.dart';

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
      emit(TZKTTransactionState(newItems: [], isLastPage: true));

      bool isLastPage = newOperationItems.length < event.pageSize;
      int? tokenNum;
      if (isLastPage) {
        tokenNum = (newTokenItems?.length ?? 0) - 1;
      } else {
        int lastOperationID = newOperationItems.last.getID();
        tokenNum = newTokenItems
            ?.lastIndexWhere((element) => element.getID() >= lastOperationID);
      }

      final List<TZKTTransactionInterface> newItems;

      if (tokenNum == null || tokenNum < 0) {
        newItems = newOperationItems;
      } else {
        List<TZKTTokenTransfer> addTokenItems =
            newTokenItems!.sublist(0, tokenNum + 1);
        newItems = mergeOperation(addTokenItems, newOperationItems);

        newTokenItems = newTokenItems?.sublist(tokenNum + 1);
      }

      emit(TZKTTransactionState(newItems: newItems, isLastPage: isLastPage));
    });
  }

  List<TZKTTransactionInterface> mergeOperation(
      List<TZKTTokenTransfer> tokens, List<TZKTOperation> operations) {
    for (var op in operations) {
      if (tokens.isEmpty) return operations;
      final token = tokens
          .firstWhereOrNull((element) => element.transactionId == op.getID());
      op.tokenTransfer = token;
      tokens.remove(token);
    }
    return List<TZKTTransactionInterface>.from(operations)
      ..addAll(tokens)
      ..sort((a, b) => b.getID().compareTo(a.getID()));
  }
}
