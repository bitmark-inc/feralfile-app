import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/nft_collection/models/models.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_state.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_item.dart';

abstract class NowDisplayingObjectBase {}

class NowDisplayingObject extends NowDisplayingObjectBase {
  NowDisplayingObject({
    this.assetToken,
    this.exhibitionDisplaying,
    this.dailiesWorkState,
  });

  final AssetToken? assetToken;
  final ExhibitionDisplaying? exhibitionDisplaying;
  final DailiesWorkState? dailiesWorkState;
}

class DP1NowDisplayingObject extends NowDisplayingObjectBase {
  DP1NowDisplayingObject({
    required this.playlistItem,
    this.assetToken,
  });

  final DP1Item playlistItem;
  final AssetToken? assetToken;
}

class ExhibitionDisplaying {
  ExhibitionDisplaying({
    this.exhibition,
    this.catalogId,
    this.catalog,
    this.artwork,
  });

  final Exhibition? exhibition;
  final String? catalogId;
  final ExhibitionCatalog? catalog;
  final Artwork? artwork;
}
