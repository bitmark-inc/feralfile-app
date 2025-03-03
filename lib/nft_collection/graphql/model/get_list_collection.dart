import 'package:autonomy_flutter/nft_collection/models/user_collection.dart';

class QueryListCollectionResponse {
  QueryListCollectionResponse({
    required this.collections,
  });

  factory QueryListCollectionResponse.fromJson(Map<String, dynamic> json) =>
      QueryListCollectionResponse(
        collections: List<UserCollection>.from(
          (json['collections'] as List).map<UserCollection>(
            (x) => UserCollection.fromJson(
              Map<String, dynamic>.from(x as Map),
            ),
          ),
        ),
      );

  final List<UserCollection> collections;
}
