

class ViewList {
  String listName;
  List<String> tokenIDs;

  ViewList({required this.listName, required this.tokenIDs});

  factory ViewList.fromJson(Map<String, dynamic> json) =>
      _$ViewListFromJson(json);
  Map<String, dynamic> toJson() => _$ViewListToJson(this);
}

ViewList _$ViewListFromJson(Map<String, dynamic> json) => ViewList(
    listName: json["listView"] as String,
    tokenIDs: (json["tokenIDs"] as List<dynamic>).map((e) => e.toString()).toList());

Map<String, dynamic> _$ViewListToJson(ViewList instance) =>
    <String, dynamic>{
      'listView': instance.listName,
      'tokenIDs': instance.tokenIDs,
    };