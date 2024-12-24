import 'dart:convert';

import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';

class HttpHelper {
  static Map<String, String> _getHmac(
    HttpMethod method,
    String path,
    dynamic body,
    String secretKey,
  ) {
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final hexBody = (method == HttpMethod.get || body is FormData)
        ? ''
        : bytesToHex(
            sha256
                .convert(body == null ? [] : utf8.encode(json.encode(body)))
                .bytes,
          );
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
    final hmacHeader = _getHmac(HttpMethod.post, path, body, secretKey);
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
    final hmacHeader = _getHmac(HttpMethod.get, path, null, secretKey);
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

  static Future<String> contentType(String link) async {
    var renderingType = RenderingType.webview;
    final uri = Uri.tryParse(link);
    if (uri != null) {
      try {
        final res =
            await http.head(uri).timeout(const Duration(milliseconds: 10000));
        renderingType =
            res.headers['content-type']?.toMimeType ?? RenderingType.webview;
      } catch (e) {
        renderingType = RenderingType.webview;
      }
    } else {
      renderingType = RenderingType.webview;
    }
    return renderingType;
  }
}

enum HttpMethod {
  get,
  post,
}
