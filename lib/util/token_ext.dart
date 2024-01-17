import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:collection/collection.dart';
import 'package:nft_collection/models/asset_token.dart';

extension AssetTokenExtension on List<CompactedAssetToken> {
  List<CompactedAssetToken> filterAssetToken({bool isShowHidden = false}) {
    final hiddenTokens =
        injector<ConfigurationService>().getTempStorageHiddenTokenIDs();
    final sentArtworks =
        injector<ConfigurationService>().getRecentlySentToken();
    final expiredTime = DateTime.now().subtract(SENT_ARTWORK_HIDE_TIME);
    return whereNot((element) =>
        (!isShowHidden && hiddenTokens.contains(element.id)) ||
        ((element.balance ?? 0) <= 0 && element.isDebugged != true) ||
        sentArtworks.any(
          (e) =>
              e.isSentAll &&
              e.isHidden(
                  tokenID: element.id,
                  address: element.owner,
                  timestamp: expiredTime),
        )).toList();
  }

  List<CompactedAssetToken> filterByTitleContain(String title) =>
      where((element) =>
          element.title!.toLowerCase().contains(title.toLowerCase())).toList();
}
