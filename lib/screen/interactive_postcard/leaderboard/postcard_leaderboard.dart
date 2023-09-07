import 'dart:async';

import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard_view.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/models.dart';

class PostcardLeaderboardPagePayload {
  final AssetToken? assetToken;

  PostcardLeaderboardPagePayload({
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
  late PostcardLeaderboard? leaderboard;
  late Timer _leaderboardTimer;
  late ScrollController _scrollController;
  late bool isFetchingLeaderboard;

  @override
  void initState() {
    leaderboard = null;
    _scrollController = ScrollController();
    isFetchingLeaderboard = false;
    _scrollController.addListener(() {
      final isScrollingDown = _scrollController.position.userScrollDirection ==
          ScrollDirection.reverse;
      if (_scrollController.position.pixels + 300 >=
              _scrollController.position.maxScrollExtent &&
          isScrollingDown) {
        if (!isFetchingLeaderboard) {
          onLoadmoreLeaderboard();
        }
      }
    });
    super.initState();
    context.read<PostcardDetailBloc>().add(FetchLeaderboardEvent());
    _setTimer();
  }

  @override
  void dispose() {
    _leaderboardTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _setTimer() {
    _leaderboardTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      context.read<PostcardDetailBloc>().add(RefreshLeaderboardEvent());
    });
  }

  void onLoadmoreLeaderboard() {
    context.read<PostcardDetailBloc>().add(FetchLeaderboardEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostcardDetailBloc, PostcardDetailState>(
        builder: (context, state) {
      return Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () {
            Navigator.pop(context);
          },
          title: "leaderboard".tr(),
          titleStyle: Theme.of(context)
              .textTheme
              .moMASans700Black16
              .copyWith(fontSize: 18),
          withDivider: false,
          backgroundColor: POSTCARD_BACKGROUND_COLOR,
        ),
        backgroundColor: POSTCARD_BACKGROUND_COLOR,
        body: PostcardLeaderboardView(
          leaderboard: state.leaderboard,
          assetToken: widget.payload?.assetToken,
          scrollController: _scrollController,
        ),
      );
    }, listener: (context, state) {
      setState(() {
        leaderboard = state.leaderboard;
        isFetchingLeaderboard = state.isFetchingLeaderboard;
      });
    });
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
