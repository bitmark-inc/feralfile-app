import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/mock_asset_token.dart';
import 'package:collection/collection.dart';

class MockPlaylistService implements PlaylistService {
  final List<PlayListModel> _playlists = [];

  @override
  Future<List<PlayListModel>> getPlayList() async {
    await _fetchPlaylists();
    return _playlists;
  }

  @override
  Future<PlayListModel?> getPlaylistById(String id) async {
    await _fetchPlaylists();
    return _playlists.firstWhereOrNull(
      (playlist) => playlist.id == id,
    );
  }

  @override
  Future<void> setPlayList(
    List<PlayListModel> playlists, {
    bool override = false,
    ConflictAction onConflict = ConflictAction.abort,
  }) async {}

  @override
  Future<List<PlayListModel>> defaultPlaylists() async {
    final allTokens = MockAssetToken.all;
    if (allTokens.isEmpty) {
      return [];
    }

    final allNftsPlaylist = PlayListModel(
      id: DefaultPlaylistModel.allNfts.id,
      name: DefaultPlaylistModel.allNfts.name,
      tokenIDs: allTokens.map((token) => token.id).toList(),
      thumbnailURL: allTokens.first.thumbnailURL,
    );

    return [allNftsPlaylist];
  }

  @override
  Future<void> addPlaylists(List<PlayListModel> playlists) async {
    for (final playlist in playlists) {
      final token = MockAssetToken.getByIndexerTokenId(playlist.tokenIDs.first);
      if (token != null) {
        final updatedPlaylist = playlist.copyWith(
          thumbnailURL: token.thumbnailURL,
        );
        _playlists.add(updatedPlaylist);
      }
    }
  }

  @override
  Future<bool> deletePlaylist(PlayListModel playlist) async {
    final initialLength = _playlists.length;
    _playlists.removeWhere((p) => p.id == playlist.id);
    return _playlists.length < initialLength;
  }

  Future<void> _fetchPlaylists() async {
    final token1 = MockAssetToken.all.first;
    final token2 = MockAssetToken.all[1];

    final playlist1 = PlayListModel(
        tokenIDs: [token1.id],
        name: 'Playlist 1',
        id: 'playlist1',
        thumbnailURL: token1.thumbnailURL);
    final playlist2 = PlayListModel(
        tokenIDs: [token2.id],
        name: 'Playlist 2',
        id: 'playlist2',
        thumbnailURL: token2.thumbnailURL);
    _playlists.clear();
    _playlists.addAll([playlist1, playlist2]);
  }
}
