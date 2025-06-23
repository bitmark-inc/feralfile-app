import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/screen/mobile_controller/json_stream.dart';
import 'package:autonomy_flutter/util/file_ext.dart';
import 'package:autonomy_flutter/util/log.dart';

import '../gateway/mobile_controller_api.dart';

class MobileControllerService {
  MobileControllerService(this.api);

  final MobileControllerAPI api;

  /// Gọi API và trả về intent, dp1_call
  Future<Map<String, dynamic>> getDP1CallFromText({
    required String command,
    required List<String> deviceNames,
  }) async {
    final body = {
      'command': command,
      'device_names': deviceNames,
    };
    final result = await api.getDP1CallFromText(body);
    return {
      'intent': result['intent'],
      'dp1_call': result['dp1_call'],
    };
  }

  //getDP1CallFromVoice
  Future<Stream<Map<String, dynamic>>> getDP1CallFromVoice({
    required File file,
    required List<String> deviceNames,
    bool withStream = false,
  }) async {
    final bytes = await file.toBytes();
    final base64String = base64Encode(bytes);
    final body = {
      'audio': base64String,
      'device_names': deviceNames,
    };
    try {
      final result = await api.getDP1CallFromVoiceStream(
        body,
        true,
      );
      final listIntStream = result.cast<List<int>>();
      return JsonStream(listIntStream).stream;
    } catch (e) {
      log.info('getDP1CallFromVoice error: $e');
      rethrow;
    }
  }
}

enum NLParserAction {
  getCurrentPlaylist,
  Unknown;

  String get value {
    switch (this) {
      case NLParserAction.getCurrentPlaylist:
        return 'get_current_playlist';
      case NLParserAction.Unknown:
        return 'Unknown';
      default:
        return 'Unknown';
    }
  }

  // Factory method to create an instance from a string
  factory NLParserAction.fromString(String value) {
    switch (value) {
      case 'get_current_playlist':
        return NLParserAction.getCurrentPlaylist;
      default:
        return NLParserAction.Unknown;
    }
  }
}

enum NLParserDataType {
  transcription,
  thinking,
  intent,
  complete,
  summary,
  result,
  unknown,
  error;

  String get value {
    switch (this) {
      case NLParserDataType.transcription:
        return 'transcription';
      case NLParserDataType.thinking:
        return 'thinking';
      case NLParserDataType.intent:
        return 'intent';
      case NLParserDataType.complete:
        return 'complete';
      case NLParserDataType.summary:
        return 'summary';
      case NLParserDataType.result:
        return 'result';
      case NLParserDataType.error:
        return 'error';
      default:
        return 'Unknown';
    }
  }

  // Factory method to create an instance from a string
  factory NLParserDataType.fromString(String value) {
    switch (value) {
      case 'transcription':
        return NLParserDataType.transcription;
      case 'thinking':
        return NLParserDataType.thinking;
      case 'intent':
        return NLParserDataType.intent;
      case 'complete':
        return NLParserDataType.complete;
      case 'summary':
        return NLParserDataType.summary;
      case 'result':
        return NLParserDataType.result;
      case 'error':
        return NLParserDataType.error;
      default:
        throw NLParserDataType.unknown;
    }
  }
}

class NLParserData {
  // fromJson method to create an object from a JSON map
  factory NLParserData.fromJson(Map<String, dynamic> json) {
    return NLParserData(
      type: NLParserDataType.fromString(json['type'] as String),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] == null
          ? {}
          : Map<String, dynamic>.from(json['data'] as Map),
    );
  }

  NLParserData({
    required this.type,
    required this.content,
    DateTime? timestamp,
    required this.data,
  }) : timestamp = timestamp ?? DateTime.now();
  final NLParserDataType type;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  // toJson method to convert the object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}
