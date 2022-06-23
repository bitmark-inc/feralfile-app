part of 'gallery_bloc.dart';

abstract class GalleryEvent {}

class GetTokensEvent extends GalleryEvent {
  String address;

  GetTokensEvent(this.address);
}

class ReindexIndexerEvent extends GalleryEvent {
  String address;

  ReindexIndexerEvent(this.address);
}

class GalleryState {
  List<AssetToken>? tokens;

  GalleryState({
    required this.tokens,
  });
}
