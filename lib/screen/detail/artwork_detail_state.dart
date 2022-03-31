import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/provenance.dart';

abstract class ArtworkDetailEvent {}

class ArtworkDetailGetInfoEvent extends ArtworkDetailEvent {
  final String id;

  ArtworkDetailGetInfoEvent(this.id);
}

class ArtworkDetailState {
  AssetToken? asset;
  List<Provenance> provenances;
  AssetPrice? assetPrice;

  ArtworkDetailState({this.asset, required this.provenances, this.assetPrice});
}
