import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_flutter/util/number_formater.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/skeleton.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension/moma_sans.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/models/asset_token.dart';

class PostcardLeaderboardView extends StatefulWidget {
  final PostcardLeaderboard? leaderboard;
  final AssetToken? assetToken;
  final ScrollController? scrollController;

  const PostcardLeaderboardView(
      {super.key, this.leaderboard, this.assetToken, this.scrollController});

  @override
  State<PostcardLeaderboardView> createState() =>
      _PostcardLeaderboardViewState();
}

class _PostcardLeaderboardViewState extends State<PostcardLeaderboardView> {
  final numberFormatter = OrdinalNumberFormatter();
  final distanceFormatter = DistanceFormatter();
  final postcardService = injector.get<PostcardService>();
  final _pageStorageBucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _loadingLeaderboard(BuildContext context) => SizedBox(
        child: Column(
          children: [
            Expanded(
              child: AnimatedList(
                controller: widget.scrollController,
                initialItemCount: 51,
                itemBuilder: (context, index, animation) {
                  if (index == 0) {
                    return _leaderboardHeader(context);
                  }
                  return _loadingLeaderboardItem(context, index: index);
                },
              ),
            ),
          ],
        ),
      );

  Widget _leaderboardHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'last_updated'.tr(),
              style: theme.textTheme.moMASans400Grey12,
            )
          ],
        ),
        const SizedBox(height: 15),
        addOnlyDivider(color: AppColor.auLightGrey)
      ],
    );
  }

  Widget _loadingLeaderboardItem(BuildContext context, {int index = 1}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TappableForwardRow(
              onTap: () {},
              leftWidget: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 65,
                    width: 85,
                    child: SkeletonContainer(),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonContainer(
                          width: 70,
                          height: 17,
                        ),
                        SizedBox(height: 5),
                        SkeletonContainer(
                          width: 110,
                          height: 17,
                        )
                      ],
                    ),
                  ),
                ],
              ),
              forwardIcon: SvgPicture.asset(
                'assets/images/iconForward.svg',
                colorFilter: const ColorFilter.mode(
                    AppColor.secondarySpanishGrey, BlendMode.srcIn),
              ),
            ),
          ),
          addOnlyDivider(color: AppColor.auLightGrey),
        ],
      );

  void _onTapLeaderboardItem(BuildContext context,
      PostcardLeaderboardItem leaderBoardItem, bool isYour) {
    if (isYour) {
      Navigator.of(context).pop();
      return;
    }
    if (leaderBoardItem.creators.isEmpty) {
      return;
    }
    final tokenId = postcardService.getTokenId(leaderBoardItem.id);
    final owner = leaderBoardItem.creators[0];
    final payload = PostcardDetailPagePayload(
      ArtworkIdentity(
        tokenId,
        owner,
      ),
      isFromLeaderboard: true,
      useIndexer: true,
    );
    unawaited(Navigator.of(context).pushNamed(
      AppRouter.claimedPostcardDetailsPage,
      arguments: payload,
    ));
  }

  Widget _leaderboardItem(
      BuildContext context, PostcardLeaderboardItem leaderBoardItem,
      {required bool isYour}) {
    final theme = Theme.of(context);
    final backgroundColor = isYour ? AppColor.auLightGrey : Colors.transparent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TappableForwardRow(
            onTap: () {
              _onTapLeaderboardItem(context, leaderBoardItem, isYour);
            },
            leftWidget: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 65,
                  width: 85,
                  child: CachedNetworkImage(
                    imageUrl: leaderBoardItem.previewUrl,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        textScaler: MediaQuery.textScalerOf(context),
                        text: TextSpan(
                          style: theme.textTheme.moMASans400Black12
                              .copyWith(fontSize: 18),
                          children: [
                            TextSpan(
                              text:
                                  numberFormatter.format(leaderBoardItem.rank),
                            ),
                            if (isYour)
                              TextSpan(
                                text: ' ${'_your'.tr()}',
                              ),
                          ],
                        ),
                      ),
                      Text(
                        distanceFormatter.showDistance(
                            distance: leaderBoardItem.totalDistance,
                            distanceUnit: DistanceFormatter.getDistanceUnit),
                        style: theme.textTheme.moMASans400Black12
                            .copyWith(color: MoMAColors.moMA12, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            forwardIcon: SvgPicture.asset(
              'assets/images/iconForward.svg',
              colorFilter: const ColorFilter.mode(
                  AppColor.primaryBlack, BlendMode.srcIn),
            ),
          ),
        ),
        addOnlyDivider(color: AppColor.auLightGrey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaderBoard = widget.leaderboard;
    if (leaderBoard == null) {
      return _loadingLeaderboard(context);
    }
    const listKey = PageStorageKey('leaderboard');
    return SizedBox(
      child: Column(
        children: [
          Expanded(
            child: PageStorage(
              bucket: _pageStorageBucket,
              child: ListView.builder(
                key: listKey,
                controller: widget.scrollController,
                itemCount: leaderBoard.items.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _leaderboardHeader(context);
                  }
                  final item = leaderBoard.items[index - 1];
                  final isYours = item.id == widget.assetToken?.tokenId;
                  return _leaderboardItem(context, item, isYour: isYours);
                },
                cacheExtent: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
