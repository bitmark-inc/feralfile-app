import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:nft_collection/database/dao/dao.dart';

import 'account_service.dart';

abstract class PlaylistService {
  Future<List<PlayListModel>> getPlayList();

  Future<void> setPlayList(List<PlayListModel> playlists,
      {bool override = false});
}

class PlayListServiceImp implements PlaylistService {
  final ConfigurationService _configurationService;
  final TokenDao _tokenDao;
  final AccountService _accountService;

  PlayListServiceImp(
      this._configurationService, this._tokenDao, this._accountService);

  @override
  Future<List<PlayListModel>> getPlayList() async {
    final playlists = _configurationService.getPlayList();
    if (playlists.isEmpty) {
      return [];
    }

    final hiddenTokens = _configurationService.getTempStorageHiddenTokenIDs();

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

  @override
  Future<void> setPlayList(List<PlayListModel> playlists,
      {bool override = false}) async {
    _configurationService.setPlayList(playlists, override: override);
    return;
  }
}
