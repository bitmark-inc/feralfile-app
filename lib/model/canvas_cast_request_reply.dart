// Import statements for Flutter

// ignore_for_file: avoid_unused_constructor_parameters

import 'package:autonomy_flutter/model/bluetooth_device_status.dart';
import 'package:autonomy_flutter/screen/device_setting/device_config.dart';
import 'package:flutter/material.dart';

enum CastCommand {
  checkStatus,
  castListArtwork,
  pauseCasting,
  resumeCasting,
  nextArtwork,
  previousArtwork,
  updateDuration,
  castExhibition,
  connect,
  disconnect,
  sendKeyboardEvent,
  rotate,
  sendLog,
  getVersion,
  updateOrientation,
  getBluetoothDeviceStatus,
  updateArtFraming,
  setTimezone,
  updateToLatestVersion,
  tapGesture,
  dragGesture,
  enableMetricsStreaming,
  disableMetricsStreaming,
  castDaily;

  static CastCommand fromString(String command) {
    switch (command) {
      case 'checkStatus':
        return CastCommand.checkStatus;
      case 'castListArtwork':
        return CastCommand.castListArtwork;
      case 'castDaily':
        return CastCommand.castDaily;
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
      case 'sendKeyboardEvent':
        return CastCommand.sendKeyboardEvent;
      case 'rotate':
        return CastCommand.rotate;
      case 'sendLog':
        return CastCommand.sendLog;
      case 'getVersion':
        return CastCommand.getVersion;
      case 'updateOrientation':
        return CastCommand.updateOrientation;
      case 'getBluetoothDeviceStatus':
        return CastCommand.getBluetoothDeviceStatus;
      case 'updateArtFraming':
        return CastCommand.updateArtFraming;
      case 'setTimezone':
        return CastCommand.setTimezone;
      case 'updateToLatestVersion':
        return CastCommand.updateToLatestVersion;
      case 'tapGesture':
        return CastCommand.tapGesture;
      case 'dragGesture':
        return CastCommand.dragGesture;
      case 'enableMetricsStreaming':
        return CastCommand.enableMetricsStreaming;
      case 'disableMetricsStreaming':
        return CastCommand.disableMetricsStreaming;
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
      case const (KeyboardEventRequest):
        return CastCommand.sendKeyboardEvent;
      case const (RotateRequest):
        return CastCommand.rotate;
      case const (GetVersionRequest):
        return CastCommand.getVersion;
      case const (UpdateOrientationRequest):
        return CastCommand.updateOrientation;
      case const (GetBluetoothDeviceStatusRequest):
        return CastCommand.getBluetoothDeviceStatus;
      case const (UpdateArtFramingRequest):
        return CastCommand.updateArtFraming;
      case const (SetTimezoneRequest):
        return CastCommand.setTimezone;
      case const (UpdateToLatestVersionRequest):
        return CastCommand.updateToLatestVersion;
      case const (SendLogRequest):
        return CastCommand.sendLog;
      case const (TapGestureRequest):
        return CastCommand.tapGesture;
      case const (DragGestureRequest):
        return CastCommand.dragGesture;
      case const (EnableMetricsStreamingRequest):
        return CastCommand.enableMetricsStreaming;
      case const (DisableMetricsStreamingRequest):
        return CastCommand.disableMetricsStreaming;
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
      case CastCommand.sendKeyboardEvent:
        request = KeyboardEventRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.rotate:
        request = RotateRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.updateArtFraming:
        request = UpdateArtFramingRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.tapGesture:
        request = TapGestureRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.dragGesture:
        request = DragGestureRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.sendLog:
        request = SendLogRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.enableMetricsStreaming:
        request = EnableMetricsStreamingRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
      case CastCommand.disableMetricsStreaming:
        request = DisableMetricsStreamingRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        );
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
  Reply();

  factory Reply.fromJson(Map<String, dynamic> json) => Reply();

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
  DisconnectRequestV2();

  factory DisconnectRequestV2.fromJson(Map<String, dynamic> json) =>
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
        if (token != null) 'token': token?.toJson(),
        if (artwork != null) 'artwork': artwork!.toJson(),
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
  CheckDeviceStatusRequest();

  factory CheckDeviceStatusRequest.fromJson(Map<String, dynamic> json) =>
      CheckDeviceStatusRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

// Class representing CheckDeviceStatusReply message
class CheckDeviceStatusReply extends Reply {
  CheckDeviceStatusReply({
    required this.artworks,
    this.index,
    bool? isPaused,
    this.connectedDevice,
    this.exhibitionId,
    this.catalogId,
    this.catalog,
    this.displayKey,
  }) : isPaused = isPaused ?? false;

  factory CheckDeviceStatusReply.fromJson(Map<String, dynamic> json) =>
      CheckDeviceStatusReply(
        artworks: json['artworks'] == null
            ? []
            : List<PlayArtworkV2>.from(
                (json['artworks'] as List).map(
                  (x) => PlayArtworkV2.fromJson(x as Map<String, dynamic>),
                ),
              ),
        index: json['index'] as int?,
        isPaused: json['isPaused'] as bool?,
        connectedDevice: json['connectedDevice'] != null
            ? DeviceInfoV2.fromJson(
                json['connectedDevice'] as Map<String, dynamic>,
              )
            : null,
        exhibitionId: json['exhibitionId'] as String?,
        catalogId: json['catalogId'] as String?,
        catalog: json['catalog'] == null
            ? null
            : ExhibitionCatalog.values[json['catalog'] as int],
        displayKey: json['displayKey'] as String?,
      );

  int? get currentArtworkIndex {
    if (artworks.isEmpty) {
      return null;
    }
    return index;
  }

  List<PlayArtworkV2> artworks;
  int? index;
  bool isPaused;
  DeviceInfoV2? connectedDevice;
  String? exhibitionId;
  String? catalogId;
  ExhibitionCatalog? catalog;
  String? displayKey;

  @override
  Map<String, dynamic> toJson() => {
        'artworks': artworks.map((artwork) => artwork.toJson()).toList(),
        'index': index,
        'isPaused': isPaused,
        'connectedDevice': connectedDevice?.toJson(),
        'exhibitionId': exhibitionId,
        'catalogId': catalogId,
        'catalog': catalog?.index,
        'displayKey': displayKey,
      };

  // copyWith method
  CheckDeviceStatusReply copyWith({
    List<PlayArtworkV2>? artworks,
    int? index,
    bool? isPaused,
    DeviceInfoV2? connectedDevice,
    String? exhibitionId,
    String? catalogId,
    ExhibitionCatalog? catalog,
    String? displayKey,
  }) {
    return CheckDeviceStatusReply(
      artworks: artworks ?? this.artworks,
      index: index ?? this.index,
      isPaused: isPaused ?? this.isPaused,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      exhibitionId: exhibitionId ?? this.exhibitionId,
      catalogId: catalogId ?? this.catalogId,
      catalog: catalog ?? this.catalog,
      displayKey: displayKey ?? this.displayKey,
    );
  }
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

// Class representing PauseCastingRequest message
class PauseCastingRequest implements Request {
  PauseCastingRequest();

  factory PauseCastingRequest.fromJson(Map<String, dynamic> json) =>
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
  UpdateDurationRequest({required this.artworks});

  factory UpdateDurationRequest.fromJson(Map<String, dynamic> json) =>
      UpdateDurationRequest(
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
          (json['artworks'] as List).map(
            (x) => PlayArtworkV2.fromJson(
              Map<String, dynamic>.from(x as Map),
            ),
          ),
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

class SendLogRequest implements Request {
  SendLogRequest({required this.userId, required this.title});

  factory SendLogRequest.fromJson(Map<String, dynamic> json) => SendLogRequest(
        userId: json['userId'] as String,
        title: json['title'] as String?,
      );

  final String userId;
  final String? title;

  @override
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'title': title,
      };
}

class SendLogReply extends ReplyWithOK {
  SendLogReply({required super.ok});

  factory SendLogReply.fromJson(Map<String, dynamic> json) =>
      SendLogReply(ok: json['ok'] as bool);

  @override
  Map<String, dynamic> toJson() => {
        'ok': ok,
      };
}

class GetVersionRequest implements Request {
  GetVersionRequest();

  factory GetVersionRequest.fromJson(Map<String, dynamic> json) =>
      GetVersionRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

class GetVersionReply extends Reply {
  GetVersionReply({required this.version});

  factory GetVersionReply.fromJson(Map<String, dynamic> json) =>
      GetVersionReply(version: json['version'] as String);
  final String version;

  @override
  Map<String, dynamic> toJson() => {
        'version': version,
      };
}

extension OrientationExtension on Orientation {
  String get name {
    switch (this) {
      case Orientation.portrait:
        return 'portrait';
      case Orientation.landscape:
        return 'landscape';
    }
  }

  static Orientation fromString(String orientation) {
    switch (orientation) {
      case 'portrait':
        return Orientation.portrait;
      case 'landscape':
        return Orientation.landscape;
      default:
        throw ArgumentError('Unknown orientation: $orientation');
    }
  }
}

class UpdateOrientationRequest implements Request {
  UpdateOrientationRequest({required this.orientation});

  factory UpdateOrientationRequest.fromJson(Map<String, dynamic> json) =>
      UpdateOrientationRequest(
        orientation:
            ScreenOrientation.fromString(json['orientation'] as String),
      );
  final ScreenOrientation orientation;

  @override
  Map<String, dynamic> toJson() => {
        'orientation': orientation.name,
      };
}

class UpdateOrientationReply extends Reply {
  UpdateOrientationReply();

  factory UpdateOrientationReply.fromJson(Map<String, dynamic> json) =>
      UpdateOrientationReply();
}

class GetBluetoothDeviceStatusRequest implements Request {
  GetBluetoothDeviceStatusRequest();

  factory GetBluetoothDeviceStatusRequest.fromJson(Map<String, dynamic> json) =>
      GetBluetoothDeviceStatusRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

class GetBluetoothDeviceStatusReply extends Reply {
  GetBluetoothDeviceStatusReply({required this.deviceStatus});

  factory GetBluetoothDeviceStatusReply.fromJson(Map<String, dynamic> json) =>
      GetBluetoothDeviceStatusReply(
        deviceStatus: BluetoothDeviceStatus.fromJson(
          json,
        ),
      );
  final BluetoothDeviceStatus deviceStatus;

  @override
  Map<String, dynamic> toJson() => deviceStatus.toJson();
}

class SetTimezoneRequest implements Request {
  SetTimezoneRequest({required this.timezone});

  factory SetTimezoneRequest.fromJson(Map<String, dynamic> json) =>
      SetTimezoneRequest(
        timezone: json['timeZone'] as String,
      );
  final String timezone;

  @override
  Map<String, dynamic> toJson() => {
        'timezone': timezone,
      };
}

class SetTimezoneReply extends Reply {
  SetTimezoneReply();

  factory SetTimezoneReply.fromJson(Map<String, dynamic> json) =>
      SetTimezoneReply();
}

class UpdateToLatestVersionRequest implements Request {
  UpdateToLatestVersionRequest();

  factory UpdateToLatestVersionRequest.fromJson(Map<String, dynamic> json) =>
      UpdateToLatestVersionRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

class UpdateToLatestVersionReply extends Reply {
  UpdateToLatestVersionReply();

  factory UpdateToLatestVersionReply.fromJson(Map<String, dynamic> json) =>
      UpdateToLatestVersionReply();
}

enum ArtFraming {
  fitToScreen,
  cropToFill;

  int get value {
    switch (this) {
      case ArtFraming.fitToScreen:
        return 0;
      case ArtFraming.cropToFill:
        return 1;
    }
  }

  static ArtFraming fromValue(int value) {
    switch (value) {
      case 0:
        return ArtFraming.fitToScreen;
      case 1:
        return ArtFraming.cropToFill;
      default:
        throw ArgumentError('Unknown value: $value');
    }
  }
}

class UpdateArtFramingRequest implements Request {
  UpdateArtFramingRequest({required this.artFraming});

  factory UpdateArtFramingRequest.fromJson(Map<String, dynamic> json) =>
      UpdateArtFramingRequest(
        artFraming: ArtFraming.fromValue(json['frameConfig'] as int),
      );
  final ArtFraming artFraming;

  @override
  Map<String, dynamic> toJson() => {
        'frameConfig': artFraming.value,
      };
}

class UpdateArtFramingReply extends Reply {
  UpdateArtFramingReply();

  factory UpdateArtFramingReply.fromJson(Map<String, dynamic> json) =>
      UpdateArtFramingReply();
}

class TapGestureRequest implements Request {
  TapGestureRequest();

  @override
  factory TapGestureRequest.fromJson(Map<String, dynamic> json) =>
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
        'dx': // round to 2 decimal places
            double.parse(dx.toStringAsFixed(2)),
        'dy': // round to 2 decimal places
            double.parse(dy.toStringAsFixed(2)),
        'coefficientX': double.parse(coefficientX.toStringAsFixed(6)),
        'coefficientY': double.parse(coefficientY.toStringAsFixed(6)),
      };
}

class EmptyRequest implements Request {
  EmptyRequest();

  factory EmptyRequest.fromJson(Map<String, dynamic> json) => EmptyRequest();

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

// Class representing EnableMetricsStreamingRequest message
class EnableMetricsStreamingRequest implements Request {
  EnableMetricsStreamingRequest();

  factory EnableMetricsStreamingRequest.fromJson(Map<String, dynamic> json) =>
      EnableMetricsStreamingRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

// Class representing EnableMetricsStreamingReply message
class EnableMetricsStreamingReply extends ReplyWithOK {
  EnableMetricsStreamingReply({required super.ok});

  factory EnableMetricsStreamingReply.fromJson(Map<String, dynamic> json) =>
      EnableMetricsStreamingReply(ok: json['ok'] as bool);
}

// Class representing DisableMetricsStreamingRequest message
class DisableMetricsStreamingRequest implements Request {
  DisableMetricsStreamingRequest();

  factory DisableMetricsStreamingRequest.fromJson(Map<String, dynamic> json) =>
      DisableMetricsStreamingRequest();

  @override
  Map<String, dynamic> toJson() => {};
}

// Class representing DisableMetricsStreamingReply message
class DisableMetricsStreamingReply extends ReplyWithOK {
  DisableMetricsStreamingReply({required super.ok});

  factory DisableMetricsStreamingReply.fromJson(Map<String, dynamic> json) =>
      DisableMetricsStreamingReply(ok: json['ok'] as bool);
}
