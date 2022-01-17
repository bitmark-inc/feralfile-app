import 'package:autonomy_flutter/model/asset_price.dart';
import 'package:autonomy_flutter/model/bitmark.dart';

abstract class ArtworkDetailEvent {}

class ArtworkDetailGetInfoEvent extends ArtworkDetailEvent {
  final String id;

  ArtworkDetailGetInfoEvent(this.id);
}

class ArtworkDetailState {
  List<Provenance> provenances;
  AssetPrice? assetPrice;

  ArtworkDetailState({required this.provenances, this.assetPrice});
}
