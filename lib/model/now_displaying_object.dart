import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_state.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_item.dart';

abstract class NowDisplayingObjectBase {
  NowDisplayingObjectBase();

  List<AssetToken> get assetTokens;
}

class NowDisplayingObject extends NowDisplayingObjectBase {
  NowDisplayingObject({
    this.assetToken,
    this.dailiesWorkState,
  });

  final AssetToken? assetToken;
  final DailiesWorkState? dailiesWorkState;

  @override
  List<AssetToken> get assetTokens => [assetToken!];
}

class DP1NowDisplayingObject extends NowDisplayingObjectBase {
  DP1NowDisplayingObject({
    required this.index,
    required this.dp1Items,
    required this.assetTokens,
  });

  final int index;
  final List<DP1Item> dp1Items;
  final List<AssetToken> assetTokens;

  DP1Item get playlistItem => dp1Items[index];

  AssetToken get assetToken => assetTokens[index];
}
