import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:http/http.dart' as http;

// ignore_for_file: constant_identifier_names

class HttpHelper {
  static Map<String, String> _getHmac(
    HttpMethod method,
    String path,
    body,
    String secretKey,
  ) {
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final hexBody = (method == HttpMethod.GET || body is FormData)
        ? ''
        : bytesToHex(sha256
            .convert(body == null ? [] : utf8.encode(json.encode(body)))
            .bytes);
    final canonicalString = List<String>.of([
      path.split('?').first,
      hexBody,
      timestamp,
    ]).join('|');
    final hmacSha256 = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmacSha256.convert(utf8.encode(canonicalString));
    final sig = bytesToHex(digest.bytes);
    return {
      'X-Api-Signature': sig,
      'X-Api-Timestamp': timestamp,
    };
  }

  static Future<http.Response> hmacAuthenticationPost({
    required String host,
    required String path,
    required String secretKey,
    Map<String, dynamic>? body,
    Map<String, String>? header,
  }) async {
    final url = Uri.parse('$host$path');
    final headers = header ?? {};
    final hmacHeader = _getHmac(HttpMethod.POST, path, body, secretKey);
    headers.addAll({
      ...hmacHeader,
      'Content-Type': 'application/json',
    });

    final response = await http.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return response;
  }

  static Future<http.Response> hmacAuthenticationGet({
    required String host,
    required String path,
    required String secretKey,
    Map<String, String>? header,
  }) async {
    final url = Uri.parse('$host$path');
    final headers = header ?? {};
    final hmacHeader = _getHmac(HttpMethod.GET, path, null, secretKey);
    headers.addAll({
      ...hmacHeader,
      'Content-Type': 'application/json',
    });

    final response = await http.get(
      url,
      headers: headers,
    );
    return response;
  }
}

enum HttpMethod {
  GET,
  POST,
}
