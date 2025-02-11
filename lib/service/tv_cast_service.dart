import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/tv_cast_api.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/dio_exception_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sentry/sentry_io.dart';

abstract class TvCastService {
  Future<CheckDeviceStatusReply> status(
    CheckDeviceStatusRequest request, {
    bool shouldShowError = true,
  });

  Future<ConnectReplyV2> connect(ConnectRequestV2 request);

  Future<DisconnectReplyV2> disconnect(DisconnectRequestV2 request);

  Future<CastListArtworkReply> castListArtwork(CastListArtworkRequest request);

  Future<PauseCastingReply> pauseCasting(PauseCastingRequest request);

  Future<ResumeCastingReply> resumeCasting(ResumeCastingRequest request);

  Future<NextArtworkReply> nextArtwork(NextArtworkRequest request);

  Future<PreviousArtworkReply> previousArtwork(PreviousArtworkRequest request);

  Future<UpdateDurationReply> updateDuration(UpdateDurationRequest request);

  Future<KeyboardEventReply> keyboardEvent(KeyboardEventRequest request);

  Future<RotateReply> rotate(RotateRequest request);

  Future<SendLogReply> getSupport(SendLogRequest request);

  Future<GetVersionReply> getVersion(GetVersionRequest request);

  Future<UpdateOrientationReply> updateOrientation(
    UpdateOrientationRequest request,
  );

  Future<UpdateArtFramingReply> updateArtFraming(
    UpdateArtFramingRequest request,
  );

  Future<CastExhibitionReply> castExhibition(CastExhibitionRequest request);

  Future<CastDailyWorkReply> castDailyWork(CastDailyWorkRequest request);

  Future<GestureReply> tap(TapGestureRequest request);

  Future<GestureReply> drag(DragGestureRequest request);
}

abstract class BaseTvCastService implements TvCastService {
  BaseTvCastService();

  Future<Map<String, dynamic>> _sendData(
    Map<String, dynamic> body, {
    bool shouldShowError = true,
  });

  Map<String, dynamic> _getBody(Request request) =>
      RequestBody(request).toJson();

  @override
  Future<CheckDeviceStatusReply> status(
    CheckDeviceStatusRequest request, {
    bool shouldShowError = true,
  }) async {
    final result =
        await _sendData(_getBody(request), shouldShowError: shouldShowError);
    return CheckDeviceStatusReply.fromJson(result);
  }

  @override
  Future<ConnectReplyV2> connect(ConnectRequestV2 request) async {
    try {
      final result = await _sendData(_getBody(request));
      return ConnectReplyV2.fromJson(result);
    } catch (e) {
      log.info('Failed to connect to device: $e');
      rethrow;
    }
  }

  @override
  Future<DisconnectReplyV2> disconnect(DisconnectRequestV2 request) async {
    final result = await _sendData(_getBody(request));
    return DisconnectReplyV2.fromJson(result);
  }

  @override
  Future<CastListArtworkReply> castListArtwork(
    CastListArtworkRequest request,
  ) async {
    final result = await _sendData(_getBody(request));
    return CastListArtworkReply.fromJson(result);
  }

  @override
  Future<PauseCastingReply> pauseCasting(PauseCastingRequest request) async {
    final result = await _sendData(_getBody(request));
    return PauseCastingReply.fromJson(result);
  }

  @override
  Future<ResumeCastingReply> resumeCasting(ResumeCastingRequest request) async {
    final result = await _sendData(_getBody(request));
    return ResumeCastingReply.fromJson(result);
  }

  @override
  Future<NextArtworkReply> nextArtwork(NextArtworkRequest request) async {
    final result = await _sendData(_getBody(request));
    return NextArtworkReply.fromJson(result);
  }

  @override
  Future<PreviousArtworkReply> previousArtwork(
    PreviousArtworkRequest request,
  ) async {
    final result = await _sendData(_getBody(request));
    return PreviousArtworkReply.fromJson(result);
  }

  @override
  Future<UpdateDurationReply> updateDuration(
    UpdateDurationRequest request,
  ) async {
    final result = await _sendData(_getBody(request));
    return UpdateDurationReply.fromJson(result);
  }

  @override
  Future<KeyboardEventReply> keyboardEvent(KeyboardEventRequest request) async {
    final result = await _sendData(_getBody(request));
    return KeyboardEventReply.fromJson(result);
  }

  @override
  Future<RotateReply> rotate(RotateRequest request) async {
    final result = await _sendData(_getBody(request));
    return RotateReply.fromJson(result);
  }

  @override
  Future<SendLogReply> getSupport(SendLogRequest request) async {
    final result = await _sendData(_getBody(request));
    return SendLogReply.fromJson(result);
  }

  @override
  Future<GetVersionReply> getVersion(GetVersionRequest request) async {
    final result = await _sendData(_getBody(request));
    return GetVersionReply.fromJson(result);
  }

  @override
  Future<UpdateOrientationReply> updateOrientation(
    UpdateOrientationRequest request,
  ) async {
    final result = await _sendData(_getBody(request));
    return UpdateOrientationReply.fromJson(result);
  }

  @override
  Future<UpdateArtFramingReply> updateArtFraming(
    UpdateArtFramingRequest request,
  ) async {
    final result = await _sendData(_getBody(request));
    return UpdateArtFramingReply.fromJson(result);
  }

  @override
  Future<CastExhibitionReply> castExhibition(
    CastExhibitionRequest request,
  ) async {
    final result = await _sendData(_getBody(request));
    return CastExhibitionReply.fromJson(result);
  }

  @override
  Future<CastDailyWorkReply> castDailyWork(CastDailyWorkRequest request) async {
    try {
      final body = _getBody(request);
      final result = await _sendData(body);
      return CastDailyWorkReply.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GestureReply> tap(TapGestureRequest request) async {
    final result = await _sendData(_getBody(request));
    return GestureReply.fromJson(result);
  }

  @override
  Future<GestureReply> drag(DragGestureRequest request) async {
    final result = await _sendData(_getBody(request));
    return GestureReply.fromJson(result);
  }
}

class TvCastServiceImpl extends BaseTvCastService {
  TvCastServiceImpl(this._api, this._device);

  final TvCastApi _api;
  final CanvasDevice _device;

  void _handleError(Object error) {
    final context = injector<NavigationService>().context;
    unawaited(Sentry.captureException(error));
    if (error is DioException) {
      if (error.error is FeralfileError) {
        unawaited(
          UIHelper.showTVConnectError(
            context,
            error.error! as FeralfileError,
          ),
        );
      } else if (error.isBranchError) {
        final feralfileError = error.branchError;
        unawaited(UIHelper.showTVConnectError(context, feralfileError));
      }
    } else {
      unawaited(
        UIHelper.showTVConnectError(
          context,
          FeralfileError(
            StatusCode.badRequest.value,
            'Unknown error: $error',
          ),
        ),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> _sendData(
    Map<String, dynamic> body, {
    bool shouldShowError = true,
  }) async {
    try {
      final result = await _api.request(
        locationId: _device.locationId,
        topicId: _device.topicId,
        body: body,
      );
      return (result['message'] as Map).cast<String, dynamic>();
    } catch (e) {
      unawaited(Sentry.captureException(e));
      if (shouldShowError) {
        _handleError(e);
      }
      rethrow;
    }
  }
}

class BluetoothCastService extends BaseTvCastService {
  BluetoothCastService(this._device);

  final BluetoothDevice _device;

  @override
  Future<Map<String, dynamic>> _sendData(
    Map<String, dynamic> body, {
    bool shouldShowError = true,
  }) async {
    final command = body['command'] as String;
    final request = Map<String, dynamic>.from(body['request'] as Map);
    try {
      await injector<FFBluetoothService>().connectToDevice(_device);
      if (!_device.isConnected) {
        throw Exception('Device not connected after reconnection');
      }

      final res = await injector<FFBluetoothService>()
          .sendCommand(device: _device, command: command, request: request);
      log.info('[BluetoothCastService] sendCommand $command');
      return res;
    } catch (e) {
      unawaited(
        Sentry.captureException(
          '[BluetoothCastService] sendCommand $command failed with error:  $e',
        ),
      );
      rethrow;
    }
  }
}
