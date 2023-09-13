import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:http/http.dart' as http;

class HttpHelper {
  static Future<http.Response> post(
      {required String host,
      required String path,
      Map<String, dynamic>? body,
      Map<String, String>? header,
      required String secretKey}) async {
    final url = Uri.parse("$host$path");
    final headers = header ?? {};
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final hexBody = bytesToHex(sha256
        .convert(body == null ? [] : utf8.encode(json.encode(body)))
        .bytes);
    final canonicalString = List<String>.of([
      path.split("?").first,
      hexBody,
      timestamp,
    ]).join("|");
    final hmacSha256 = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmacSha256.convert(utf8.encode(canonicalString));
    final sig = bytesToHex(digest.bytes);
    headers.addAll({
      "X-Api-Signature": sig,
      "X-Api-Timestamp": timestamp,
    });

    final response = await http.post(url, headers: headers);
    return response;
  }
}
