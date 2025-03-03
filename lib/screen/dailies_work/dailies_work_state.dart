import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';

class DailiesWorkState {
  final List<AssetToken> assetTokens;
  final DailyToken? currentDailyToken;
  final AlumniAccount? currentArtist;
  final Exhibition? currentExhibition;

  DailiesWorkState({
    required this.assetTokens,
    required this.currentDailyToken,
    required this.currentArtist,
    required this.currentExhibition,
  });
}
