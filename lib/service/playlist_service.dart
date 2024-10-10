import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:collection/collection.dart';
import 'package:nft_collection/database/dao/dao.dart';
import 'package:nft_collection/services/tokens_service.dart';

abstract class PlaylistService {
  Future<List<PlayListModel>> getPlayList();

  Future<PlayListModel?> getPlaylistById(String id);

  Future<void> setPlayList(List<PlayListModel> playlists,
      {bool override = false,
      ConflictAction onConflict = ConflictAction.abort});

  Future<void> refreshPlayLists();

  Future<List<PlayListModel>> defaultPlaylists();

  Future<void> addPlaylists(List<PlayListModel> playlists);
}

class PlayListServiceImp implements PlaylistService {
  final ConfigurationService _configurationService;
  final TokenDao _tokenDao;
  final AccountService _accountService;
  final AssetTokenDao _assetTokenDao;

  PlayListServiceImp(this._configurationService, this._tokenDao,
      this._accountService, this._assetTokenDao);

  Future<PlayListModel?> getPlaylistById(String id) async {
    final playlists = await getPlayList();
    return playlists.firstWhereOrNull((element) => element.id == id);
  }

  Future<List<String>> _getHiddenTokenIds() async {
    final hiddenTokens = _configurationService.getHiddenOrSentTokenIDs();
    final hiddenAddresses = await _accountService.getHiddenAddressIndexes();
    final tokens = await _tokenDao
        .findTokenIDsByOwners(hiddenAddresses.map((e) => e.address).toList());

    hiddenTokens.addAll(tokens);
    return hiddenTokens;
  }

  @override
  Future<List<PlayListModel>> getPlayList() async {
    final playlists = _getRawPlayList();

    if (playlists.isEmpty) {
      return [];
    }

    final hiddenTokens = await _getHiddenTokenIds();

    for (var playlist in playlists) {
      playlist.tokenIDs
          .removeWhere((tokenID) => hiddenTokens.contains(tokenID));
    }
    playlists.removeWhere((element) => element.tokenIDs.isEmpty);
    return playlists;
  }

  List<PlayListModel> _getRawPlayList() => _configurationService.getPlayList();

  @override
  Future<void> setPlayList(
    List<PlayListModel> playlists, {
    bool override = false,
    ConflictAction onConflict = ConflictAction.abort,
  }) async {
    await _configurationService.setPlayList(playlists,
        override: override, onConflict: onConflict);
    return;
  }

  @override
  Future<void> refreshPlayLists() async {
    final addresses = await _accountService.getAllAddresses();
    final List<String> ids = await _tokenDao.findTokenIDsOwnersOwn(addresses);
    final playlists = _getRawPlayList();
    for (int i = 0; i < playlists.length; i++) {
      playlists[i].tokenIDs.removeWhere((tokenID) => !ids.contains(tokenID));
      if (playlists[i].tokenIDs.isEmpty) {
        playlists.removeAt(i);
        i--;
      }
    }
    await setPlayList(playlists, override: true);
  }

  @override
  Future<List<PlayListModel>> defaultPlaylists() async {
    List<PlayListModel> defaultPlaylists = [];
    final activeAddress = await _accountService.getShowedAddresses();
    List<String> allTokenIds =
        await _tokenDao.findTokenIDsOwnersOwn(activeAddress);
    final hiddenTokenIds = _configurationService.getHiddenOrSentTokenIDs();
    allTokenIds.removeWhere((element) => hiddenTokenIds.contains(element));
    if (allTokenIds.isNotEmpty) {
      final token = await _assetTokenDao
          .findAllAssetTokensByTokenIDs([allTokenIds.first]);

      final allNftsPlaylist = PlayListModel(
          id: DefaultPlaylistModel.allNfts.id,
          name: DefaultPlaylistModel.allNfts.name,
          tokenIDs: allTokenIds,
          thumbnailURL: token.first.thumbnailURL);
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
    await setPlayList(playlists);
  }
}
