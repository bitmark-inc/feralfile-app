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
  moveToArtwork,
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
      case 'moveToArtwork':
        return CastCommand.moveToArtwork;
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
      case const (MoveToArtworkRequest):
        return CastCommand.moveToArtwork;
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
  final CastCommand command;
  final Request request;

  RequestBody(this.request) : command = CastCommand.fromRequest(request);

  Map<String, dynamic> toJson() => {
        'command': command.toString().split('.').last,
        'request': request.toJson(),
      };

  // fromJson method
  factory RequestBody.fromJson(Map<String, dynamic> json) {
    final commandString = json['command'] as String;
    final command = CastCommand.fromString(commandString);

    Request request;
    switch (command) {
      case CastCommand.checkStatus:
        request = CheckDeviceStatusRequest.fromJson(json['request']);
      case CastCommand.castListArtwork:
        request = CastListArtworkRequest.fromJson(json['request']);
      case CastCommand.castDaily:
        request = CastDailyWorkRequest.fromJson(json['request']);
      case CastCommand.cancelCasting:
        request = CancelCastingRequest.fromJson(json['request']);
      case CastCommand.appendArtworkToCastingList:
        request = AppendArtworkToCastingListRequest.fromJson(json['request']);
      case CastCommand.pauseCasting:
        request = PauseCastingRequest.fromJson(json['request']);
      case CastCommand.resumeCasting:
        request = ResumeCastingRequest.fromJson(json['request']);
      case CastCommand.nextArtwork:
        request = NextArtworkRequest.fromJson(json['request']);
      case CastCommand.previousArtwork:
        request = PreviousArtworkRequest.fromJson(json['request']);
      case CastCommand.moveToArtwork:
        request = MoveToArtworkRequest.fromJson(json['request']);
      case CastCommand.updateDuration:
        request = UpdateDurationRequest.fromJson(json['request']);
      case CastCommand.castExhibition:
        request = CastExhibitionRequest.fromJson(json['request']);
      case CastCommand.connect:
        request = ConnectRequestV2.fromJson(json['request']);
      case CastCommand.disconnect:
        request = DisconnectRequestV2.fromJson(json['request']);
      default:
        throw ArgumentError('Unknown command: $commandString');
    }

    return RequestBody(request);
  }
}

class Reply {
  Reply();

  Map<String, dynamic> toJson() => {};

  factory Reply.fromJson(Map<String, dynamic> json) => Reply();
}

class ReplyWithOK extends Reply {
  final bool ok;

  ReplyWithOK({required this.ok});

  @override
  Map<String, dynamic> toJson() => {
        'ok': ok,
      };

  factory ReplyWithOK.fromJson(Map<String, dynamic> json) => ReplyWithOK(
        ok: json['ok'],
      );
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
  String deviceId;
  String deviceName;
  DevicePlatform platform;

  DeviceInfoV2({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  factory DeviceInfoV2.fromJson(Map<String, dynamic> json) => DeviceInfoV2(
        deviceId: json['device_id'],
        deviceName: json['device_name'],
        platform: DevicePlatform.values[json['platform'] ?? 0],
      );

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform.index,
      };
}

// Class representing ConnectRequestV2 message
class ConnectRequestV2 implements Request {
  DeviceInfoV2 clientDevice;

  // primaryAddress is used for mixpanel identity
  String? primaryAddress;

  ConnectRequestV2({required this.clientDevice, required this.primaryAddress});

  factory ConnectRequestV2.fromJson(Map<String, dynamic> json) =>
      ConnectRequestV2(
        clientDevice: DeviceInfoV2.fromJson(json['clientDevice']),
        primaryAddress: json['primaryAddress'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'clientDevice': clientDevice.toJson(),
        'primaryAddress': primaryAddress,
      };
}

// Class representing ConnectReplyV2 message
class ConnectReplyV2 extends ReplyWithOK {
  DeviceInfoV2? canvasDevice;

  ConnectReplyV2({required super.ok, this.canvasDevice});

  @override
  Map<String, dynamic> toJson() => {
        'ok': ok,
        'canvasDevice': canvasDevice?.toJson(),
      };

  factory ConnectReplyV2.fromJson(Map<String, dynamic> json) => ConnectReplyV2(
        ok: json['ok'],
        canvasDevice: json['canvasDevice'] != null
            ? DeviceInfoV2.fromJson(json['canvasDevice'])
            : null,
      );
}

// Class representing DisconnectRequestV2 message
class DisconnectRequestV2 implements Request {
  DisconnectRequestV2();

  @override
  Map<String, dynamic> toJson() => {};

  factory DisconnectRequestV2.fromJson(Map<String, dynamic> json) =>
      DisconnectRequestV2();
}

// Class representing DisconnectReplyV2 message
class DisconnectReplyV2 extends ReplyWithOK {
  DisconnectReplyV2({required super.ok});

  factory DisconnectReplyV2.fromJson(Map<String, dynamic> json) =>
      DisconnectReplyV2(ok: json['ok']);
}

// Class representing CastAssetToken message
class CastAssetToken implements Request {
  String id;

  CastAssetToken({required this.id});

  factory CastAssetToken.fromJson(Map<String, dynamic> json) => CastAssetToken(
        id: json['id'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
      };
}

// Class representing CastArtwork message
class CastArtwork implements Request {
  String url;
  String mimetype;

  CastArtwork({required this.url, required this.mimetype});

  factory CastArtwork.fromJson(Map<String, dynamic> json) => CastArtwork(
        url: json['url'],
        mimetype: json['mimetype'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'url': url,
        'mimetype': mimetype,
      };
}

// Class representing PlayArtworkV2 message
class PlayArtworkV2 {
  CastAssetToken? token;
  CastArtwork? artwork;
  int duration;

  PlayArtworkV2({
    required this.duration,
    this.token,
    this.artwork,
  });

  factory PlayArtworkV2.fromJson(Map<String, dynamic> json) => PlayArtworkV2(
        token: json['token'] != null
            ? CastAssetToken.fromJson(json['token'])
            : null,
        artwork: json['artwork'] != null
            ? CastArtwork.fromJson(json['artwork'])
            : null,
        duration: json['duration'],
      );

  Map<String, dynamic> toJson() => {
        'token': token?.toJson(),
        'artwork': artwork?.toJson(),
        'duration': duration,
      };
}

// Class representing CastListArtworkRequest message
class CastListArtworkRequest implements Request {
  List<PlayArtworkV2> artworks;
  int? startTime;

  CastListArtworkRequest({
    required this.artworks,
    this.startTime,
  });

  factory CastListArtworkRequest.fromJson(Map<String, dynamic> json) =>
      CastListArtworkRequest(
        artworks: List<PlayArtworkV2>.from(
            json['artworks'].map((x) => PlayArtworkV2.fromJson(x))),
        startTime: json['startTime'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'artworks': artworks.map((artwork) => artwork.toJson()).toList(),
        'startTime': startTime,
      };
}

// Class representing CheckDeviceStatusRequest message
class CheckDeviceStatusRequest implements Request {
  CheckDeviceStatusRequest();

  @override
  Map<String, dynamic> toJson() => {};

  factory CheckDeviceStatusRequest.fromJson(Map<String, dynamic> json) =>
      CheckDeviceStatusRequest();
}

// Class representing CheckDeviceStatusReply message
class CheckDeviceStatusReply extends Reply {
  List<PlayArtworkV2> artworks;
  int? startTime;
  DeviceInfoV2? connectedDevice;
  String? exhibitionId;
  String? catalogId;
  String? displayKey;

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
                json['artworks'].map((x) => PlayArtworkV2.fromJson(x))),
        startTime: json['startTime'],
        connectedDevice: json['connectedDevice'] != null
            ? DeviceInfoV2.fromJson(json['connectedDevice'])
            : null,
        exhibitionId: json['exhibitionId'],
        catalogId: json['catalogId'],
        displayKey: json['displayKey'],
      );

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
      CastListArtworkReply(ok: json['ok']);

  @override
  Map<String, dynamic> toJson() => {
        'ok': ok,
      };
}

// Class representing CancelCastingRequest message
class CancelCastingRequest implements Request {
  CancelCastingRequest();

  @override
  Map<String, dynamic> toJson() => {};

  factory CancelCastingRequest.fromJson(Map<String, dynamic> json) =>
      CancelCastingRequest();
}

// Class representing CancelCastingReply message
class CancelCastingReply extends ReplyWithOK {
  CancelCastingReply({required super.ok});

  factory CancelCastingReply.fromJson(Map<String, dynamic> json) =>
      CancelCastingReply(ok: json['ok']);
}

// Class representing AppendArtworkToCastingListRequest message
class AppendArtworkToCastingListRequest implements Request {
  List<PlayArtworkV2> artworks;

  AppendArtworkToCastingListRequest({required this.artworks});

  factory AppendArtworkToCastingListRequest.fromJson(
          Map<String, dynamic> json) =>
      AppendArtworkToCastingListRequest(
        artworks: List<PlayArtworkV2>.from(
            json['artworks'].map((x) => PlayArtworkV2.fromJson(x))),
      );

  @override
  Map<String, dynamic> toJson() => {
        'artworks': artworks.map((artwork) => artwork.toJson()).toList(),
      };
}

// Class representing AppendArtworkToCastingListReply message
class AppendArtworkToCastingListReply extends ReplyWithOK {
  AppendArtworkToCastingListReply({required super.ok});

  factory AppendArtworkToCastingListReply.fromJson(Map<String, dynamic> json) =>
      AppendArtworkToCastingListReply(ok: json['ok']);
}

// Class representing PauseCastingRequest message
class PauseCastingRequest implements Request {
  PauseCastingRequest();

  @override
  Map<String, dynamic> toJson() => {};

  factory PauseCastingRequest.fromJson(Map<String, dynamic> json) =>
      PauseCastingRequest();
}

// Class representing PauseCastingReply message
class PauseCastingReply extends ReplyWithOK {
  PauseCastingReply({required super.ok});

  factory PauseCastingReply.fromJson(Map<String, dynamic> json) =>
      PauseCastingReply(ok: json['ok']);
}

// Class representing ResumeCastingRequest message
class ResumeCastingRequest implements Request {
  int? startTime;

  ResumeCastingRequest({this.startTime});

  factory ResumeCastingRequest.fromJson(Map<String, dynamic> json) =>
      ResumeCastingRequest(
        startTime: json['startTime'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'startTime': startTime,
      };
}

// Class representing ResumeCastingReply message
class ResumeCastingReply extends ReplyWithOK {
  ResumeCastingReply({required super.ok});

  factory ResumeCastingReply.fromJson(Map<String, dynamic> json) =>
      ResumeCastingReply(ok: json['ok']);
}

// Class representing NextArtworkRequest message
class NextArtworkRequest implements Request {
  int? startTime;

  NextArtworkRequest({this.startTime});

  factory NextArtworkRequest.fromJson(Map<String, dynamic> json) =>
      NextArtworkRequest(
        startTime: json['startTime'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'startTime': startTime,
      };
}

// Class representing NextArtworkReply message
class NextArtworkReply extends ReplyWithOK {
  NextArtworkReply({required super.ok});

  factory NextArtworkReply.fromJson(Map<String, dynamic> json) =>
      NextArtworkReply(ok: json['ok']);
}

// Class representing PreviousArtworkRequest message
class PreviousArtworkRequest implements Request {
  int? startTime;

  PreviousArtworkRequest({this.startTime});

  factory PreviousArtworkRequest.fromJson(Map<String, dynamic> json) =>
      PreviousArtworkRequest(
        startTime: json['startTime'],
      );

  @override
  Map<String, dynamic> toJson() => {
        'startTime': startTime,
      };
}

// Class representing PreviousArtworkReply message
class PreviousArtworkReply extends ReplyWithOK {
  PreviousArtworkReply({required super.ok});

  factory PreviousArtworkReply.fromJson(Map<String, dynamic> json) =>
      PreviousArtworkReply(ok: json['ok']);
}

// Class representing MoveToArtworkRequest message
class MoveToArtworkRequest implements Request {
  PlayArtworkV2 artwork;

  MoveToArtworkRequest({required this.artwork});

  factory MoveToArtworkRequest.fromJson(Map<String, dynamic> json) =>
      MoveToArtworkRequest(
        artwork: PlayArtworkV2.fromJson(json['artwork']),
      );

  @override
  Map<String, dynamic> toJson() => {
        'artwork': artwork.toJson(),
      };
}

// Class representing MoveToArtworkReply message
class MoveToArtworkReply extends ReplyWithOK {
  MoveToArtworkReply({required super.ok});

  factory MoveToArtworkReply.fromJson(Map<String, dynamic> json) =>
      MoveToArtworkReply(ok: json['ok']);
}

// Class representing UpdateDurationRequest message
class UpdateDurationRequest implements Request {
  List<PlayArtworkV2> artworks;

  UpdateDurationRequest({required this.artworks});

  factory UpdateDurationRequest.fromJson(Map<String, dynamic> json) =>
      UpdateDurationRequest(
        artworks: List<PlayArtworkV2>.from(
            json['artworks'].map((x) => PlayArtworkV2.fromJson(x))),
      );

  @override
  Map<String, dynamic> toJson() => {
        'artworks': artworks.map((artwork) => artwork.toJson()).toList(),
      };
}

// Class representing UpdateDurationReply message
class UpdateDurationReply extends Reply {
  int? startTime;
  List<PlayArtworkV2> artworks;

  UpdateDurationReply({
    required this.artworks,
    this.startTime,
  });

  factory UpdateDurationReply.fromJson(Map<String, dynamic> json) =>
      UpdateDurationReply(
        startTime: json['startTime'],
        artworks: List<PlayArtworkV2>.from(
            json['artworks'].map((x) => PlayArtworkV2.fromJson(x))),
      );

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
  String? exhibitionId;
  ExhibitionCatalog catalog;
  String? catalogId;

  CastExhibitionRequest({
    required this.catalog,
    this.exhibitionId,
    this.catalogId,
  });

  factory CastExhibitionRequest.fromJson(Map<String, dynamic> json) =>
      CastExhibitionRequest(
        exhibitionId: json['exhibitionId'],
        catalog: ExhibitionCatalog.values[json['catalog']],
        catalogId: json['catalogId'],
      );

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
      CastExhibitionReply(ok: json['ok']);
}

class KeyboardEventRequest implements Request {
  final int code;

  KeyboardEventRequest({required this.code});

  @override
  Map<String, dynamic> toJson() => {'code': code};

  @override
  factory KeyboardEventRequest.fromJson(Map<String, dynamic> json) =>
      KeyboardEventRequest(code: json['code']);
}

class KeyboardEventReply extends ReplyWithOK {
  KeyboardEventReply({required super.ok});

  factory KeyboardEventReply.fromJson(Map<String, dynamic> json) =>
      KeyboardEventReply(ok: json['ok']);
}

class RotateRequest implements Request {
  final bool clockwise;

  RotateRequest({required this.clockwise});

  @override
  Map<String, dynamic> toJson() => {'clockwise': clockwise};

  factory RotateRequest.fromJson(Map<String, dynamic> json) =>
      RotateRequest(clockwise: json['clockwise']);
}

class RotateReply extends Reply {
  final int degree;

  RotateReply({required this.degree});

  @override
  Map<String, dynamic> toJson() => {'degree': degree};

  factory RotateReply.fromJson(Map<String, dynamic> json) =>
      RotateReply(degree: json['degree']);
}

class TapGestureRequest implements Request {
  TapGestureRequest();

  @override
  Map<String, dynamic> toJson() => {};

  @override
  factory TapGestureRequest.fromJson(Map<String, dynamic> json) =>
      TapGestureRequest();
}

class GestureReply extends ReplyWithOK {
  GestureReply({required super.ok});

  factory GestureReply.fromJson(Map<String, dynamic> json) =>
      GestureReply(ok: json['ok']);
}

class DragGestureRequest implements Request {
  List<CursorOffset> cursorOffsets;

  DragGestureRequest({required this.cursorOffsets});

  @override
  Map<String, dynamic> toJson() => {
        'cursorOffsets':
            cursorOffsets.map((cursorOffset) => cursorOffset.toJson()).toList(),
      };

  @override
  factory DragGestureRequest.fromJson(Map<String, dynamic> json) =>
      DragGestureRequest(
        cursorOffsets: List<CursorOffset>.from(
            json['cursorOffsets'].map((x) => CursorOffset.fromJson(x))),
      );
}

class CursorOffset {
  final double dx;
  final double dy;
  final double coefficientX;
  final double coefficientY;

  CursorOffset({
    required this.dx,
    required this.dy,
    required this.coefficientX,
    required this.coefficientY,
  });

  Map<String, dynamic> toJson() => {
        'dx': dx,
        'dy': dy,
        'coefficientX': coefficientX,
        'coefficientY': coefficientY,
      };

  factory CursorOffset.fromJson(Map<String, dynamic> json) => CursorOffset(
        dx: json['dx'],
        dy: json['dy'],
        coefficientX: json['coefficientX'],
        coefficientY: json['coefficientY'],
      );
}

class GetCursorOffsetRequest implements Request {
  GetCursorOffsetRequest();

  @override
  Map<String, dynamic> toJson() => {};

  factory GetCursorOffsetRequest.fromJson(Map<String, dynamic> json) =>
      GetCursorOffsetRequest();
}

class GetCursorOffsetReply extends Reply {
  final CursorOffset cursorOffset;

  GetCursorOffsetReply({
    required this.cursorOffset,
  });

  @override
  Map<String, dynamic> toJson() => {
        'cursorOffset': cursorOffset.toJson(),
      };

  factory GetCursorOffsetReply.fromJson(Map<String, dynamic> json) =>
      GetCursorOffsetReply(
        cursorOffset: CursorOffset.fromJson(json['cursorOffset']),
      );
}

class SetCursorOffsetRequest implements Request {
  final CursorOffset cursorOffset;

  SetCursorOffsetRequest({required this.cursorOffset});

  @override
  Map<String, dynamic> toJson() => {
        'cursorOffset': cursorOffset.toJson(),
      };

  factory SetCursorOffsetRequest.fromJson(Map<String, dynamic> json) =>
      SetCursorOffsetRequest(
        cursorOffset: CursorOffset.fromJson(json['cursorOffset']),
      );
}

class SetCursorOffsetReply extends EmptyReply {
  SetCursorOffsetReply();

  factory SetCursorOffsetReply.fromJson(Map<String, dynamic> json) =>
      SetCursorOffsetReply();
}

class EmptyRequest implements Request {
  EmptyRequest();

  @override
  Map<String, dynamic> toJson() => {};

  factory EmptyRequest.fromJson(Map<String, dynamic> json) => EmptyRequest();
}

class EmptyReply extends Reply {
  EmptyReply();

  factory EmptyReply.fromJson(Map<String, dynamic> json) => EmptyReply();

  @override
  Map<String, dynamic> toJson() => {};
}

class CastDailyWorkRequest extends EmptyRequest {
  static String get displayKey => 'daily_work';

  CastDailyWorkRequest();

  // fromJson method
  factory CastDailyWorkRequest.fromJson(Map<String, dynamic> json) =>
      CastDailyWorkRequest();
}

class CastDailyWorkReply extends ReplyWithOK {
  CastDailyWorkReply({required super.ok});

  factory CastDailyWorkReply.fromJson(Map<String, dynamic> json) =>
      CastDailyWorkReply(ok: json['ok']);

  @override
  Map<String, dynamic> toJson() => {
        'ok': ok,
      };
}
