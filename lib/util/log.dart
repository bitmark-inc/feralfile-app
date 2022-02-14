import 'dart:convert';
import 'dart:io';
import 'dart:core';
import 'package:dio/dio.dart';
import 'package:synchronized/synchronized.dart' as synchronization;
import 'package:path_provider/path_provider.dart';

import 'package:logging/logging.dart';

final log = Logger('MyClassName');

Future<String> getLogFilePath() async {
  Directory tempDir = await getTemporaryDirectory();
  return tempDir.path + "/app.log";
}

class FileLogger {
  static final _lock =
      synchronization.Lock(); // uses the “synchronized” package
  static late File _logFile;

  static Future initializeLogging(String canonicalLogFileName) async {
    _logFile = _createLogFile(canonicalLogFileName);
    final text = '${new DateTime.now()}: LOGGING STARTED\n';

    /// per its documentation, `writeAsString` “Opens the file, writes
    /// the string in the given encoding, and closes the file”
    return _logFile.writeAsString(text, mode: FileMode.write, flush: true);
  }

  static Future log(String s) async {
    final text = '$s\n';
    return _lock.synchronized(() async {
      await _logFile.writeAsString(text, mode: FileMode.append, flush: true);
    });
  }

  static File _createLogFile(canonicalLogFileName) =>
      File(canonicalLogFileName);
}

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    final curl = cURLRepresentation(err.requestOptions);
    final message = err.message;
    log.info("API Request: $curl");
    log.warning("Respond error: $message");
    return handler.next(err);
  }

  @override
  Future onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    final curl = cURLRepresentation(response.requestOptions);
    final message = response.toString();
    log.info("API Request: $curl");
    log.info("API Response: $message");

    return handler.next(response);
  }

  String cURLRepresentation(RequestOptions options) {
    List<String> components = ["\$ curl -i"];
    if (options.method != null && options.method.toUpperCase() == "GET") {
      components.add("-X ${options.method}");
    }

    if (options.headers != null) {
      options.headers.forEach((k, v) {
        if (k != "Cookie") {
          components.add("-H \"$k: $v\"");
        }
      });
    }

    var data = json.encode(options.data);
    if (data != null) {
      data = data.replaceAll('\"', '\\\"');
      components.add("-d \"$data\"");
    }

    components.add("\"${options.uri.toString()}\"");

    return components.join('\\\n\t');
  }
}
