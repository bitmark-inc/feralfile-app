import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object/playlist_cloud_object.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:nft_collection/database/dao/dao.dart';
import 'package:nft_collection/services/tokens_service.dart';

abstract class PlaylistService {
  Future<List<PlayListModel>> getPlayList();

  Future<PlayListModel?> getPlaylistById(String id);

  Future<void> setPlayList(
    List<PlayListModel> playlists, {
    bool override = false,
    ConflictAction onConflict = ConflictAction.abort,
  });

  Future<List<PlayListModel>> defaultPlaylists();

  Future<void> addPlaylists(List<PlayListModel> playlists);

  Future<bool> deletePlaylist(PlayListModel playlist);
}

class PlayListServiceImp implements PlaylistService {
  PlayListServiceImp(
    this._configurationService,
    this._tokenDao,
    this._addressService,
    this._assetTokenDao,
    this._cloudManager,
  );

  final ConfigurationService _configurationService;
  final TokenDao _tokenDao;
  final AssetTokenDao _assetTokenDao;
  final CloudManager _cloudManager;
  final AddressService _addressService;

  late final PlaylistCloudObject _playlistCloudObject =
      _cloudManager.playlistCloudObject;
  bool _didFetch = false;

  @override
  Future<PlayListModel?> getPlaylistById(String id) async {
    await _fetchPlaylists();
    return _playlistCloudObject.getPlaylistById(id);
  }

  Future<List<String>> _getHiddenTokenIds() async {
    final hiddenTokens = _configurationService.getHiddenTokenIDs();
    final hiddenAddresses =
        _addressService.getAllWalletAddresses(isHidden: true);
    final tokens = await _tokenDao
        .findTokenIDsByOwners(hiddenAddresses.map((e) => e.address).toList());

    hiddenTokens.addAll(tokens);
    return hiddenTokens;
  }

  Future<void> _fetchPlaylists() async {
    if (_didFetch) {
      return;
    }
    await _playlistCloudObject.db.download();
    _didFetch = true;
  }

  @override
  Future<List<PlayListModel>> getPlayList() async {
    await _fetchPlaylists();
    final playlists = _getRawPlayList();

    if (playlists.isEmpty) {
      return [];
    }

    final hiddenTokens = await _getHiddenTokenIds();

    for (final playlist in playlists) {
      playlist.tokenIDs.removeWhere(hiddenTokens.contains);
    }
    playlists.removeWhere((element) => element.tokenIDs.isEmpty);
    return playlists;
  }

  List<PlayListModel> _getRawPlayList() => _playlistCloudObject.getPlaylists();

  @override
  Future<void> setPlayList(
    List<PlayListModel> playlists, {
    bool override = false,
    ConflictAction onConflict = ConflictAction.abort,
  }) async {
    await _fetchPlaylists();
    final currentPlaylists = _getRawPlayList();
    if (override) {
      await _playlistCloudObject.deletePlaylists(currentPlaylists);
      await _playlistCloudObject.setPlaylists(playlists);
    } else {
      switch (onConflict) {
        case ConflictAction.replace:
          await _playlistCloudObject.setPlaylists(playlists);
        case ConflictAction.abort:
          playlists.removeWhere(
            (element) => currentPlaylists.any((e) => e.id == element.id),
          );
          await _playlistCloudObject.setPlaylists(playlists);
      }
    }
  }

  @override
  Future<List<PlayListModel>> defaultPlaylists() async {
    final defaultPlaylists = <PlayListModel>[];
    final activeAddress = _addressService.getAllAddresses(isHidden: false);
    final allTokenIds = await _tokenDao.findTokenIDsOwnersOwn(activeAddress);
    final hiddenTokenIds = _configurationService.getHiddenTokenIDs();
    allTokenIds.removeWhere(hiddenTokenIds.contains);
    if (allTokenIds.isNotEmpty) {
      final token = await _assetTokenDao
          .findAllAssetTokensByTokenIDs([allTokenIds.first]);

      final allNftsPlaylist = PlayListModel(
        id: DefaultPlaylistModel.allNfts.id,
        name: DefaultPlaylistModel.allNfts.name,
        tokenIDs: allTokenIds,
        thumbnailURL: token.first.thumbnailURL,
      );
      defaultPlaylists.add(allNftsPlaylist);
    }
    return defaultPlaylists;
  }

  @override
  Future<void> addPlaylists(List<PlayListModel> playlists) async {
    final tokenService = injector<TokensService>();
    final indexerIds = playlists
        .map((e) => e.tokenIDs)
        .expand((element) => element)
        .toSet()
        .toList();
    await tokenService.fetchManualTokens(indexerIds);
    final playlistWithThumbnail = await Future.wait(
      playlists.map((e) async {
        final token = await _assetTokenDao
            .findAllAssetTokensByTokenIDs([e.tokenIDs.first]);
        return e.copyWith(thumbnailURL: token.first.thumbnailURL);
      }).toList(),
    );
    await setPlayList(playlistWithThumbnail);
  }

  @override
  Future<bool> deletePlaylist(PlayListModel playlist) =>
      _playlistCloudObject.deletePlaylists([playlist]);
}
