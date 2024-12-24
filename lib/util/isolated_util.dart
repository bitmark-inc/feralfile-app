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

class IsolatedUtil {
  factory IsolatedUtil() {
    return _singleton;
  }

  IsolatedUtil._internal();

  static final IsolatedUtil _singleton = IsolatedUtil._internal();

  SendPort? _sendPort;
  ReceivePort? _receivePort;
  Isolate? _isolate;
  var _isolateReady = Completer<void>();
  static SendPort? _isolateSendPort;

  Future<void> get isolateReady => _isolateReady.future;
  final Map<String, Completer<bool>> _boolCompleters = {};
  final Map<String, Completer<dynamic>> _stringCompleters = {};

  static const shouldShortAPIResonseLog = 'SHOULD_SHORT_API_RESPONSE_LOG';
  static const shouldShortCURLLog = 'SHOULD_SHORT_CURL_LOG';
  static const shouldJsonDecode = 'JSON_DECODE';

  Future<void> start() async {
    if (_sendPort != null || _receivePort != null) return;

    _receivePort = ReceivePort();
    _receivePort!.listen(_handleMessageInMain);
    _isolate = await Isolate.spawn(
      _isolateEntry,
      _receivePort!.sendPort,
    );
  }

  Future<void> startIsolateOrWait() async {
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

    _sendPort!.send([shouldShortAPIResonseLog, uuid, curl]);
    return completer.future;
  }

  Future<bool> shouldShortAPIResponseLog(String curl) async {
    await startIsolateOrWait();

    final uuid = const Uuid().v4();
    final completer = Completer<bool>();
    _boolCompleters[uuid] = completer;

    _sendPort!.send([shouldShortAPIResonseLog, uuid, curl]);
    return completer.future;
  }

  Future<dynamic> parseAndDecode(String response) async {
    await startIsolateOrWait();

    final uuid = const Uuid().v4();
    final completer = Completer<dynamic>();
    _stringCompleters[uuid] = completer;

    _sendPort!.send([shouldJsonDecode, uuid, response]);
    return completer.future;
  }

  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort()..listen(_handleMessageInIsolate);

    sendPort.send(receivePort.sendPort);
    _isolateSendPort = sendPort;
  }

  void _handleMessageInMain(dynamic message) {
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

  static void _handleMessageInIsolate(dynamic message) {
    if (message is List<dynamic>) {
      final uuid = message[1] as String;
      final curl = message[2] as String;
      switch (message[0]) {
        case shouldShortCURLLog:
          _shortCurlLog(uuid, curl);
        case shouldShortAPIResonseLog:
          _shortAPIResponseLog(uuid, curl);
        case shouldJsonDecode:
          _jsonDecode(uuid, curl);
      }
    }
  }

  static void _shortCurlLog(String uuid, String curl) {
    final matched = RegExp(r'.*support.*/issues.*').hasMatch(curl);
    _isolateSendPort?.send(BoolResult(uuid, matched));
  }

  static void _shortAPIResponseLog(String uuid, String curl) {
    final logFilterRegex = <RegExp>[
      RegExp(r'.*/nft.*'),
      RegExp(r'.*support.*/issues.*'),
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
  BoolResult(this.uuid, this.result);

  final String uuid;
  final bool result;
}

class StringResult extends IsolatedUtilResult {
  StringResult(this.uuid, this.result);

  final String uuid;
  final dynamic result;
}
