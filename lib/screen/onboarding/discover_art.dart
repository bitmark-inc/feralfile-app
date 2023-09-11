import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/follow/follow_artist_bloc.dart';
import 'package:autonomy_flutter/screen/feed/feed_preview_page.dart';
import 'package:autonomy_flutter/screen/onboarding/discover_art_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/add_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_view/gif_view.dart';
import 'package:nft_collection/models/asset_token.dart';

class DiscoverArtPage extends StatefulWidget {
  static const String tag = 'discover_art';

  const DiscoverArtPage({Key? key}) : super(key: key);

  @override
  State<DiscoverArtPage> createState() => _DiscoverArtPageState();
}

class _DiscoverArtPageState extends State<DiscoverArtPage> {
  @override
  void initState() {
    super.initState();
    _fetchSuggestedArtists();
  }

  Future<void> _fetchSuggestedArtists() async {
    context.read<DiscoverArtBloc>().add(DiscoverArtFetchEvent());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
          appBar: AppBar(
            systemOverlayStyle: systemUiOverlayDarkStyle,
            toolbarHeight: 40,
            shadowColor: Colors.transparent,
            elevation: 0,
          ),
          backgroundColor: AppColor.primaryBlack,
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _header(context),
                      BlocBuilder<DiscoverArtBloc, DiscoverArtState>(
                          builder: (context, state) {
                        if (state.isLoading && state.tokenList.isEmpty) {
                          return Center(
                            child: GifView.asset(
                              "assets/images/loading_white.gif",
                              width: 52,
                              height: 52,
                              frameRate: 12,
                            ),
                          );
                        }
                        return BlocProvider.value(
                          value: FollowArtistBloc(injector()),
                          child: ListDiscoverArts(
                            tokenList: state.tokenList,
                            artistNames:
                                state.artistNames as Map<String, List<String>>,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Padding(
                  padding:
                      ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
                  child: PrimaryButton(
                    text: "continue".tr(),
                    onTap: () {
                      doneOnboarding(context);
                    },
                  ))
            ],
          )),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: ResponsiveLayout.pageHorizontalEdgeInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          addOnlyDivider(color: AppColor.white),
          Text(
            "discover_art".tr(),
            style: theme.textTheme.ppMori700White24.copyWith(fontSize: 36),
          ),
          const SizedBox(height: 30),
          Text(
            "discover_art_desc".tr(),
            style: theme.textTheme.ppMori400Grey12
                .copyWith(color: AppColor.auQuickSilver),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class ListDiscoverArts extends StatefulWidget {
  final List<AssetToken> tokenList;
  final Map<String, List<String>> artistNames;

  const ListDiscoverArts(
      {Key? key, required this.tokenList, required this.artistNames})
      : super(key: key);

  @override
  State<ListDiscoverArts> createState() => _ListDiscoverArtsState();
}

class _ListDiscoverArtsState extends State<ListDiscoverArts> {
  late final FollowArtistBloc _bloc;

  @override
  void initState() {
    super.initState();
    _fetchFollowedArtists();
  }

  Future<void> _fetchFollowedArtists() async {
    final artistIDs = widget.tokenList.map((e) => e.artistID ?? "").toList();
    artistIDs.removeWhere((element) => element == "");
    _bloc = context.read<FollowArtistBloc>();
    _bloc.add(FollowArtistFetchEvent(artistIDs));
  }

  @override
  Widget build(BuildContext context) {
    return widget.tokenList.isNotEmpty
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 570),
            child: BlocBuilder<FollowArtistBloc, FollowArtistState>(
                builder: (context, state) {
              return Swiper(
                itemCount: widget.tokenList.length,
                itemBuilder: (context, index) {
                  return _artView(
                      context,
                      widget.tokenList[index],
                      "${index + 1} / ${widget.tokenList.length}",
                      // need to handle multiple artists case
                      (widget.artistNames[widget.tokenList[index].id] ?? [""])
                          .first,
                      state.followStatus.firstWhereOrNull(
                        (element) =>
                            element.artistID ==
                            widget.tokenList[index].artistID,
                      ));
                },
                control: const SwiperControl(
                    color: Colors.transparent,
                    disableColor: Colors.transparent,
                    size: 0),
              );
            }),
          )
        : const SizedBox();
  }

  Widget _artView(BuildContext context, AssetToken assetToken, String page,
      String artistName, ArtistFollowStatus? status) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Row(
            children: [
              Text(
                artistName,
                style: theme.textTheme.ppMori700White14,
              ),
              const Spacer(),
              if (status != null) ...[
                _followButton(context, status),
              ]
            ],
          ),
        ),
        const SizedBox(height: 15),
        FeedArtwork(assetToken: assetToken),
        const SizedBox(height: 5),
        Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  assetToken.title ?? "",
                  style: theme.textTheme.ppMori400White14,
                ),
              ),
              Container(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    //width: double.infinity,
                    height: 28.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primaryBlack,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.0)),
                        side: const BorderSide(color: AppColor.white),
                        alignment: Alignment.center,
                      ),
                      onPressed: null,
                      child:
                          Text(page, style: theme.textTheme.ppMori400White14),
                    ),
                  ))
            ],
          ),
        ),
      ],
    );
  }

  Widget _followButton(BuildContext context, ArtistFollowStatus status) {
    switch (status.status) {
      case FollowStatus.unfollowed:
        return AddButton(onTap: () {
          _bloc.add(FollowEvent(status.artistID));
        });
      case FollowStatus.followed:
        return RemoveButton(
            color: AppColor.white,
            onTap: () {
              _bloc.add(UnfollowEvent(status.artistID));
            });

      default:
        return const SizedBox();
    }
  }
}
