import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';

class PlaylistsService {
  static const List<Map<String, dynamic>> _mockData = [
    {
      'dpVersion': '1.0.0',
      'id': '1',
      'slug': 'console-spirituality',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '2',
      'slug': 'curated',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '3',
      'slug': 'harbor-scene',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '4',
      'slug': 'postcard-project',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '5',
      'slug': 'compressed-cinema',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '6',
      'slug': 'evolved-formulae',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '7',
      'slug': 'patterns-of-flow',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '8',
      'slug': 'balance',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '9',
      'slug': 'joyworld',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '10',
      'slug': 'rgb',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '11',
      'slug': 'digital-landscapes',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '12',
      'slug': 'generative-expressions',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '13',
      'slug': 'abstract-narratives',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '14',
      'slug': 'pixel-poetry',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
    {
      'dpVersion': '1.0.0',
      'id': '15',
      'slug': 'algorithmic-beauty',
      'created': '2025-06-26T06:38:26.396Z',
      'signature': 'ed25519:0x884e6b4bab7ab8',
      'defaults': <String, dynamic>{},
      'items': [],
    },
  ];

  Future<List<DP1Call>> getPlaylists({int page = 0, int limit = 20}) async {
    // Simulate network delay
    final delayMs = 500 + (page * 200);
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    final startIndex = page * limit;
    final endIndex = startIndex + limit;

    // Simulate finite data
    if (startIndex >= _mockData.length * 3) {
      return [];
    }

    final playlists = <DP1Call>[];
    for (var i = startIndex; i < endIndex && i < _mockData.length; i++) {
      playlists.add(DP1Call.fromJson(_mockData[i]));
    }

    return playlists;
  }
}
