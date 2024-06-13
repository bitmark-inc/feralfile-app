import 'package:autonomy_flutter/gateway/tv_cast_api.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';

abstract class TvCastService {
  Future<CheckDeviceStatusReply> status(CheckDeviceStatusRequest request);

  Future<ConnectReplyV2> connect(ConnectRequestV2 request);

  Future<DisconnectReplyV2> disconnect(DisconnectRequestV2 request);

  Future<CastListArtworkReply> castListArtwork(CastListArtworkRequest request);

  Future<PauseCastingReply> pauseCasting(PauseCastingRequest request);

  Future<ResumeCastingReply> resumeCasting(ResumeCastingRequest request);

  Future<NextArtworkReply> nextArtwork(NextArtworkRequest request);

  Future<MoveToArtworkReply> moveToArtwork(MoveToArtworkRequest request);

  Future<PreviousArtworkReply> previousArtwork(PreviousArtworkRequest request);

  Future<AppendArtworkToCastingListReply> appendListArtwork(
      AppendArtworkToCastingListRequest request);

  Future<UpdateDurationReply> updateDuration(UpdateDurationRequest request);

  Future<KeyboardEventReply> keyboardEvent(KeyboardEventRequest request);

  Future<RotateReply> rotate(RotateRequest request);

  Future<CastExhibitionReply> castExhibition(CastExhibitionRequest request);

  Future<GestureReply> tap(TapGestureRequest request);

  Future<GestureReply> drag(DragGestureRequest request);

  Future<GetCursorOffsetReply> getCursorOffset(GetCursorOffsetRequest request);

  Future<SetCursorOffsetReply> setCursorOffset(SetCursorOffsetRequest request);
}

class TvCastServiceImpl implements TvCastService {
  final TvCastApi _api;
  final CanvasDevice _device;

  TvCastServiceImpl(this._api, this._device);

  Future<dynamic> _cast(Map<String, dynamic> body) => _api.cast(
        locationId: _device.locationId,
        topicId: _device.topicId,
        body: body,
      );

  Map<String, dynamic> _getBody(Request request) =>
      RequestBody(request).toJson();

  @override
  Future<CheckDeviceStatusReply> status(
      CheckDeviceStatusRequest request) async {
    final result = await _cast(_getBody(request));
    return CheckDeviceStatusReply.fromJson(result);
  }

  @override
  Future<ConnectReplyV2> connect(ConnectRequestV2 request) async {
    final result = await _cast(_getBody(request));
    return ConnectReplyV2.fromJson(result);
  }

  @override
  Future<DisconnectReplyV2> disconnect(DisconnectRequestV2 request) async {
    final result = await _cast(_getBody(request));
    return DisconnectReplyV2.fromJson(result);
  }

  @override
  Future<CastListArtworkReply> castListArtwork(
      CastListArtworkRequest request) async {
    final result = await _cast(_getBody(request));
    return CastListArtworkReply.fromJson(result);
  }

  @override
  Future<PauseCastingReply> pauseCasting(PauseCastingRequest request) async {
    final result = await _cast(_getBody(request));
    return PauseCastingReply.fromJson(result);
  }

  @override
  Future<ResumeCastingReply> resumeCasting(ResumeCastingRequest request) async {
    final result = await _cast(_getBody(request));
    return ResumeCastingReply.fromJson(result);
  }

  @override
  Future<NextArtworkReply> nextArtwork(NextArtworkRequest request) async {
    final result = await _cast(_getBody(request));
    return NextArtworkReply.fromJson(result);
  }

  @override
  Future<MoveToArtworkReply> moveToArtwork(MoveToArtworkRequest request) async {
    final result = await _cast(_getBody(request));
    return MoveToArtworkReply.fromJson(result);
  }

  @override
  Future<PreviousArtworkReply> previousArtwork(
      PreviousArtworkRequest request) async {
    final result = await _cast(_getBody(request));
    return PreviousArtworkReply.fromJson(result);
  }

  @override
  Future<AppendArtworkToCastingListReply> appendListArtwork(
      AppendArtworkToCastingListRequest request) async {
    final result = await _cast(_getBody(request));
    return AppendArtworkToCastingListReply.fromJson(result);
  }

  @override
  Future<UpdateDurationReply> updateDuration(
      UpdateDurationRequest request) async {
    final result = await _cast(_getBody(request));
    return UpdateDurationReply.fromJson(result);
  }

  @override
  Future<KeyboardEventReply> keyboardEvent(KeyboardEventRequest request) async {
    final result = await _cast(_getBody(request));
    return KeyboardEventReply.fromJson(result);
  }

  @override
  Future<RotateReply> rotate(RotateRequest request) async {
    final result = await _cast(_getBody(request));
    return RotateReply.fromJson(result);
  }

  @override
  Future<CastExhibitionReply> castExhibition(
      CastExhibitionRequest request) async {
    final result = await _cast(_getBody(request));
    return CastExhibitionReply.fromJson(result);
  }

  @override
  Future<GestureReply> tap(TapGestureRequest request) async {
    final result = await _cast(_getBody(request));
    return GestureReply.fromJson(result);
  }

  @override
  Future<GestureReply> drag(DragGestureRequest request) async {
    final result = await _cast(_getBody(request));
    return GestureReply.fromJson(result);
  }

  @override
  Future<GetCursorOffsetReply> getCursorOffset(
      GetCursorOffsetRequest request) async {
    final result = await _cast(_getBody(request));
    return GetCursorOffsetReply.fromJson(result);
  }

  @override
  Future<SetCursorOffsetReply> setCursorOffset(
      SetCursorOffsetRequest request) async {
    final result = await _cast(_getBody(request));
    return SetCursorOffsetReply.fromJson(result);
  }
}
