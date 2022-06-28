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
  int nextPageKey;
  bool isLastPage;
  bool isLoading;

  GalleryState({
    required this.tokens,
    required this.nextPageKey,
    required this.isLastPage,
    required this.isLoading,
  });

  GalleryState copyWith({
    List<AssetToken>? tokens,
    int? nextPageKey,
    bool? isLastPage,
    bool? isLoading,
  }) {
    return GalleryState(
      tokens: tokens ?? this.tokens,
      nextPageKey: nextPageKey ?? this.nextPageKey,
      isLastPage: isLastPage ?? this.isLastPage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
