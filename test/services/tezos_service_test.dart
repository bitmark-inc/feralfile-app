import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:tezart/tezart.dart';
import 'package:uuid/uuid.dart';

main() {
  final client = TezartClient("https://ghostnet.tezos.marigold.dev");
  final tezosService = TezosServiceImpl(client);
  final walletStorage = MockWalletStorage(const Uuid().v4());

  const publicKey = "edpkvB8a5H6uwbzKysXRzZ96EqT5pVouZFvz6Qye67sgcZFkSZS92x";

  group('tezos service test', () {
    test('sign message', () async {
      final message = await tezosService.signMessage(
          walletStorage, 0, Uint8List.fromList(utf8.encode("message")));

      expect(message,
          "edsigtXomBKi5CTRf5cjATJWSyaRvhfYNHqSUGrn4SdbYRcGwQrUGjzEfQDTuqHhuA8b2d8NarZjz8TRf65WkpQmo423BtomS8Q");
    });

    test('get tezos balance', () async {
      final balance1 =
          await tezosService.getBalance("tz1R22Abp5iFPaCYUEBZ6WAQtNUjZXsu6ehT");
      expect(balance1, greaterThan(0));
    });

    test('estimate transaction fee', () async {
      final estimate = await tezosService.estimateFee(
          publicKey, "tz1iuLHmMKec8M8ZqaXXPmYhFiEiRxN86k44", 1);

      expect(estimate, greaterThan(0));
    });

    test('process transaction operation', () async {
      final operation = TransactionOperation(
          amount: 1, destination: "tz1iuLHmMKec8M8ZqaXXPmYhFiEiRxN86k44");

      final estimate =
          await tezosService.estimateOperationFee(publicKey, [operation]);

      expect(estimate, greaterThan(0));
    });

    test('process batch operation', () async {
      final operations = [
        TransactionOperation(
            amount: 2, destination: "tz1iuLHmMKec8M8ZqaXXPmYhFiEiRxN86k44"),
        TransactionOperation(
            amount: 1, destination: "tz1iuLHmMKec8M8ZqaXXPmYhFiEiRxN86k44"),
      ];

      final estimate =
          await tezosService.estimateOperationFee(publicKey, operations);

      expect(estimate, greaterThan(0));
    });

    // test('send transaction', () async {
    //   final id = await tezosService.sendTransaction(
    //       walletStorage, "tz1L76GWnRL8ottK7veac96JPuArFLEhZeVa", 1);
    //
    //   expect(id?.isNotEmpty, true);
    // });
    //
    // test('send operation', () async {
    //   final operation = TransactionOperation(
    //       amount: 1, destination: "tz1L76GWnRL8ottK7veac96JPuArFLEhZeVa");
    //
    //   final id =
    //       await tezosService.sendOperationTransaction(walletStorage, [operation]);
    //
    //   expect(id?.isNotEmpty, true);
    // });
  });
}

class MockWalletStorage extends WalletStorage {
  MockWalletStorage(String uuid) : super(uuid);

  @override
  Future<String> getTezosPublicKey({int index = 0}) async {
    return "edpkvB8a5H6uwbzKysXRzZ96EqT5pVouZFvz6Qye67sgcZFkSZS92x";
  }

  @override
  Future<Uint8List> tezosSignMessage(Uint8List message, {int index = 0}) async {
    return Uint8List(64);
  }

  @override
  Future<Uint8List> tezosSignTransaction(String forgedHex,
      {int index = 0}) async {
    return Uint8List(64);
  }
}
