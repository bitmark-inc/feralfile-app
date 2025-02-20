class PredefinedCollectionModel {
  PredefinedCollectionModel({
    required this.id,
    this.name,
    this.total = 0,
    this.thumbnailURL,
  });

  String id;
  String? name;
  int total;
  String? thumbnailURL;
}
