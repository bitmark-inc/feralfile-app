///
//  Generated code. Do not modify.
//  source: canvas_control.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'canvas_control.pb.dart' as $0;
export 'canvas_control.pb.dart';

class CanvasControlClient extends $grpc.Client {
  static final _$connect =
      $grpc.ClientMethod<$0.ConnectRequest, $0.ConnectReply>(
          '/canvas_control.CanvasControl/Connect',
          ($0.ConnectRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.ConnectReply.fromBuffer(value));

  CanvasControlClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.ConnectReply> connect($0.ConnectRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$connect, request, options: options);
  }
}

abstract class CanvasControlServiceBase extends $grpc.Service {
  $core.String get $name => 'canvas_control.CanvasControl';

  CanvasControlServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ConnectRequest, $0.ConnectReply>(
        'Connect',
        connect_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ConnectRequest.fromBuffer(value),
        ($0.ConnectReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.ConnectReply> connect_Pre(
      $grpc.ServiceCall call, $async.Future<$0.ConnectRequest> request) async {
    return connect(call, await request);
  }

  $async.Future<$0.ConnectReply> connect(
      $grpc.ServiceCall call, $0.ConnectRequest request);
}
