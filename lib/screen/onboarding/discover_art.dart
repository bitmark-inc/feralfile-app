import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/screen/feed/feed_preview_page.dart';
import 'package:autonomy_flutter/service/followee_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/add_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/tokens_service.dart';

class DiscoverArtPage extends StatefulWidget {
  static const String tag = 'discover_art';

  const DiscoverArtPage({Key? key}) : super(key: key);

  @override
  State<DiscoverArtPage> createState() => _DiscoverArtPageState();
}

class _DiscoverArtPageState extends State<DiscoverArtPage> {
  final List<AssetToken> _tokenList = [];

  @override
  void initState() {
    super.initState();
    _fetchSuggestedArtists();
  }

  Future<void> _fetchSuggestedArtists() async {
    final suggestedArtistList =
        await injector<PubdocAPI>().getSuggestedArtistsFromGithub();
    final tokens = await injector<TokensService>().fetchManualTokens(
        suggestedArtistList.map((e) => e.tokenIDs.first).toList());
    _tokenList.addAll(tokens);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    ListDiscoverArts(
                      tokenList: _tokenList,
                    ),
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
        ));
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

  const ListDiscoverArts({Key? key, required this.tokenList}) : super(key: key);

  @override
  State<ListDiscoverArts> createState() => _ListDiscoverArtsState();
}

class _ListDiscoverArtsState extends State<ListDiscoverArts> {
  final FolloweeService _followeeService = injector<FolloweeService>();
  final List<String> _followedList = [];

  @override
  Widget build(BuildContext context) {
    return widget.tokenList.isNotEmpty
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: Swiper(
              itemCount: widget.tokenList.length,
              itemBuilder: (context, index) {
                return _artView(
                  context,
                  widget.tokenList[index],
                );
              },
              pagination: const SwiperPagination(
                builder: DotSwiperPaginationBuilder(
                    color: AppColor.auLightGrey,
                    activeColor: AppColor.auSuperTeal,
                    size: 8),
              ),
              control: const SwiperControl(
                  color: Colors.transparent,
                  disableColor: Colors.transparent,
                  size: 0),
            ),
          )
        : const SizedBox();
  }

  Widget _artView(BuildContext context, AssetToken assetToken) {
    final theme = Theme.of(context);
    final artistID = assetToken.artistID ?? "";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Row(
            children: [
              Text(
                assetToken.artistName ?? assetToken.artistID ?? "",
                style: theme.textTheme.ppMori700White14,
              ),
              const Spacer(),
              if (artistID.isNotEmpty) ...[
                _followedList.contains(artistID)
                    ? RemoveButton(
                        color: AppColor.white,
                        onTap: () async {
                          final followees = await _followeeService
                              .getFromAddresses([artistID]);
                          if (followees.isNotEmpty) {
                            await _followeeService
                                .removeArtistManual(followees.first);
                            _followedList.remove(artistID);
                            setState(() {});
                          }
                        })
                    : AddButton(onTap: () async {
                        await _followeeService
                            .addArtistManual(assetToken.artistID ?? "");
                        _followedList.add(artistID);
                        setState(() {});
                      })
              ]
            ],
          ),
        ),
        const SizedBox(height: 15),
        FeedArtwork(assetToken: assetToken),
        const SizedBox(height: 5),
        Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Text(
            assetToken.title ?? "",
            style: theme.textTheme.ppMori400White14,
          ),
        ),
      ],
    );
  }
}
