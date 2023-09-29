import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:nft_collection/database/dao/dao.dart';

import 'account_service.dart';

abstract class PlaylistService {
  Future<List<PlayListModel>> getPlayList();

  Future<void> setPlayList(List<PlayListModel> playlists,
      {bool override = false});

  Future<void> refreshPlayLists();

  Future<PlayListModel> getAllNftPlaylist();
}

class PlayListServiceImp implements PlaylistService {
  final ConfigurationService _configurationService;
  final TokenDao _tokenDao;
  final AccountService _accountService;

  PlayListServiceImp(
      this._configurationService, this._tokenDao, this._accountService);

  @override
  Future<List<PlayListModel>> getPlayList() async {
    final playlists = _getRawPlayList();

    if (playlists.isEmpty) {
      return [];
    }

    final hiddenTokens = _configurationService.getTempStorageHiddenTokenIDs();
    final recentlySent = _configurationService.getRecentlySentToken();
    hiddenTokens.addAll(recentlySent
        .where((element) => element.isSentAll)
        .map((e) => e.tokenID)
        .toList());
    final hiddenAddresses = await _accountService.getHiddenAddressIndexes();
    final tokens = await _tokenDao
        .findTokenIDsByOwners(hiddenAddresses.map((e) => e.address).toList());

    hiddenTokens.addAll(tokens);

    for (var playlist in playlists) {
      playlist.tokenIDs
          ?.removeWhere((tokenID) => hiddenTokens.contains(tokenID));
    }
    playlists.removeWhere((element) => element.tokenIDs?.isEmpty ?? true);
    return playlists;
  }

  List<PlayListModel> _getRawPlayList() {
    return _configurationService.getPlayList();
  }

  @override
  Future<void> setPlayList(List<PlayListModel> playlists,
      {bool override = false}) async {
    _configurationService.setPlayList(playlists, override: override);
    return;
  }

  @override
  Future<void> refreshPlayLists() async {
    final addresses = await _accountService.getAllAddresses();
    final List<String> ids = await _tokenDao.findTokenIDsOwnersOwn(addresses);
    final playlists = _getRawPlayList();
    for (int i = 0; i < playlists.length; i++) {
      playlists[i].tokenIDs?.removeWhere((tokenID) => !ids.contains(tokenID));
      if ((playlists[i].tokenIDs?.isEmpty ?? true) == true) {
        playlists.removeAt(i);
        i--;
      }
    }
    setPlayList(playlists, override: true);
  }

  @override
  Future<PlayListModel> getAllNftPlaylist() {
    // TODO: implement getAllNftPlaylist
    throw UnimplementedError();
  }
}
