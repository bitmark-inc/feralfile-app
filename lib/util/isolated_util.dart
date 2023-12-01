//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

// ignore_for_file: constant_identifier_names

class IsolatedUtil {
  static final IsolatedUtil _singleton = IsolatedUtil._internal();

  factory IsolatedUtil() => _singleton;

  IsolatedUtil._internal();

  SendPort? _sendPort;
  ReceivePort? _receivePort;
  Isolate? _isolate;
  var _isolateReady = Completer<void>();
  static SendPort? _isolateSendPort;

  Future<void> get isolateReady => _isolateReady.future;
  final Map<String, Completer<bool>> _boolCompleters = {};
  final Map<String, Completer<dynamic>> _stringCompleters = {};

  static const SHOULD_SHORT_API_RESPONSE_LOG = 'SHOULD_SHORT_API_RESPONSE_LOG';
  static const SHOULD_SHORT_CURL_LOG = 'SHOULD_SHORT_CURL_LOG';
  static const JSON_DECODE = 'JSON_DECODE';

  Future<void> start() async {
    if (_sendPort != null || _receivePort != null) {
      return;
    }

    _receivePort = ReceivePort();
    _receivePort!.listen(_handleMessageInMain);
    _isolate = await Isolate.spawn(
      _isolateEntry,
      _receivePort!.sendPort,
    );
  }

  Future startIsolateOrWait() async {
    if (_receivePort == null) {
      await start();
      await isolateReady;
      //
    } else if (!_isolateReady.isCompleted) {
      await isolateReady;
    }
  }

  Future<bool> shouldShortCurlLog(String curl) async {
    await startIsolateOrWait();

    final uuid = const Uuid().v4();
    final completer = Completer<bool>();
    _boolCompleters[uuid] = completer;

    _sendPort!.send([SHOULD_SHORT_API_RESPONSE_LOG, uuid, curl]);
    return completer.future;
  }

  Future<bool> shouldShortAPIResponseLog(String curl) async {
    await startIsolateOrWait();

    final uuid = const Uuid().v4();
    final completer = Completer<bool>();
    _boolCompleters[uuid] = completer;

    _sendPort!.send([SHOULD_SHORT_API_RESPONSE_LOG, uuid, curl]);
    return completer.future;
  }

  Future<dynamic> parseAndDecode(String response) async {
    await startIsolateOrWait();

    final uuid = const Uuid().v4();
    final completer = Completer<dynamic>();
    _stringCompleters[uuid] = completer;

    _sendPort!.send([JSON_DECODE, uuid, response]);
    return completer.future;
  }

  static Future<void> _isolateEntry(SendPort sendPort) async {
    final receivePort = ReceivePort()..listen(_handleMessageInIsolate);

    sendPort.send(receivePort.sendPort);
    _isolateSendPort = sendPort;
  }

  Future<void> _handleMessageInMain(message) async {
    if (message is SendPort) {
      _sendPort = message;
      _isolateReady.complete();

      return;
    }

    final result = message;
    if (result is BoolResult) {
      _boolCompleters[result.uuid]?.complete(result.result);
      _boolCompleters.remove(result.uuid);
    } else if (result is StringResult) {
      _stringCompleters[result.uuid]?.complete(result.result);
      _stringCompleters.remove(result.uuid);
    }
  }

  static void _handleMessageInIsolate(message) {
    if (message is List<dynamic>) {
      switch (message[0]) {
        case SHOULD_SHORT_CURL_LOG:
          _shortCurlLog(message[1], message[2]);
          break;
        case SHOULD_SHORT_API_RESPONSE_LOG:
          _shortAPIResponseLog(message[1], message[2]);
          break;
        case JSON_DECODE:
          _jsonDecode(message[1], message[2]);
          break;
      }
    }
  }

  static void _shortCurlLog(String uuid, String curl) {
    final matched = RegExp('.*support.*/issues.*').hasMatch(curl);
    _isolateSendPort?.send(BoolResult(uuid, matched));
  }

  static void _shortAPIResponseLog(String uuid, String curl) {
    List<RegExp> logFilterRegex = [
      RegExp('.*/nft.*'),
      RegExp('.*support.*/issues.*'),
    ];

    final matched =
        logFilterRegex.firstWhereOrNull((regex) => regex.hasMatch(curl)) !=
            null;
    _isolateSendPort?.send(BoolResult(uuid, matched));
  }

  static void _jsonDecode(String uuid, String response) {
    final result = jsonDecode(response);
    _isolateSendPort?.send(StringResult(uuid, result));
  }

  void disposeIsolate() {
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
    _receivePort?.close();
    _isolateReady = Completer<void>();
  }
}

abstract class IsolatedUtilResult {}

class BoolResult extends IsolatedUtilResult {
  final String uuid;
  final bool result;

  BoolResult(this.uuid, this.result);
}

class StringResult extends IsolatedUtilResult {
  final String uuid;
  final dynamic result;

  StringResult(this.uuid, this.result);
}
