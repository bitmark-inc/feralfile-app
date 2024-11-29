// Import statements for Flutter

// ignore_for_file: avoid_unused_constructor_parameters

enum CastCommand {
  checkStatus,
  castListArtwork,
  cancelCasting,
  appendArtworkToCastingList,
  pauseCasting,
  resumeCasting,
  nextArtwork,
  previousArtwork,
  updateDuration,
  castExhibition,
  connect,
  disconnect,
  setCursorOffset,
  getCursorOffset,
  sendKeyboardEvent,
  rotate,
  tapGesture,
  dragGesture,
  castDaily;

  static CastCommand fromString(String command) {
    switch (command) {
      case 'checkStatus':
        return CastCommand.checkStatus;
      case 'castListArtwork':
        return CastCommand.castListArtwork;
      case 'castDaily':
        return CastCommand.castDaily;
      case 'cancelCasting':
        return CastCommand.cancelCasting;
      case 'appendArtworkToCastingList':
        return CastCommand.appendArtworkToCastingList;
      case 'pauseCasting':
        return CastCommand.pauseCasting;
      case 'resumeCasting':
        return CastCommand.resumeCasting;
      case 'nextArtwork':
        return CastCommand.nextArtwork;
      case 'previousArtwork':
        return CastCommand.previousArtwork;
      case 'updateDuration':
        return CastCommand.updateDuration;
      case 'castExhibition':
        return CastCommand.castExhibition;
      case 'connect':
        return CastCommand.connect;
      case 'disconnect':
        return CastCommand.disconnect;
      case 'setCursorOffset':
        return CastCommand.setCursorOffset;
      case 'getCursorOffset':
        return CastCommand.getCursorOffset;
      case 'sendKeyboardEvent':
        return CastCommand.sendKeyboardEvent;
      case 'rotate':
        return CastCommand.rotate;
      case 'tapGesture':
        return CastCommand.tapGesture;
      case 'dragGesture':
        return CastCommand.dragGesture;
      default:
        throw ArgumentError('Unknown command: $command');
    }
  }

  static CastCommand fromRequest(Request request) {
    switch (request.runtimeType) {
      case const (CheckDeviceStatusRequest):
        return CastCommand.checkStatus;
      case const (CastListArtworkRequest):
        return CastCommand.castListArtwork;
      case const (CastDailyWorkRequest):
        return CastCommand.castDaily;
      case const (CancelCastingRequest):
        return CastCommand.cancelCasting;
      case const (AppendArtworkToCastingListRequest):
        return CastCommand.appendArtworkToCastingList;
      case const (PauseCastingRequest):
        return CastCommand.pauseCasting;
      case const (ResumeCastingRequest):
        return CastCommand.resumeCasting;
      case const (NextArtworkRequest):
        return CastCommand.nextArtwork;
      case const (PreviousArtworkRequest):
        return CastCommand.previousArtwork;
      case const (UpdateDurationRequest):
        return CastCommand.updateDuration;
      case const (CastExhibitionRequest):
        return CastCommand.castExhibition;
      case const (ConnectRequestV2):
        return CastCommand.connect;
      case const (DisconnectRequestV2):
        return CastCommand.disconnect;
      case const (SetCursorOffsetRequest):
        return CastCommand.setCursorOffset;
      case const (GetCursorOffsetRequest):
        return CastCommand.getCursorOffset;
      case const (KeyboardEventRequest):
        return CastCommand.sendKeyboardEvent;
      case const (RotateRequest):
        return CastCommand.rotate;
      case const (TapGestureRequest):
        return CastCommand.tapGesture;
      case const (DragGestureRequest):
        return CastCommand.dragGesture;
      default:
        throw Exception('Unknown request type');
    }
  }
}

class RequestBody {
  RequestBody(this.request) : command = CastCommand.fromRequest(request);

  // fromJson method
  factory RequestBody.fromJson(Map<String, dynamic> json) {
    final commandString = json['command'] as String;
    final command = CastCommand.fromString(commandString);

    Request request;
    switch (command) {
      case CastCommand.checkStatus:
        request = CheckDeviceStatusRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.castListArtwork:
        request = CastListArtworkRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.castDaily:
        request = CastDailyWorkRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.cancelCasting:
        request = CancelCastingRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.appendArtworkToCastingList:
        request = AppendArtworkToCastingListRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.pauseCasting:
        request = PauseCastingRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.resumeCasting:
        request = ResumeCastingRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.nextArtwork:
        request = NextArtworkRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.previousArtwork:
        request = PreviousArtworkRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.updateDuration:
        request = UpdateDurationRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.castExhibition:
        request = CastExhibitionRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.connect:
        request =
            ConnectRequestV2.fromJson(json['request'] as Map<String, dynamic>);
      case CastCommand.disconnect:
        request = DisconnectRequestV2.fromJson(
          json['request'] as Map<String, dynamic>,
        );

      case CastCommand.setCursorOffset:
      case CastCommand.getCursorOffset:
      case CastCommand.sendKeyboardEvent:
      case CastCommand.rotate:
      case CastCommand.tapGesture:
      case CastCommand.dragGesture:
      default:
        throw ArgumentError('Unknown command: $commandString');
    }

    return RequestBody(request);
  }

  final CastCommand command;
  final Request request;

  Map<String, dynamic> toJson() => {
        'command': command.toString().split('.').last,
        'request': request.toJson(),
      };
}

class Reply {
  factory Reply.fromJson(Map<String, dynamic> json) => Reply();

  Reply();

  Map<String, dynamic> toJson() => {};
}

class ReplyWithOK extends Reply {
  ReplyWithOK({required this.ok});

  factory ReplyWithOK.fromJson(Map<String, dynamic> json) => ReplyWithOK(
        ok: json['ok'] as bool,
      );
  final bool ok;

  @override
  Map<String, dynamic> toJson() => {
        'ok': ok,
      };
}

abstract class Request {
  Map<String, dynamic> toJson();
}

// Enum for DevicePlatform
enum DevicePlatform {
  iOS,
  android,
  macos,
  tizenTV,
  androidTV,
  lgTV,
  other,
}

// Class representing DeviceInfoV2 message
class DeviceInfoV2 {
  DeviceInfoV2({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  factory DeviceInfoV2.fromJson(Map<String, dynamic> json) => DeviceInfoV2(
        deviceId: json['device_id'] as String,
        deviceName: json['device_name'] as String,
        platform: DevicePlatform.values[json['platform'] as int? ?? 0],
      );
  String deviceId;
  String deviceName;
  DevicePlatform platform;

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform.index,
      };
}

// Class representing ConnectRequestV2 message
class ConnectRequestV2 implements Request {
  ConnectRequestV2({required this.clientDevice, required this.primaryAddress});

  factory ConnectRequestV2.fromJson(Map<String, dynamic> json) =>
      ConnectRequestV2(
        clientDevice:
            DeviceInfoV2.fromJson(json['clientDevice'] as Map<String, dynamic>),
        primaryAddress: json['primaryAddress'] as String?,
      );
  DeviceInfoV2 clientDevice;

  // primaryAddress is used for mixpanel identity
  String? primaryAddress;

  @override
  Map<String, dynamic> toJson() => {
        'clientDevice': clientDevice.toJson(),
        'primaryAddress': primaryAddress,
      };
}

// Class representing ConnectReplyV2 message
class ConnectReplyV2 extends ReplyWithOK {
  ConnectReplyV2({required super.ok, this.canvasDevice});

  factory ConnectReplyV2.fromJson(Map<String, dynamic> json) => ConnectReplyV2(
        ok: json['ok'] as bool,
        canvasDevice: json['canvasDevice'] != null
            ? DeviceInfoV2.fromJson(
                json['canvasDevice'] as Map<String, dynamic>,
              )
            : null,
      );
  DeviceInfoV2? canvasDevice;

  @override
  Map<String, dynamic> toJson() => {
        'ok': ok,
        'canvasDevice': canvasDevice?.toJson(),
      };
}

// Class representing DisconnectRequestV2 message
class DisconnectRequestV2 implements Request {
  factory DisconnectRequestV2.fromJson(Map<String, dynamic> json) =>
      DisconnectRequestV2();

  DisconnectRequestV2();

  @override
  Map<String, dynamic> toJson() => {};
}

// Class representing DisconnectReplyV2 message
class DisconnectReplyV2 extends ReplyWithOK {
  DisconnectReplyV2({required super.ok});

  factory DisconnectReplyV2.fromJson(Map<String, dynamic> json) =>
      DisconnectReplyV2(ok: json['ok'] as bool);
}

// Class representing CastAssetToken message
class CastAssetToken implements Request {
  CastAssetToken({required this.id});

  factory CastAssetToken.fromJson(Map<String, dynamic> json) => CastAssetToken(
        id: json['id'] as String,
      );
  String id;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
      };
}

// Class representing CastArtwork message
class CastArtwork implements Request {
  CastArtwork({required this.url, required this.mimetype});

  factory CastArtwork.fromJson(Map<String, dynamic> json) => CastArtwork(
        url: json['url'] as String,
        mimetype: json['mimetype'] as String,
      );
  String url;
  String mimetype;

  @override
  Map<String, dynamic> toJson() => {
        'url': url,
        'mimetype': mimetype,
      };
}

// Class representing PlayArtworkV2 message
class PlayArtworkV2 {
  PlayArtworkV2({
    required this.duration,
    this.token,
    this.artwork,
  });

  factory PlayArtworkV2.fromJson(Map<String, dynamic> json) => PlayArtworkV2(
        token: json['token'] != null
            ? CastAssetToken.fromJson(json['token'] as Map<String, dynamic>)
            : null,
        artwork: json['artwork'] != null
            ? CastArtwork.fromJson(json['artwork'] as Map<String, dynamic>)
            : null,
        duration: json['duration'] as int,
      );
  CastAssetToken? token;
  CastArtwork? artwork;
  int duration;

  Map<String, dynamic> toJson() => {
        'token': token?.toJson(),
        'artwork': artwork?.toJson(),
        'duration': duration,
      };
}

// Class representing CastListArtworkRequest message
class CastListArtworkRequest implements Request {
  CastListArtworkRequest({
    required this.artworks,
    this.startTime,
  });

  factory CastListArtworkRequest.fromJson(Map<String, dynamic> json) =>
      CastListArtworkRequest(
        artworks: List<PlayArtworkV2>.from(
          (json['artworks'] as List)
              .map((x) => PlayArtworkV2.fromJson(x as Map<String, dynamic>)),
        ),
        startTime: json['startTime'] as int?,
      );
  List<PlayArtworkV2> artworks;
  int? startTime;

  @override
  Map<String, dynamic> toJson() => {
        'artworks': artworks.map((artwork) => artwork.toJson()).toList(),
        'startTime': startTime,
      };
}

// Class representing CheckDeviceStatusRequest message
class CheckDeviceStatusRequest implements Request {
  factory CheckDeviceStatusRequest.fromJson(Map<String, dynamic> json) =>
      CheckDeviceStatusRequest();

  CheckDeviceStatusRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

// Class representing CheckDeviceStatusReply message
class CheckDeviceStatusReply extends Reply {
  CheckDeviceStatusReply({
    required this.artworks,
    this.startTime,
    this.connectedDevice,
    this.exhibitionId,
    this.catalogId,
    this.displayKey,
  });

  factory CheckDeviceStatusReply.fromJson(Map<String, dynamic> json) =>
      CheckDeviceStatusReply(
        artworks: json['artworks'] == null
            ? []
            : List<PlayArtworkV2>.from(
                (json['artworks'] as List).map(
                    (x) => PlayArtworkV2.fromJson(x as Map<String, dynamic>)),
              ),
        startTime: json['startTime'] as int?,
        connectedDevice: json['connectedDevice'] != null
            ? DeviceInfoV2.fromJson(
                json['connectedDevice'] as Map<String, dynamic>,
              )
            : null,
        exhibitionId: json['exhibitionId'] as String?,
        catalogId: json['catalogId'] as String?,
        displayKey: json['displayKey'] as String?,
      );
  List<PlayArtworkV2> artworks;
  int? startTime;
  DeviceInfoV2? connectedDevice;
  String? exhibitionId;
  String? catalogId;
  String? displayKey;

  @override
  Map<String, dynamic> toJson() => {
        'artworks': artworks.map((artwork) => artwork.toJson()).toList(),
        'startTime': startTime,
        'connectedDevice': connectedDevice?.toJson(),
        'exhibitionId': exhibitionId,
        'catalogId': catalogId,
        'displayKey': displayKey,
      };
}

// Class representing CastListArtworkReply message
class CastListArtworkReply extends ReplyWithOK {
  CastListArtworkReply({required super.ok});

  factory CastListArtworkReply.fromJson(Map<String, dynamic> json) =>
      CastListArtworkReply(ok: json['ok'] as bool);

  @override
  Map<String, dynamic> toJson() => {
        'ok': ok,
      };
}

// Class representing CancelCastingRequest message
class CancelCastingRequest implements Request {
  factory CancelCastingRequest.fromJson(Map<String, dynamic> json) =>
      CancelCastingRequest();

  CancelCastingRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

// Class representing CancelCastingReply message
class CancelCastingReply extends ReplyWithOK {
  CancelCastingReply({required super.ok});

  factory CancelCastingReply.fromJson(Map<String, dynamic> json) =>
      CancelCastingReply(ok: json['ok'] as bool);
}

// Class representing AppendArtworkToCastingListRequest message
class AppendArtworkToCastingListRequest implements Request {
  AppendArtworkToCastingListRequest({required this.artworks});

  factory AppendArtworkToCastingListRequest.fromJson(
    Map<String, dynamic> json,
  ) =>
      AppendArtworkToCastingListRequest(
        artworks: List<PlayArtworkV2>.from(
          (json['artworks'] as List).map(
            (x) => PlayArtworkV2.fromJson(Map<String, dynamic>.from(x as Map)),
          ),
        ),
      );
  List<PlayArtworkV2> artworks;

  @override
  Map<String, dynamic> toJson() => {
        'artworks': artworks.map((artwork) => artwork.toJson()).toList(),
      };
}

// Class representing AppendArtworkToCastingListReply message
class AppendArtworkToCastingListReply extends ReplyWithOK {
  AppendArtworkToCastingListReply({required super.ok});

  factory AppendArtworkToCastingListReply.fromJson(Map<String, dynamic> json) =>
      AppendArtworkToCastingListReply(ok: json['ok'] as bool);
}

// Class representing PauseCastingRequest message
class PauseCastingRequest implements Request {
  factory PauseCastingRequest.fromJson(Map<String, dynamic> json) =>
      PauseCastingRequest();

  PauseCastingRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

// Class representing PauseCastingReply message
class PauseCastingReply extends ReplyWithOK {
  PauseCastingReply({required super.ok});

  factory PauseCastingReply.fromJson(Map<String, dynamic> json) =>
      PauseCastingReply(ok: json['ok'] as bool);
}

// Class representing ResumeCastingRequest message
class ResumeCastingRequest implements Request {
  ResumeCastingRequest({this.startTime});

  factory ResumeCastingRequest.fromJson(Map<String, dynamic> json) =>
      ResumeCastingRequest(
        startTime: int.tryParse(json['startTime'] as String),
      );
  int? startTime;

  @override
  Map<String, dynamic> toJson() => {
        'startTime': startTime,
      };
}

// Class representing ResumeCastingReply message
class ResumeCastingReply extends ReplyWithOK {
  ResumeCastingReply({required super.ok});

  factory ResumeCastingReply.fromJson(Map<String, dynamic> json) =>
      ResumeCastingReply(ok: json['ok'] as bool);
}

// Class representing NextArtworkRequest message
class NextArtworkRequest implements Request {
  NextArtworkRequest({this.startTime});

  factory NextArtworkRequest.fromJson(Map<String, dynamic> json) =>
      NextArtworkRequest(
        startTime: int.tryParse(json['startTime'] as String),
      );
  int? startTime;

  @override
  Map<String, dynamic> toJson() => {
        'startTime': startTime,
      };
}

// Class representing NextArtworkReply message
class NextArtworkReply extends ReplyWithOK {
  NextArtworkReply({required super.ok});

  factory NextArtworkReply.fromJson(Map<String, dynamic> json) =>
      NextArtworkReply(ok: json['ok'] as bool);
}

// Class representing PreviousArtworkRequest message
class PreviousArtworkRequest implements Request {
  PreviousArtworkRequest({this.startTime});

  factory PreviousArtworkRequest.fromJson(Map<String, dynamic> json) =>
      PreviousArtworkRequest(
        startTime: int.tryParse(json['startTime'] as String),
      );
  int? startTime;

  @override
  Map<String, dynamic> toJson() => {
        'startTime': startTime,
      };
}

// Class representing PreviousArtworkReply message
class PreviousArtworkReply extends ReplyWithOK {
  PreviousArtworkReply({required super.ok});

  factory PreviousArtworkReply.fromJson(Map<String, dynamic> json) =>
      PreviousArtworkReply(ok: json['ok'] as bool);
}

// Class representing UpdateDurationRequest message
class UpdateDurationRequest implements Request {
  factory UpdateDurationRequest.fromJson(Map<String, dynamic> json) =>
      UpdateDurationRequest(
        artworks: List<PlayArtworkV2>.from(
          (json['artworks'] as List).map((x) =>
              PlayArtworkV2.fromJson(Map<String, dynamic>.from(x as Map))),
        ),
      );

  UpdateDurationRequest({required this.artworks});

  List<PlayArtworkV2> artworks;

  @override
  Map<String, dynamic> toJson() => {
        'artworks': artworks.map((artwork) => artwork.toJson()).toList(),
      };
}

// Class representing UpdateDurationReply message
class UpdateDurationReply extends Reply {
  UpdateDurationReply({
    required this.artworks,
    this.startTime,
  });

  factory UpdateDurationReply.fromJson(Map<String, dynamic> json) =>
      UpdateDurationReply(
        startTime: int.tryParse(json['startTime'] as String),
        artworks: List<PlayArtworkV2>.from(
          (json['artworks'] as List).map((x) => PlayArtworkV2.fromJson(
                Map<String, dynamic>.from(x as Map),
              )),
        ),
      );
  int? startTime;
  List<PlayArtworkV2> artworks;

  @override
  Map<String, dynamic> toJson() => {
        'startTime': startTime,
        'artworks': artworks.map((artwork) => artwork.toJson()).toList(),
      };
}

// Enum for ExhibitionCatalog
enum ExhibitionCatalog {
  home,
  curatorNote,
  resource,
  resourceDetail,
  artwork;

  String get metricName {
    switch (this) {
      case ExhibitionCatalog.home:
        return 'home';
      case ExhibitionCatalog.curatorNote:
      case ExhibitionCatalog.resource:
      case ExhibitionCatalog.resourceDetail:
        // resource and resourceDetail are treated as the same metric
        return 'curator_note';
      case ExhibitionCatalog.artwork:
        return 'artworks';
      default:
        return '';
    }
  }
}

// Class representing CastExhibitionRequest message
class CastExhibitionRequest implements Request {
  CastExhibitionRequest({
    required this.catalog,
    this.exhibitionId,
    this.catalogId,
  });

  factory CastExhibitionRequest.fromJson(Map<String, dynamic> json) =>
      CastExhibitionRequest(
        exhibitionId: json['exhibitionId'] as String?,
        catalog: ExhibitionCatalog.values[json['catalog'] as int],
        catalogId: json['catalogId'] as String?,
      );
  String? exhibitionId;
  ExhibitionCatalog catalog;
  String? catalogId;

  @override
  Map<String, dynamic> toJson() => {
        'exhibitionId': exhibitionId,
        'catalog': catalog.index,
        'catalogId': catalogId,
      };
}

// Class representing CastExhibitionReply message
class CastExhibitionReply extends ReplyWithOK {
  CastExhibitionReply({required super.ok});

  factory CastExhibitionReply.fromJson(Map<String, dynamic> json) =>
      CastExhibitionReply(ok: json['ok'] as bool);
}

class KeyboardEventRequest implements Request {
  KeyboardEventRequest({required this.code});

  @override
  factory KeyboardEventRequest.fromJson(Map<String, dynamic> json) =>
      KeyboardEventRequest(code: json['code'] as int);
  final int code;

  @override
  Map<String, dynamic> toJson() => {'code': code};
}

class KeyboardEventReply extends ReplyWithOK {
  KeyboardEventReply({required super.ok});

  factory KeyboardEventReply.fromJson(Map<String, dynamic> json) =>
      KeyboardEventReply(ok: json['ok'] as bool);
}

class RotateRequest implements Request {
  RotateRequest({required this.clockwise});

  factory RotateRequest.fromJson(Map<String, dynamic> json) =>
      RotateRequest(clockwise: json['clockwise'] as bool);
  final bool clockwise;

  @override
  Map<String, dynamic> toJson() => {'clockwise': clockwise};
}

class RotateReply extends Reply {
  RotateReply({required this.degree});

  factory RotateReply.fromJson(Map<String, dynamic> json) =>
      RotateReply(degree: json['degree'] as int);
  final int degree;

  @override
  Map<String, dynamic> toJson() => {'degree': degree};
}

class TapGestureRequest implements Request {
  @override
  factory TapGestureRequest.fromJson(Map<String, dynamic> json) =>
      TapGestureRequest();

  TapGestureRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

class GestureReply extends ReplyWithOK {
  GestureReply({required super.ok});

  factory GestureReply.fromJson(Map<String, dynamic> json) =>
      GestureReply(ok: json['ok'] as bool);
}

class DragGestureRequest implements Request {
  DragGestureRequest({required this.cursorOffsets});

  @override
  factory DragGestureRequest.fromJson(Map<String, dynamic> json) =>
      DragGestureRequest(
        cursorOffsets: List<CursorOffset>.from(
          (json['cursorOffsets'] as List)
              .map((x) => CursorOffset.fromJson(x as Map<String, dynamic>)),
        ),
      );
  List<CursorOffset> cursorOffsets;

  @override
  Map<String, dynamic> toJson() => {
        'cursorOffsets':
            cursorOffsets.map((cursorOffset) => cursorOffset.toJson()).toList(),
      };
}

class CursorOffset {
  CursorOffset({
    required this.dx,
    required this.dy,
    required this.coefficientX,
    required this.coefficientY,
  });

  factory CursorOffset.fromJson(Map<String, dynamic> json) => CursorOffset(
        dx: json['dx'] as double,
        dy: json['dy'] as double,
        coefficientX: json['coefficientX'] as double,
        coefficientY: json['coefficientY'] as double,
      );
  final double dx;
  final double dy;
  final double coefficientX;
  final double coefficientY;

  Map<String, dynamic> toJson() => {
        'dx': dx,
        'dy': dy,
        'coefficientX': coefficientX,
        'coefficientY': coefficientY,
      };
}

class GetCursorOffsetRequest implements Request {
  factory GetCursorOffsetRequest.fromJson(Map<String, dynamic> json) =>
      GetCursorOffsetRequest();

  GetCursorOffsetRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

class GetCursorOffsetReply extends Reply {
  GetCursorOffsetReply({
    required this.cursorOffset,
  });

  factory GetCursorOffsetReply.fromJson(Map<String, dynamic> json) =>
      GetCursorOffsetReply(
        cursorOffset: CursorOffset.fromJson(
            Map<String, dynamic>.from(json['cursorOffset'] as Map)),
      );
  final CursorOffset cursorOffset;

  @override
  Map<String, dynamic> toJson() => {
        'cursorOffset': cursorOffset.toJson(),
      };
}

class SetCursorOffsetRequest implements Request {
  SetCursorOffsetRequest({required this.cursorOffset});

  factory SetCursorOffsetRequest.fromJson(Map<String, dynamic> json) =>
      SetCursorOffsetRequest(
        cursorOffset: CursorOffset.fromJson(
            Map<String, dynamic>.from(json['cursorOffset'] as Map)),
      );
  final CursorOffset cursorOffset;

  @override
  Map<String, dynamic> toJson() => {
        'cursorOffset': cursorOffset.toJson(),
      };
}

class SetCursorOffsetReply extends EmptyReply {
  SetCursorOffsetReply();

  factory SetCursorOffsetReply.fromJson(Map<String, dynamic> json) =>
      SetCursorOffsetReply();
}

class EmptyRequest implements Request {
  factory EmptyRequest.fromJson(Map<String, dynamic> json) => EmptyRequest();

  EmptyRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

class EmptyReply extends Reply {
  EmptyReply();

  factory EmptyReply.fromJson(Map<String, dynamic> json) => EmptyReply();

  @override
  Map<String, dynamic> toJson() => {};
}

class CastDailyWorkRequest extends EmptyRequest {
  CastDailyWorkRequest();

  // fromJson method
  factory CastDailyWorkRequest.fromJson(Map<String, dynamic> json) =>
      CastDailyWorkRequest();

  static String get displayKey => 'daily_work';
}

class CastDailyWorkReply extends ReplyWithOK {
  CastDailyWorkReply({required super.ok});

  factory CastDailyWorkReply.fromJson(Map<String, dynamic> json) =>
      CastDailyWorkReply(ok: json['ok'] as bool);

  @override
  Map<String, dynamic> toJson() => {
        'ok': ok,
      };
}
