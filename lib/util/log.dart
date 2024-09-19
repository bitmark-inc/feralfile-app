// SPDX-License-Identifier: BSD-2-Clause-Patent
// Copyright © 2022 Bitmark. All rights reserved.
// Use of this source code is governed by the BSD-2-Clause Plus Patent License
// that can be found in the LICENSE file.

// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final log = Logger('App');
final apiLog = Logger('API');

enum APIErrorCode {
  invalidToken,
  notLoggedIn,
  expiredSubscription,
  ffNotConnected
}

APIErrorCode? getAPIErrorCode(int code) {
  switch (code) {
    case 7001:
      return APIErrorCode.invalidToken;
    case 1002:
      return APIErrorCode.notLoggedIn;
    case 1041:
      return APIErrorCode.expiredSubscription;
    case 2013:
      return APIErrorCode.ffNotConnected;
    default:
      return null;
  }
}

Future<File> getLogFile() async {
  final directory = (await getTemporaryDirectory()).path;
  const fileName = 'app.log';

  return _createLogFile('$directory/$fileName');
}

Future<File> _createLogFile(String canonicalLogFileName) async =>
    File(canonicalLogFileName).create(recursive: true);

class FileLogger {
  static late File _logFile;
  static const int maxFileSize = 1024 * 1024; // 1MB
  static late StreamController<String> _logStreamController;
  static bool _isInitialized = false;

  static Future initializeLogging() async {
    _logFile = await getLogFile();
    _isInitialized = true;

    // Initialize the StreamController and start the background task
    _logStreamController = StreamController<String>();
    _logStreamController.stream.listen(
      (logEntry) async {
        try {
          await _writeLog(logEntry);
        } catch (e) {
          debugPrint('Error writing log: $e');
        }
      },
      onError: (error) {
        debugPrint('Stream error: $error');
      },
      onDone: () {
        debugPrint('Log stream closed');
      },
    );

    // Write initial log entry
    final text = '${DateTime.now()}: LOGGING STARTED\n';
    _logStreamController.add(text);
  }

  static Future<void> _writeLog(String text) async {
    // Check if file size exceeds max size
    await _rotateLogFileIfNeeded();

    await _logFile.writeAsString(text, mode: FileMode.append, flush: true);
  }

  static Future<void> _rotateLogFileIfNeeded() async {
    final fileStat = await _logFile.stat();
    if (fileStat.size >= maxFileSize) {
      // Rotate the log file
      final directory = _logFile.parent.path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rotatedFileName = 'app_$timestamp.log';

      final rotatedFile = File('$directory/$rotatedFileName');
      await _logFile.rename(rotatedFile.path);

      // Create a new log file
      _logFile = await getLogFile();
    }
  }

  static void setLogFile(File file) {
    _logFile = file;
  }

  static File get logFile => _logFile;

  static Future log(LogRecord record) async {
    if (!_isInitialized) {
      await initializeLogging();
    }

    var text = '$record\n';
    text = _filterLog(text);

    debugPrint(text);

    // Add log entry to the queue
    _logStreamController.add('${record.time}: $text');
  }

  static Future<void> clear() async {
    // Delete the current log file and all rotated log files
    final directory = _logFile.parent;
    final logFiles = directory
        .listSync()
        .where((file) =>
            file is File && file.path.contains(RegExp(r'app(_\d+)?\.log$')))
        .cast<File>();

    for (var file in logFiles) {
      await file.delete();
    }

    // Create a new log file
    _logFile = await getLogFile();
  }

  static Future dispose() async {
    await _logStreamController.close();
  }

  static String _filterLog(String logText) {
    String filteredLog = logText;

    RegExp combinedRegex = RegExp('("message":".*?")|'
        '("Authorization: Bearer .*?")|'
        '("X-Api-Signature: .*?")|'
        r'(signature: [^,\}]*)|'
        r'(location: \[.*?,.*?\])|'
        r'(\\"signature\\":\\".*?\\")|'
        r'(\\"location\\":\[.*?,.*?\])|'
        r'(0x[A-Fa-f0-9]{64}[\s\W])|'
        r'(0x[A-Fa-f0-9]{128,144}[\s\W])|'
        r'(eyJ[A-Za-z0-9-_]+\.eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_.+/]*)|'
        r'(\\"receipt\\":\{[^{}]*\})');

    filteredLog = filteredLog.replaceAllMapped(combinedRegex, (match) {
      if (match[1] != null) {
        return '"message":"REDACTED_MESSAGE"';
      }
      if (match[2] != null) {
        return '"Authorization: Bearer REDACTED_AUTH_TOKEN"';
      }
      if (match[3] != null) {
        return '"X-Api-Signature: REDACTED_X_API_SIGNATURE"';
      }
      if (match[4] != null) {
        return 'signature: REDACTED_SIGNATURE';
      }
      if (match[5] != null) {
        return 'location: REDACTED_LOCATION';
      }
      if (match[6] != null) {
        return r'\"signature\":\"REDACTED_SIGNATURE\"';
      }
      if (match[7] != null) {
        return r'\"location\":REDACTED_LOCATION';
      }
      if (match[8] != null || match[9] != null) {
        return 'REDACTED_SIGNATURE';
      }
      if (match[10] != null) {
        return 'REDACTED_JWT_TOKEN';
      }
      if (match[11] != null) {
        return r'\"receipt\": REDACTED_RECEIPT';
      }
      return '';
    });

    return filteredLog;
  }
}

class SentryBreadcrumbLogger {
  static Future log(LogRecord record) async {
    if (record.loggerName == apiLog.name) {
      // do not send api breadcrumb here.
      return;
    }
    if (record.level == Level.FINE ||
        record.level == Level.FINER ||
        record.level == Level.FINEST) {
      return;
    }
    String? type;
    SentryLevel? level;
    if (record.level == Level.WARNING) {
      type = 'error';
      level = SentryLevel.warning;
    }
    await Sentry.addBreadcrumb(
      Breadcrumb(
          message: '[${record.level}] ${record.message}',
          level: level,
          type: type),
    );
  }

  static Future<void> clear() async {
    await Sentry.configureScope((scope) => scope.clearBreadcrumbs());
  }
}
