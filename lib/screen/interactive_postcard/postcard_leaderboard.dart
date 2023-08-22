import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard_view.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/models.dart';

class PostcardLeaderboardPagePayload {
  final PostcardLeaderboard? leaderboard;
  final AssetToken? assetToken;

  PostcardLeaderboardPagePayload({
    this.leaderboard,
    this.assetToken,
  });
}

class PostcardLeaderboardPage extends StatefulWidget {
  final PostcardLeaderboardPagePayload? payload;

  const PostcardLeaderboardPage({Key? key, this.payload}) : super(key: key);

  @override
  State<PostcardLeaderboardPage> createState() =>
      _PostcardLeaderboardPageState();
}

class _PostcardLeaderboardPageState extends State<PostcardLeaderboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.pop(context);
        },
        title: "leaderboard".tr(),
      ),
      backgroundColor: POSTCARD_BACKGROUND_COLOR,
      body: PostcardLeaderboardView(
        leaderboard: widget.payload?.leaderboard,
        assetToken: widget.payload?.assetToken,
      ),
    );
  }
}

class PostcardLeaderboardItem {
  String id;
  int rank;
  String title;
  double totalDistance;
  List<String> creators;
  String previewUrl;

  PostcardLeaderboardItem({
    required this.id,
    required this.rank,
    required this.title,
    required this.totalDistance,
    required this.creators,
    required this.previewUrl,
  });

  static PostcardLeaderboardItem fromJson(Map<String, dynamic> json) {
    return PostcardLeaderboardItem(
      id: json['token_id'],
      rank: json['rank'],
      title: json['title'] ?? "",
      totalDistance: json['mileage'].toDouble(),
      creators:
          json['creators'] == null ? [] : json['creators'] as List<String>,
      previewUrl: json['preview_url'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "rank": rank,
      "title": title,
      "totalDistance": totalDistance,
      "creators": creators,
    };
  }
}

class PostcardLeaderboard {
  List<PostcardLeaderboardItem> items;
  DateTime lastUpdated;

  PostcardLeaderboard({
    required this.items,
    required this.lastUpdated,
  });

  static PostcardLeaderboard fromJson(Map<String, dynamic> json) {
    return PostcardLeaderboard(
      items: json['items']
          .map<PostcardLeaderboardItem>(
              (item) => PostcardLeaderboardItem.fromJson(item))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "items": items.map((item) => item.toJson()).toList(),
      "lastUpdated": lastUpdated.toIso8601String(),
    };
  }
}
