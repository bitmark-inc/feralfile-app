import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_item.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/provenance.dart';

class MockMobileControllerData {
  // Mock Channels
  static Channel get mockChannel1 => Channel(
        id: 'mock-channel-1',
        slug: 'mock-channel-1',
        title: 'Mock Channel 1',
        summary: 'Mock channel description 1',
        created: DateTime.now().subtract(const Duration(days: 1)),
        playlists: [
          'https://example.com/mock-playlist-1.json',
          'https://example.com/mock-playlist-2.json',
        ],
      );

  static Channel get mockChannel2 => Channel(
        id: 'mock-channel-2',
        slug: 'mock-channel-2',
        title: 'Mock Channel 2',
        summary: 'Mock channel description 2',
        created: DateTime.now().subtract(const Duration(days: 2)),
        playlists: [
          'https://example.com/mock-playlist-3.json',
        ],
      );

  static Channel get mockChannel3 => Channel(
        id: 'mock-channel-3',
        slug: 'mock-channel-3',
        title: 'Mock Channel 3',
        summary: 'Mock channel description 3',
        created: DateTime.now().subtract(const Duration(days: 3)),
        playlists: [
          'https://example.com/mock-playlist-4.json',
          'https://example.com/mock-playlist-5.json',
          'https://example.com/mock-playlist-6.json',
        ],
      );

  static List<Channel> get mockChannels => [
        mockChannel1,
        mockChannel2,
        mockChannel3,
      ];

  // Mock Playlists
  static DP1Call get mockPlaylist1 => DP1Call(
        dpVersion: '1.0.0',
        id: 'mock-playlist-1',
        slug: 'mock-playlist-1',
        title: 'Mock Playlist 1',
        created: DateTime.now().subtract(const Duration(days: 1)),
        defaults: {'display': {}},
        items: [
          DP1Item(
            duration: 30,
            provenance: DP1Provenance(
              type: DP1ProvenanceType.onChain,
              contract: DP1Contract(
                chain: DP1ProvenanceChain.evm,
                standard: DP1ProvenanceStandard.erc721,
                address: '0x1234567890123456789012345678901234567890',
                tokenId: '1',
              ),
            ),
            title: 'Mock Artwork 1',
            source: 'https://example.com/mock-image-1.jpg',
          ),
        ],
        signature: 'mock-signature-1',
      );

  static DP1Call get mockPlaylist2 => DP1Call(
        dpVersion: '1.0.0',
        id: 'mock-playlist-2',
        slug: 'mock-playlist-2',
        title: 'Mock Playlist 2',
        created: DateTime.now().subtract(const Duration(days: 2)),
        defaults: {'display': {}},
        items: [
          DP1Item(
            duration: 45,
            provenance: DP1Provenance(
              type: DP1ProvenanceType.onChain,
              contract: DP1Contract(
                chain: DP1ProvenanceChain.evm,
                standard: DP1ProvenanceStandard.erc721,
                address: '0x1234567890123456789012345678901234567890',
                tokenId: '2',
              ),
            ),
            title: 'Mock Artwork 2',
            source: 'https://example.com/mock-image-2.jpg',
          ),
        ],
        signature: 'mock-signature-2',
      );

  static DP1Call get mockPlaylist3 => DP1Call(
        dpVersion: '1.0.0',
        id: 'mock-playlist-3',
        slug: 'mock-playlist-3',
        title: 'Mock Playlist 3',
        created: DateTime.now().subtract(const Duration(days: 3)),
        defaults: {'display': {}},
        items: [
          DP1Item(
            duration: 60,
            provenance: DP1Provenance(
              type: DP1ProvenanceType.onChain,
              contract: DP1Contract(
                chain: DP1ProvenanceChain.evm,
                standard: DP1ProvenanceStandard.erc721,
                address: '0x1234567890123456789012345678901234567890',
                tokenId: '3',
              ),
            ),
            title: 'Mock Artwork 3',
            source: 'https://example.com/mock-image-3.jpg',
          ),
        ],
        signature: 'mock-signature-3',
      );

  static List<DP1Call> get mockPlaylists => [
        mockPlaylist1,
        mockPlaylist2,
        mockPlaylist3,
      ];

  // Mock Record Data
  static DP1Call get mockRecordPlaylist => DP1Call(
        dpVersion: '1.0.0',
        id: 'mock-record-playlist-id',
        slug: 'mock-record-playlist',
        title: 'Mock Record Playlist',
        created: DateTime.now(),
        defaults: {'display': {}},
        items: [
          DP1Item(
            duration: 30,
            provenance: DP1Provenance(
              type: DP1ProvenanceType.onChain,
              contract: DP1Contract(
                chain: DP1ProvenanceChain.evm,
                standard: DP1ProvenanceStandard.erc721,
                address: '0x1234567890123456789012345678901234567890',
                tokenId: '1',
              ),
            ),
            title: 'Mock Record Artwork 1',
            source: 'https://example.com/mock-record-image-1.jpg',
          ),
        ],
        signature: 'mock-record-signature',
      );

  static DP1Call get mockVoicePlaylist => DP1Call(
        dpVersion: '1.0.0',
        id: 'mock-voice-playlist-id',
        slug: 'mock-voice-playlist',
        title: 'Mock Voice Playlist',
        created: DateTime.now(),
        defaults: {'display': {}},
        items: [
          DP1Item(
            duration: 45,
            provenance: DP1Provenance(
              type: DP1ProvenanceType.onChain,
              contract: DP1Contract(
                chain: DP1ProvenanceChain.evm,
                standard: DP1ProvenanceStandard.erc721,
                address: '0x1234567890123456789012345678901234567890',
                tokenId: '2',
              ),
            ),
            title: 'Mock Voice Artwork 1',
            source: 'https://example.com/mock-voice-image-1.jpg',
          ),
        ],
        signature: 'mock-voice-signature',
      );
}
