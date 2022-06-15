import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:tezart/tezart.dart';
import 'package:web3dart/crypto.dart';

main() {
  final client = TezartClient("https://ithacanet.ecadinfra.com");
  final tezosService = TezosServiceImpl(client);
  final wallet = TezosWallet(
    "tz1L76GWnRL8ottK7veac96JPuArFLEhZeVa",
    hexToBytes(
        "6624fca51ce9a25c7ec174e12ae53403f3be5bb2f535b5adea48c4ba441fc3e0"),
    hexToBytes(
        "c9e0152112737a97f4ad01afbb9f076eae20764911696e3e0c92e7f5a21f0992"),
  );

  group('tezos service test', () {
    test('get public key', () async {
      final publicKey = await tezosService.getPublicKey(wallet);

      expect(
          publicKey, "edpkvB8a5H6uwbzKysXRzZ96EqT5pVouZFvz6Qye67sgcZFkSZS92x");
    });

    test('sign message', () async {
      final message = await tezosService.signMessage(
          wallet, Uint8List.fromList(utf8.encode("message")));

      expect(message,
          "edsigtztT6tJS5g3DNbefNhJPzXVT2XR4Vu1iLwxko7C15rocRCcdLGrKhTa8tDhBiePfsKUQbRhdpXeXuzZS8hSTkoSH9Qcr8P");
    });

    test('get tezos balance', () async {
      final balance1 =
          await tezosService.getBalance("tz1R22Abp5iFPaCYUEBZ6WAQtNUjZXsu6ehT");
      expect(balance1, greaterThan(0));
    });

    test('estimate transaction fee', () async {
      final estimate = await tezosService.estimateFee(
          wallet, "tz1iuLHmMKec8M8ZqaXXPmYhFiEiRxN86k44", 1);

      expect(estimate, greaterThan(0));
    });

    test('process transaction operation', () async {
      final operation = TransactionOperation(
          amount: 1, destination: "tz1iuLHmMKec8M8ZqaXXPmYhFiEiRxN86k44");

      final estimate =
          await tezosService.estimateOperationFee(wallet, [operation]);

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
          await tezosService.estimateOperationFee(wallet, operations);

      expect(estimate, greaterThan(0));
    });

    test('send transaction', () async {
      final id = await tezosService.sendTransaction(
          wallet, "tz1L76GWnRL8ottK7veac96JPuArFLEhZeVa", 1);

      expect(id?.isNotEmpty, true);
    });

    test('send operation', () async {
      final operation = TransactionOperation(
          amount: 1, destination: "tz1L76GWnRL8ottK7veac96JPuArFLEhZeVa");

      final id =
          await tezosService.sendOperationTransaction(wallet, [operation]);

      expect(id?.isNotEmpty, true);
    });
  });
}
