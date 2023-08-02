import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/skeleton.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/asset_token.dart';

class PostcardLeaderboardView extends StatefulWidget {
  final PostcardLeaderboard? leaderboard;
  final AssetToken? assetToken;
  const PostcardLeaderboardView({Key? key, this.leaderboard, this.assetToken})
      : super(key: key);

  @override
  State<PostcardLeaderboardView> createState() =>
      _PostcardLeaderboardViewState();
}

class _PostcardLeaderboardViewState extends State<PostcardLeaderboardView> {
  final numberFormatter = NumberFormat("00");
  final distanceFormatter = DistanceFormatter();
  final postcardService = injector.get<PostcardService>();
  final _pageStorageBucket = PageStorageBucket();
  late ScrollController _leaderboardScrollController;

  @override
  void initState() {
    _leaderboardScrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _leaderboardScrollController.dispose();
    super.dispose();
  }

  Widget _loadingLeaderboard(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Column(
        children: [
          Expanded(
            child: AnimatedList(
              initialItemCount: 51,
              itemBuilder: (context, index, animation) {
                if (index == 0) {
                  return _loadingLeaderboardHeader(context);
                }
                return _loadingLeaderboardItem(context, index: index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingLeaderboardHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "updating_leaderboard".tr(),
              style: theme.textTheme.moMASans400Grey12.copyWith(fontSize: 10),
            )
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _leaderboardHeader(BuildContext context, DateTime lastUpdated) {
    final theme = Theme.of(context);
    final dateFormater = DateFormat("yyyy-MM-dd HH:mm");
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "last_updated"
                  .tr(namedArgs: {"time": dateFormater.format(lastUpdated)}),
              style: theme.textTheme.moMASans400Grey12.copyWith(fontSize: 10),
            )
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _loadingLeaderboardItem(BuildContext context, {int index = 1}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              children: [
                Text(
                  numberFormatter.format(index),
                  style: theme.textTheme.moMASans400Black12,
                ),
                const SizedBox(width: 36),
                Expanded(
                  flex: 2,
                  child: SkeletonContainer(
                    width: 64,
                    height: 17,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(child: Container()),
                Expanded(
                  child: SkeletonContainer(
                    width: 64,
                    height: 17,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          addOnlyDivider(color: AppColor.auLightGrey),
        ],
      ),
    );
  }

  Widget _leaderboardItem(PostcardLeaderboardItem leaderBoardItem,
      {required bool isYour}) {
    final theme = Theme.of(context);
    const moMAColor = Color.fromRGBO(131, 79, 196, 1);
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            color: isYour ? moMAColor : Colors.transparent,
            width: 12,
            height: 24,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  children: [
                    Text(
                      numberFormatter.format(leaderBoardItem.rank),
                      style: theme.textTheme.moMASans400Black12,
                    ),
                    const SizedBox(width: 36),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: leaderBoardItem.title,
                              style: theme.textTheme.moMASans400Black12
                                  .copyWith(color: moMAColor),
                            ),
                            if (isYour)
                              TextSpan(
                                text: "_your".tr(),
                                style: const TextStyle(
                                    color: AppColor.auLightGrey),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      distanceFormatter.showDistance(
                          distance: leaderBoardItem.totalDistance,
                          distanceUnit: DistanceFormatter.getDistanceUnit),
                      style: theme.textTheme.moMASans400Black12,
                    ),
                  ],
                ),
              ),
              addOnlyDivider(color: AppColor.auLightGrey),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaderBoard = widget.leaderboard;
    if (leaderBoard == null) {
      return _loadingLeaderboard(context);
    }
    const listKey = PageStorageKey("leaderboard");
    return SizedBox(
      height: 500,
      child: Column(
        children: [
          Expanded(
            child: PageStorage(
              bucket: _pageStorageBucket,
              child: AnimatedList(
                key: listKey,
                controller: _leaderboardScrollController,
                initialItemCount: leaderBoard.items.length + 1,
                itemBuilder: (context, index, animation) {
                  if (index == 0) {
                    return _leaderboardHeader(context, leaderBoard.lastUpdated);
                  }
                  final item = leaderBoard.items[index - 1];
                  final isYours = item.id == widget.assetToken?.id;
                  return _leaderboardItem(item, isYour: isYours);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
