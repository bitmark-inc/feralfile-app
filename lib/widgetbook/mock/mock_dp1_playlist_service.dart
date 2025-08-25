import 'package:autonomy_flutter/gateway/dp1_playlist_api.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/channel.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_api_response.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_item.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/provenance.dart';
import 'package:autonomy_flutter/screen/mobile_controller/services/channels_service.dart';
import 'package:autonomy_flutter/service/dp1_playlist_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:dio/dio.dart';

class MockDp1PlaylistService extends Dp1PlaylistService {
  MockDp1PlaylistService(super.api, super.apiKey);

  @override
  Future<DP1Call> createPlaylist(DP1Call playlist) async {
    // Mock creating a playlist
    return playlist;
  }

  @override
  Future<DP1Call> getPlaylistById(String playlistId) async {
    // Mock playlist data
    return DP1Call(
      dpVersion: '1.0.0',
      id: playlistId,
      slug: 'mock-playlist',
      title: 'Mock Playlist',
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
          title: 'Mock Artwork 1',
          source: 'https://example.com/mock-image-1.jpg',
        ),
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
      signature: 'mock-signature',
    );
  }

  @override
  Future<List<DP1Call>> getPlaylistsByChannel(Channel channel) async {
    // Mock playlists for a channel
    return [
      DP1Call(
        dpVersion: '1.0.0',
        id: 'mock-playlist-1',
        slug: 'mock-playlist-1',
        title: 'Mock Playlist 1',
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
            title: 'Mock Artwork 1',
            source: 'https://example.com/mock-image-1.jpg',
          ),
        ],
        signature: 'mock-signature-1',
      ),
      DP1Call(
        dpVersion: '1.0.0',
        id: 'mock-playlist-2',
        slug: 'mock-playlist-2',
        title: 'Mock Playlist 2',
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
            title: 'Mock Artwork 2',
            source: 'https://example.com/mock-image-2.jpg',
          ),
        ],
        signature: 'mock-signature-2',
      ),
    ];
  }

  @override
  Future<List<DP1Call>> getAllPlaylistsFromAllChannel() async {
    // Mock all playlists from all channels
    return [
      DP1Call(
        dpVersion: '1.0.0',
        id: 'mock-all-playlist-1',
        slug: 'mock-all-playlist-1',
        title: 'Mock All Playlist 1',
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
            title: 'Mock All Artwork 1',
            source: 'https://example.com/mock-all-image-1.jpg',
          ),
        ],
        signature: 'mock-all-signature-1',
      ),
    ];
  }

  @override
  Future<DP1PlaylistResponse> getPlaylistsFromChannels({
    String? cursor,
    int? limit,
  }) async {
    final playlists = await getAllPlaylistsFromAllChannel();
    return DP1PlaylistResponse(playlists, false, null);
  }

  @override
  Channel? getChannelByPlaylistId(String playlistId) {
    // Mock channel for playlist
    return Channel(
      id: 'mock-channel-for-playlist',
      slug: 'mock-channel-for-playlist',
      title: 'Mock Channel for Playlist',
      summary: 'Mock channel for playlist description',
      created: DateTime.now(),
      playlists: [
        'https://example.com/mock-playlist.json',
      ],
    );
  }

  @override
  Future<DP1PlaylistResponse> getPlaylists({
    String? channelId,
    String? cursor,
    int? limit,
  }) async {
    // Mock playlists response
    final mockPlaylists = [
      DP1Call(
        dpVersion: '1.0.0',
        id: 'mock-playlist-response-1',
        slug: 'mock-playlist-response-1',
        title: 'Mock Playlist Response 1',
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
            title: 'Mock Response Artwork 1',
            source: 'https://example.com/mock-response-image-1.jpg',
          ),
        ],
        signature: 'mock-response-signature-1',
      ),
    ];

    return DP1PlaylistResponse(mockPlaylists, false, null);
  }

  @override
  Future<DP1PlaylistItemsResponse> getPlaylistItems({
    List<String>? playlistGroupIds,
    String? cursor,
    int? limit,
  }) async {
    // Mock playlist items response
    return DP1PlaylistItemsResponse([], false, null);
  }
}
