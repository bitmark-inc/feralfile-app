import 'dart:async';

import 'package:autonomy_flutter/gateway/mobile_controller_api.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/intent.dart';
import 'package:dio/dio.dart';

class MockMobileControllerAPI implements MobileControllerAPI {
  @override
  Future<Map<String, dynamic>> getDP1CallFromText(
    Map<String, dynamic> body,
  ) async {
    // Mock response for text API
    final mockDp1Call = {
      'dpVersion': '1.0.0',
      'id': 'mock-text-playlist-id',
      'slug': 'mock-text-playlist',
      'title': 'Mock Text Playlist',
      'created': DateTime.now().toIso8601String(),
      'defaults': {'display': {}},
      'items': [
        {
          'title': 'Mock Text Artwork 1',
          'source': 'https://example.com/mock-text-image-1.jpg',
          'duration': 30,
          'license': 'open',
          'provenance': {
            'type': 'onChain',
            'contract': {
              'chain': 'evm',
              'standard': 'erc721',
              'address': '0x1234567890123456789012345678901234567890',
              'tokenId': '1',
            },
          },
        },
        {
          'title': 'Mock Text Artwork 2',
          'source': 'https://example.com/mock-text-image-2.jpg',
          'duration': 45,
          'license': 'open',
          'provenance': {
            'type': 'onChain',
            'contract': {
              'chain': 'evm',
              'standard': 'erc721',
              'address': '0x1234567890123456789012345678901234567890',
              'tokenId': '2',
            },
          },
        },
      ],
      'signature': 'mock-text-signature',
    };

    final mockIntent = {
      'action': 'now_display',
      'device_name': body['device_names']?.first ?? 'Mock Text Device',
      'entities': [
        {
          'name': 'Mock Artist',
          'type': 'artist',
          'probability': 0.9,
        },
      ],
      'search_term': body['command'] ?? 'Mock search term',
    };

    return {
      'dp1_call': mockDp1Call,
      'intent': mockIntent,
      'response': 'Mock response for text: ${body['command']}',
    };
  }

  @override
  Future<Stream<dynamic>> getDP1CallFromTextStream(
    Map<String, dynamic> body,
  ) async {
    // Mock stream response for text API
    final mockData = {
      'type': 'transcription',
      'data': {
        'corrected_text': body['command'] ?? 'Mock transcription',
      },
      'content': body['command'] ?? 'Mock transcription',
    };

    final mockThinkingData = {
      'type': 'thinking',
      'data': {},
      'content': 'Processing your request...',
    };

    final mockIntentData = {
      'type': 'intent',
      'data': {
        'action': 'now_display',
        'device_name': body['device_names']?.first ?? 'Mock Stream Device',
        'entities': [
          {
            'name': 'Mock Stream Artist',
            'type': 'artist',
            'probability': 0.85,
          },
        ],
        'search_term': body['command'] ?? 'Mock stream search term',
      },
      'content': 'Building playlist for artist(s) Mock Stream Artist',
    };

    final mockDp1CallData = {
      'type': 'dp1_call',
      'data': {
        'dpVersion': '1.0.0',
        'id': 'mock-stream-playlist-id',
        'slug': 'mock-stream-playlist',
        'title': 'Mock Stream Playlist',
        'created': DateTime.now().toIso8601String(),
        'defaults': {'display': {}},
        'items': [
          {
            'title': 'Mock Stream Artwork 1',
            'source': 'https://example.com/mock-stream-image-1.jpg',
            'duration': 30,
            'license': 'open',
            'provenance': {
              'type': 'onChain',
              'contract': {
                'chain': 'evm',
                'standard': 'erc721',
                'address': '0x1234567890123456789012345678901234567890',
                'tokenId': '1',
              },
            },
          },
        ],
        'signature': 'mock-stream-signature',
      },
    };

    final mockResponseData = {
      'type': 'response',
      'data': {},
      'content': 'Mock stream response for: ${body['command']}',
    };

    final mockCompleteData = {
      'type': 'complete',
      'data': {},
      'content': 'Request completed successfully',
    };

    // Simulate streaming data with delays
    return Stream.fromIterable([
      mockData,
      mockThinkingData,
      mockIntentData,
      mockDp1CallData,
      mockResponseData,
      mockCompleteData,
    ]).asyncMap((data) async {
      await Future.delayed(const Duration(milliseconds: 500));
      return data;
    });
  }

  @override
  Future<Map<String, dynamic>> getDP1CallFromVoice(
    Map<String, dynamic> body,
  ) async {
    // Mock response for voice API
    final mockDp1Call = {
      'dpVersion': '1.0.0',
      'id': 'mock-voice-playlist-id',
      'slug': 'mock-voice-playlist',
      'title': 'Mock Voice Playlist',
      'created': DateTime.now().toIso8601String(),
      'defaults': {'display': {}},
      'items': [
        {
          'title': 'Mock Voice Artwork 1',
          'source': 'https://example.com/mock-voice-image-1.jpg',
          'duration': 60,
          'license': 'open',
          'provenance': {
            'type': 'onChain',
            'contract': {
              'chain': 'evm',
              'standard': 'erc721',
              'address': '0x1234567890123456789012345678901234567890',
              'tokenId': '3',
            },
          },
        },
      ],
      'signature': 'mock-voice-signature',
    };

    final mockIntent = {
      'action': 'now_display',
      'device_name': body['device_names']?.first ?? 'Mock Voice Device',
      'entities': [
        {
          'name': 'Mock Voice Artist',
          'type': 'artist',
          'probability': 0.88,
        },
      ],
      'search_term': 'Mock voice search term',
    };

    return {
      'dp1_call': mockDp1Call,
      'intent': mockIntent,
      'response': 'Mock response for voice input',
    };
  }

  @override
  Future<Stream<dynamic>> getDP1CallFromVoiceStream(
    Map<String, dynamic> body,
  ) async {
    // Mock stream response for voice API
    final mockTranscriptionData = {
      'type': 'transcription',
      'data': {
        'corrected_text': 'Mock voice transcription',
      },
      'content': 'Mock voice transcription',
    };

    final mockThinkingData = {
      'type': 'thinking',
      'data': {},
      'content': 'Processing your voice input...',
    };

    final mockIntentData = {
      'type': 'intent',
      'data': {
        'action': 'now_display',
        'device_name':
            body['device_names']?.first ?? 'Mock Voice Stream Device',
        'entities': [
          {
            'name': 'Mock Voice Stream Artist',
            'type': 'artist',
            'probability': 0.92,
          },
        ],
        'search_term': 'Mock voice stream search term',
      },
      'content': 'Building playlist for artist(s) Mock Voice Stream Artist',
    };

    final mockDp1CallData = {
      'type': 'dp1_call',
      'data': {
        'dpVersion': '1.0.0',
        'id': 'mock-voice-stream-playlist-id',
        'slug': 'mock-voice-stream-playlist',
        'title': 'Mock Voice Stream Playlist',
        'created': DateTime.now().toIso8601String(),
        'defaults': {'display': {}},
        'items': [
          {
            'title': 'Mock Voice Stream Artwork 1',
            'source': 'https://example.com/mock-voice-stream-image-1.jpg',
            'duration': 90,
            'license': 'open',
            'provenance': {
              'type': 'onChain',
              'contract': {
                'chain': 'evm',
                'standard': 'erc721',
                'address': '0x1234567890123456789012345678901234567890',
                'tokenId': '4',
              },
            },
          },
        ],
        'signature': 'mock-voice-stream-signature',
      },
    };

    final mockResponseData = {
      'type': 'response',
      'data': {},
      'content': 'Mock voice stream response',
    };

    final mockCompleteData = {
      'type': 'complete',
      'data': {},
      'content': 'Voice request completed successfully',
    };

    // Simulate streaming data with delays
    return Stream.fromIterable([
      mockTranscriptionData,
      mockThinkingData,
      mockIntentData,
      mockDp1CallData,
      mockResponseData,
      mockCompleteData,
    ]).asyncMap((data) async {
      await Future.delayed(const Duration(milliseconds: 800));
      return data;
    });
  }
}
