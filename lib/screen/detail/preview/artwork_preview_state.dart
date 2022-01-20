import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/bitmark.dart';

abstract class ArtworkPreviewEvent {}

class ArtworkPreviewGetAssetTokenEvent extends ArtworkPreviewEvent {
  final String id;

  ArtworkPreviewGetAssetTokenEvent(this.id);
}

class ArtworkPreviewState {
  AssetToken? asset;

  ArtworkPreviewState({this.asset});
}
