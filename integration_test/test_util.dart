import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<void> addDelay(int ms) async {
  await Future<void>.delayed(Duration(milliseconds: ms));
}

Future<void> depositTezos(String address) async {
  final faucetUrl = dotenv.env['TEZOS_FAUCET_URL'] ?? '';
  final token = dotenv.env['TEZOS_FAUCET_AUTH_TOKEN'] ?? '';

  await http.post(
    Uri.parse(faucetUrl),
    body: json.encode({"address": address}),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Basic $token",
    },
  );
}
