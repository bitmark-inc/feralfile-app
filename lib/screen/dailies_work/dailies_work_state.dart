import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:nft_collection/models/asset_token.dart';

class DailiesWorkState {
  final List<AssetToken> assetTokens;
  final DailyToken? currentDailyToken;
  final FFArtist? currentArtist;
  final Exhibition? currentExhibition;

  DailiesWorkState({
    required this.assetTokens,
    required this.currentDailyToken,
    required this.currentArtist,
    required this.currentExhibition,
  });
}