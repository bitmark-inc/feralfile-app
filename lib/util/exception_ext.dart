import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart';
import 'package:tezart/tezart.dart';

extension ExceptionExt on Exception {
  bool get isNetworkIssue {
    if (this is DioException) {
      final e = this as DioException;
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.error is SocketException;
    }
    if (this is TezartNodeError) {
      final e = this as TezartNodeError;
      return e.cause?.clientError.isNetworkIssue ?? false;
    }

    if (this is TezartHttpError) {
      final e = this as TezartHttpError;
      return e.clientError.isNetworkIssue;
    }

    if (this is ClientException) {
      return true;
    }

    return false;
  }
}
