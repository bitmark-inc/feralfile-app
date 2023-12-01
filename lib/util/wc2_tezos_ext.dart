import 'dart:convert';

import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:collection/collection.dart';
import 'package:tezart/tezart.dart';

extension Wc2TezosRequestExt on Wc2Request {
  BeaconRequest toBeaconRequest() {
    final chain = params['chain'] as String;
    if (chain.caip2Namespace != 'tezos') {
      throw Exception('$chain chain is not supported');
    }

    final List operationsDetails = params['transactions'];

    List<Operation> operations = operationsDetails.map((element) {
      final String? kind = element['kind'];
      final String? storageLimit = element['storageLimit'];
      final String? gasLimit = element['gasLimit'];
      final String? fee = element['fee'];

      if (kind == 'origination') {
        final String balance = element['balance'] ?? '0';
        final List<dynamic> code = element['code'];
        final dynamic storage = element['storage'];

        final operation = OriginationOperation(
          balance: int.parse(balance),
          code: code.map((e) => Map<String, dynamic>.from(e)).toList(),
          storage: storage,
          customFee: fee != null ? int.parse(fee) : null,
          customGasLimit: gasLimit != null ? int.parse(gasLimit) : null,
          customStorageLimit:
              storageLimit != null ? int.parse(storageLimit) : null,
        );
        return operation;
      } else {
        final int amount = int.tryParse(element['amount'].toString()) ?? 0;
        final String destination = element['destination'] ?? '';
        final dynamic parameters = element['parameters'] != null
            ? json.decode(json.encode(element['parameters']))
            : null;
        final String? entrypoint = element['entrypoint'];
        final operation = TransactionOperation(
          amount: amount,
          destination: destination,
          entrypoint: entrypoint,
          params: parameters,
          customFee: int.tryParse(fee ?? ''),
          customGasLimit: int.tryParse(gasLimit ?? ''),
          customStorageLimit:
              storageLimit != null ? int.parse(storageLimit) : null,
        );
        return operation;
      }
    }).toList();

    final String senderID = params['senderID'] ?? '';
    final String version = params['version'] ?? '';
    final String originID = params['originID'] ?? '';
    final String? appName = proposer?.name ?? params['appName'];
    final String? icon = proposer?.icons.firstOrNull ?? params['icon'];
    final String? sourceAddress = params['address'];

    final beaconRequest = BeaconRequest(
      '$id',
      senderID: senderID,
      version: version,
      originID: originID,
      type: 'operation',
      appName: appName,
      icon: icon,
      operations: operations,
      sourceAddress: sourceAddress,
      wc2Topic: topic,
    );

    return beaconRequest;
  }
}
