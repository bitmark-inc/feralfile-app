import 'dart:async';
import 'dart:collection';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/detail/report_rendering_issue/any_problem_nft_widget.dart';
import 'package:autonomy_flutter/screen/detail/report_rendering_issue/report_rendering_issue_widget.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/jumping_dot.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';
import 'package:nft_rendering/nft_rendering.dart';

// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/injector.dart';

String getEditionSubTitle(AssetToken token) {
  if (token.editionName != null && token.editionName != "") {
    return token.editionName!;
  }
  if (token.edition == 0) return "";
  return token.maxEdition != null && token.maxEdition! >= 1
      ? tr('edition_of',
          args: [token.edition.toString(), token.maxEdition.toString()])
      : '${tr('edition')} ${token.edition}';
}

class PendingTokenWidget extends StatelessWidget {
  final String? thumbnail;
  final String? tokenId;

  const PendingTokenWidget({Key? key, this.thumbnail, this.tokenId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "pending: $tokenId",
      child: ClipPath(
        clipper: AutonomyTopRightRectangleClipper(),
        child: Container(
          color: AppColor.secondaryDimGreyBackground,
          child: Stack(
            children: [
              if (thumbnail?.isNotEmpty == true) ...[
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: thumbnail!,
                    fit: BoxFit.cover,
                  ),
                )
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.8,
                  vertical: 19.26,
                ),
                child: const Align(
                    alignment: Alignment.bottomLeft,
                    child: JumpingDots(
                      color: AppColor.secondaryDimGrey,
                      radius: 3.2,
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class TokenThumbnailWidget extends StatelessWidget {
  final AssetToken token;
  final Function? onHideArtwork;

  const TokenThumbnailWidget({
    Key? key,
    required this.token,
    this.onHideArtwork,
  }) : super(key: key);

  Widget _buildContent(
      {required String ext,
      required double screenWidth,
      required int attempt}) {
    final thumbnailUrl = token.getThumbnailUrl();
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
      return const AspectRatio(
        aspectRatio: 1,
        child: GalleryNoThumbnailWidget(),
      );
    }

    return Hero(
      tag: token.id,
      child: ext == ".svg"
          ? Center(
              child: SvgImage(
                url: thumbnailUrl,
                fallbackToWebView: true,
                loadingWidgetBuilder: (context) => placeholder(context),
                errorWidgetBuilder: (_) => const GalleryThumbnailErrorWidget(),
                unsupportWidgetBuilder: (context) => GalleryUnSupportWidget(
                  onHideArtwork: () => onHideArtwork?.call(),
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: attempt > 0
                  ? "${token.getThumbnailUrl() ?? ''}?t=$attempt"
                  : token.getThumbnailUrl() ?? "",
              width: double.infinity,
              memCacheWidth: (screenWidth * 3).floor(),
              maxWidthDiskCache: (screenWidth * 3).floor(),
              cacheManager: injector<CacheManager>(),
              placeholder: (context, url) => placeholder(context),
              placeholderFadeInDuration: const Duration(milliseconds: 300),
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: const Color.fromRGBO(227, 227, 227, 1),
                  padding: const EdgeInsets.symmetric(vertical: 133),
                  child: BrokenTokenWidget(token: token),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = p.extension(token.getThumbnailUrl() ?? "");
    final screenWidth = MediaQuery.of(context).size.width;
    return BlocProvider(
      create: (_) => RetryCubit(),
      child: BlocBuilder<RetryCubit, int>(
        builder: (context, state) => _buildContent(
          ext: ext,
          screenWidth: screenWidth,
          attempt: state,
        ),
      ),
    );
  }
}

final Map<String, Future<bool>> _cachingStates = {};

Widget tokenGalleryThumbnailWidget(
    BuildContext context, AssetToken token, int cachedImageSize) {
  final thumbnailUrl = token.getGalleryThumbnailUrl();
  if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
    return const GalleryNoThumbnailWidget();
  }

  final ext = p.extension(thumbnailUrl);

  final cacheManager = injector<CacheManager>();

  Future<bool> cachingState = _cachingStates[thumbnailUrl] ??
      cacheManager.store.retrieveCacheData(thumbnailUrl).then((cachedObject) {
        final cached = cachedObject != null;
        if (cached) {
          _cachingStates[thumbnailUrl] = Future.value(true);
        }
        return cached;
      });

  return Semantics(
    label: token.title,
    child: Hero(
      tag: token.id,
      key: const Key('Artwork_Thumbnail'),
      child: ext == ".svg"
          ? SvgImage(
              url: thumbnailUrl,
              loadingWidgetBuilder: (_) => const GalleryThumbnailPlaceholder(),
              errorWidgetBuilder: (_) => const GalleryThumbnailErrorWidget(),
              unsupportWidgetBuilder: (context) =>
                  const GalleryUnSupportThumbnailWidget(),
            )
          : CachedNetworkImage(
              imageUrl: thumbnailUrl,
              fadeInDuration: Duration.zero,
              fit: BoxFit.cover,
              memCacheHeight: cachedImageSize,
              memCacheWidth: cachedImageSize,
              maxWidthDiskCache: cachedImageSize,
              maxHeightDiskCache: cachedImageSize,
              cacheManager: cacheManager,
              placeholder: (context, index) => FutureBuilder<bool>(
                  future: cachingState,
                  builder: (context, snapshot) {
                    return GalleryThumbnailPlaceholder(
                      loading: !(snapshot.data ?? true),
                    );
                  }),
              errorWidget: (context, url, error) =>
                  const GalleryThumbnailErrorWidget(),
            ),
    ),
  );
}

Widget tokenGalleryWidget(
  BuildContext context,
  AssetToken token,
  int cachedImageSize,
) {
  final thumbnailUrl = token.getGalleryThumbnailUrl();
  if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
    return const GalleryNoThumbnailWidget();
  }

  final ext = p.extension(thumbnailUrl);

  final cacheManager = injector<CacheManager>();

  Future<bool> cachingState = _cachingStates[thumbnailUrl] ??
      cacheManager.store.retrieveCacheData(thumbnailUrl).then((cachedObject) {
        final cached = cachedObject != null;
        if (cached) {
          _cachingStates[thumbnailUrl] = Future.value(true);
        }
        return cached;
      });

  return Semantics(
    label: token.title,
    child: ext == ".svg"
        ? SvgImage(
            url: thumbnailUrl,
            loadingWidgetBuilder: (_) => const GalleryThumbnailPlaceholder(),
            errorWidgetBuilder: (_) => const GalleryThumbnailErrorWidget(),
            unsupportWidgetBuilder: (context) =>
                const GalleryUnSupportThumbnailWidget(),
          )
        : CachedNetworkImage(
            imageUrl: thumbnailUrl,
            fadeInDuration: Duration.zero,
            fit: BoxFit.cover,
            memCacheHeight: cachedImageSize,
            memCacheWidth: cachedImageSize,
            maxWidthDiskCache: cachedImageSize,
            maxHeightDiskCache: cachedImageSize,
            cacheManager: cacheManager,
            placeholder: (context, index) => FutureBuilder<bool>(
                future: cachingState,
                builder: (context, snapshot) {
                  return GalleryThumbnailPlaceholder(
                    loading: !(snapshot.data ?? true),
                  );
                }),
            errorWidget: (context, url, error) =>
                const GalleryThumbnailErrorWidget(),
          ),
  );
}

class GalleryUnSupportWidget extends StatelessWidget {
  final String type;
  final Function()? onHideArtwork;

  const GalleryUnSupportWidget(
      {Key? key, this.type = '.svg', this.onHideArtwork})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return ClipPath(
      clipper: AutonomyTopRightRectangleClipper(),
      child: Container(
        width: size.width,
        height: size.width,
        padding: const EdgeInsets.all(13),
        color: const Color.fromRGBO(227, 227, 227, 1),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'unsupported_token'.tr(),
                    style: theme.textTheme.atlasGreyNormal14,
                  ),
                  Visibility(
                    visible: onHideArtwork != null,
                    child: GestureDetector(
                      onTap: onHideArtwork,
                      child: Text(
                        'hide_it_from_collection'.tr(),
                        style: theme.textTheme.atlasGreyNormal14.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.bottomStart,
              child: Text(
                type.toUpperCase(),
                style: theme.textTheme.ibmGreyNormal12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryUnSupportThumbnailWidget extends StatelessWidget {
  final String type;

  const GalleryUnSupportThumbnailWidget({Key? key, this.type = '.svg'})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return ClipPath(
      clipper: AutonomyTopRightRectangleClipper(),
      child: Container(
        width: size.width,
        height: size.width,
        padding: const EdgeInsets.all(13),
        color: const Color.fromRGBO(227, 227, 227, 1),
        child: Align(
          alignment: AlignmentDirectional.bottomStart,
          child: Text(
            type.toUpperCase(),
            style: theme.textTheme.ibmGreyNormal12,
          ),
        ),
      ),
    );
  }
}

class GalleryThumbnailErrorWidget extends StatelessWidget {
  const GalleryThumbnailErrorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipPath(
      clipper: AutonomyTopRightRectangleClipper(),
      child: Container(
        padding: const EdgeInsets.all(13.0),
        color: const Color.fromRGBO(227, 227, 227, 1),
        child: Align(
          alignment: AlignmentDirectional.bottomStart,
          child: Text(
            'IPFS!',
            style: theme.textTheme.ibmGreyNormal12,
          ),
        ),
      ),
    );
  }
}

class GalleryNoThumbnailWidget extends StatelessWidget {
  const GalleryNoThumbnailWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ClipPath(
      clipper: AutonomyTopRightRectangleClipper(),
      child: Container(
        padding: const EdgeInsets.all(15.0),
        height: size.width,
        width: size.width,
        color: Colors.black,
      ),
    );
  }
}

class GalleryThumbnailPlaceholder extends StatelessWidget {
  final bool loading;

  const GalleryThumbnailPlaceholder({
    Key? key,
    this.loading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: ClipPath(
        clipper: loading ? AutonomyTopRightRectangleClipper() : null,
        child: Container(
          padding: const EdgeInsets.all(13),
          color: const Color.fromRGBO(227, 227, 227, 1),
          child: Visibility(
            visible: loading,
            child: Align(
              alignment: AlignmentDirectional.bottomStart,
              child: loadingIndicator(
                size: 13,
                valueColor: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget placeholder(BuildContext context) {
  final theme = Theme.of(context);
  return AspectRatio(
    aspectRatio: 1,
    child: Container(
      color: const Color.fromRGBO(227, 227, 227, 1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loadingIndicator(valueColor: theme.colorScheme.primary),
            const SizedBox(
              height: 12,
            ),
            Text(
              "loading...".tr(),
              style: ResponsiveLayout.isMobile
                  ? theme.textTheme.atlasGreyNormal12
                  : theme.textTheme.atlasGreyNormal14,
            ),
          ],
        ),
      ),
    ),
  );
}

class ReportButton extends StatefulWidget {
  final AssetToken? token;
  final ScrollController scrollController;

  const ReportButton({
    Key? key,
    this.token,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<ReportButton> {
  bool isShowingArtwortReportProblemContainer = true;

  _scrollListener() {
    /*
    So we see it like that when we are at the top of the page.
    When we start scrolling down it disappears and we see it again attached at the bottom of the page.
    And if we scroll all the way up again, we would display again it attached down the screen
    https://www.figma.com/file/Ze71GH9ZmZlJwtPjeHYZpc?node-id=51:5175#159199971
    */
    if (widget.scrollController.offset > 80) {
      setState(() {
        isShowingArtwortReportProblemContainer = false;
      });
    } else {
      setState(() {
        isShowingArtwortReportProblemContainer = true;
      });
    }

    if (widget.scrollController.position.pixels + 100 >=
        widget.scrollController.position.maxScrollExtent) {
      setState(() {
        isShowingArtwortReportProblemContainer = true;
      });
    }
  }

  @override
  void initState() {
    widget.scrollController.addListener(_scrollListener);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token == null) return const SizedBox();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isShowingArtwortReportProblemContainer ? 62 : 0,
      child: AnyProblemNFTWidget(
        asset: widget.token!,
      ),
    );
  }
}

INFTRenderingWidget buildRenderingWidget(
  BuildContext context,
  AssetToken token, {
  int? attempt,
  Function({int? time})? onLoaded,
  Function({int? time})? onDispose,
}) {
  String mimeType = "";
  switch (token.medium) {
    case "image":
      final ext = p.extension(token.getPreviewUrl() ?? "");
      if (ext == ".svg") {
        mimeType = "svg";
      } else if (token.mimeType == 'image/gif') {
        mimeType = "gif";
      } else {
        mimeType = "image";
      }
      break;
    case "video":
      mimeType = "video";
      break;
    default:
      if (token.mimeType?.startsWith("audio/") == true) {
        mimeType = "audio";
      } else {
        mimeType = token.mimeType ?? "";
      }
  }
  final renderingWidget = typesOfNFTRenderingWidget(mimeType);

  renderingWidget.setRenderWidgetBuilder(RenderingWidgetBuilder(
    previewURL: attempt == null
        ? token.getPreviewUrl()
        : "${token.getPreviewUrl()}?t=$attempt",
    thumbnailURL: token.getThumbnailUrl(),
    loadingWidget: previewPlaceholder(context),
    errorWidget: BrokenTokenWidget(token: token),
    cacheManager: injector<CacheManager>(),
    onLoaded: onLoaded,
    onDispose: onDispose,
  ));

  return renderingWidget;
}

class RetryCubit extends Cubit<int> {
  RetryCubit() : super(0);

  void refresh() {
    emit(state + 1);
  }
}

class BrokenTokenWidget extends StatefulWidget {
  final AssetToken token;

  const BrokenTokenWidget({Key? key, required this.token}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BrokenTokenWidgetState();
  }
}

class _BrokenTokenWidgetState extends State<BrokenTokenWidget> {
  @override
  void initState() {
    injector<CustomerSupportService>().reportIPFSLoadingError(widget.token);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          "unable_to_load_artwork_preview_from_ipfs".tr(),
          style: ResponsiveLayout.isMobile
              ? theme.textTheme.atlasGreyNormal12
              : theme.textTheme.atlasGreyNormal14,
        ),
        TextButton(
          onPressed: () => context.read<RetryCubit>().refresh(),
          style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.all(8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Text("please_try_again".tr(),
              style: makeLinkStyle(
                ResponsiveLayout.isMobile
                    ? theme.textTheme.atlasGreyNormal12
                    : theme.textTheme.atlasGreyNormal14,
              )),
        ),
      ]),
    );
  }
}

void showReportIssueDialog(BuildContext context, AssetToken token) {
  UIHelper.showDialog(
    context,
    'report_issue'.tr(),
    ReportRenderingIssueWidget(
      token: token,
      onReported: (githubURL) =>
          _showReportRenderingDialogSuccess(context, githubURL),
    ),
  );
}

void _showReportRenderingDialogSuccess(BuildContext context, String githubURL) {
  final theme = Theme.of(context);
  UIHelper.showDialog(
    context,
    'share_with_artist'.tr(),
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "thank_for_report".tr(),
          style: theme.primaryTextTheme.bodyText1,
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: AuFilledButton(
                text: "share".tr(),
                onPress: () {
                  Share.share(githubURL).then((value) {
                    Navigator.of(context).pop();
                  });
                },
                color: theme.colorScheme.secondary,
                textStyle: theme.textTheme.button,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Align(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr(),
              style: theme.primaryTextTheme.button,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    ),
    isDismissible: true,
    feedback: FeedbackType.success,
  );
}

Widget previewPlaceholder(BuildContext context) {
  final theme = Theme.of(context);
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        loadingIndicator(
            valueColor: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondary.withOpacity(0.5)),
        const SizedBox(
          height: 13,
        ),
        Text(
          "loading...".tr(),
          style: ResponsiveLayout.isMobile
              ? theme.textTheme.atlasGreyNormal12
              : theme.textTheme.atlasGreyNormal14,
        ),
      ],
    ),
  );
}

Widget debugInfoWidget(BuildContext context, AssetToken? token) {
  final theme = Theme.of(context);

  if (token == null) return const SizedBox();

  return FutureBuilder<bool>(
      future: isAppCenterBuild().then((value) {
        if (value == false) return Future.value(false);

        return injector<ConfigurationService>().showTokenDebugInfo();
      }),
      builder: (context, snapshot) {
        if (snapshot.data == false) return const SizedBox();

        TextButton _buildInfo(String text, String value) {
          return TextButton(
            onPressed: () async {
              Vibrate.feedback(FeedbackType.light);
              final uri = Uri.tryParse(value);
              if (uri != null && await canLaunchUrl(uri)) {
                launchUrl(uri, mode: LaunchMode.inAppWebView);
              } else {
                Clipboard.setData(ClipboardData(text: value));
              }
            },
            child: Text('$text:  $value'),
          );
        }

        return Column(
          children: [
            addDivider(),
            Text(
              "debug_info".tr(),
              style: theme.textTheme.headline4,
            ),
            _buildInfo('IndexerID', token.id),
            _buildInfo(
                'galleryThumbnailURL', token.getGalleryThumbnailUrl() ?? ''),
            _buildInfo('thumbnailURL', token.getThumbnailUrl() ?? ''),
            _buildInfo('previewURL', token.getPreviewUrl() ?? ''),
            addDivider(),
          ],
        );
      });
}

Widget artworkDetailsRightSection(BuildContext context, AssetToken token) {
  return token.source == "feralfile"
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const SizedBox(height: 40.0), _artworkRightView(context)],
        )
      : const SizedBox();
}

Widget artworkDetailsMetadataSection(
    BuildContext context, AssetToken asset, String? artistName) {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "metadata".tr(),
        style: theme.textTheme.headline2,
      ),
      const SizedBox(height: 23.0),
      _rowItem(context, "title".tr(), asset.title),
      if (artistName != null) ...[
        const Divider(height: 32.0),
        _rowItem(
          context,
          "artist".tr(),
          artistName,
          // some FF's artist set multiple links
          // Discussion thread: https://bitmark.slack.com/archives/C01EPPD07HU/p1648698027564299
          tapLink: asset.artistURL?.split(" & ").first,
          forceSafariVC: true,
        ),
      ],
      (asset.fungible == false)
          ? Column(
              children: [
                const Divider(height: 32.0),
                _getEditionNameRow(context, asset),
              ],
            )
          : const SizedBox(),
      (asset.maxEdition ?? 0) > 0
          ? Column(
              children: [
                const Divider(height: 32.0),
                _rowItem(
                    context, "edition_size".tr(), asset.maxEdition.toString()),
              ],
            )
          : const SizedBox(),
      const Divider(height: 32.0),
      _rowItem(
        context,
        "token".tr(),
        polishSource(asset.source ?? ""),
        tapLink: asset.isAirdrop ? null : asset.assetURL,
        forceSafariVC: true,
      ),
      const Divider(height: 32.0),
      _rowItem(
        context,
        "contract".tr(),
        asset.blockchain.capitalize(),
        tapLink: asset.getBlockchainUrl(),
        forceSafariVC: true,
      ),
      const Divider(height: 32.0),
      _rowItem(context, "medium".tr(), asset.medium?.capitalize()),
      const Divider(height: 32.0),
      _rowItem(
        context,
        "date_minted".tr(),
        asset.mintedAt != null
            ? localTimeStringFromISO8601(asset.mintedAt!)
            : null,
        maxLines: 1,
      ),
      asset.assetData != null && asset.assetData!.isNotEmpty
          ? Column(
              children: [
                const Divider(height: 32.0),
                _rowItem(context, "artwork_data".tr(), asset.assetData)
              ],
            )
          : const SizedBox(),
    ],
  );
}

Widget _getEditionNameRow(BuildContext context, AssetToken asset) {
  if (asset.editionName != null && asset.editionName != "") {
    return _rowItem(context, "edition_name".tr(), asset.editionName!);
  }
  return _rowItem(context, "edition_number".tr(), asset.edition.toString());
}

Widget tokenOwnership(
    BuildContext context, AssetToken asset, List<String> addresses) {
  final theme = Theme.of(context);

  int ownedTokens = asset.balance ?? 0;
  if (ownedTokens == 0) {
    ownedTokens = addresses.map((address) => asset.owners[address] ?? 0).sum;
    if (ownedTokens == 0) {
      ownedTokens = addresses.contains(asset.ownerAddress) ? 1 : 0;
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "token_ownership".tr(),
        style: theme.textTheme.headline2,
      ),
      const SizedBox(height: 23.0),
      Text(
        "how_many_editions_you_own".tr(),
        style: theme.textTheme.bodyText1,
      ),
      const SizedBox(height: 32.0),
      _rowItem(context, "editions".tr(), "${asset.maxEdition}",
          tapLink: asset.tokenURL, forceSafariVC: true),
      const Divider(height: 32.0),
      _rowItem(context, "owned".tr(), "$ownedTokens",
          tapLink: asset.tokenURL, forceSafariVC: true),
    ],
  );
}

Widget artworkDetailsProvenanceSectionNotEmpty(
    BuildContext context,
    List<Provenance> provenances,
    HashSet<String> youAddresses,
    Map<String, String> identityMap) {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 40.0),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "provenance".tr(),
            style: theme.textTheme.headline2,
          ),
          const SizedBox(height: 23.0),
          ...provenances.map((el) {
            final identity = identityMap[el.owner];
            final identityTitle = el.owner.toIdentityOrMask(identityMap);
            final youTitle = youAddresses.contains(el.owner) ? "_you".tr() : "";
            final provenanceTitle = "${identityTitle ?? ''}$youTitle";
            return Column(
              children: [
                _rowItem(
                  context,
                  provenanceTitle,
                  localTimeString(el.timestamp),
                  subTitle: el.blockchain.toUpperCase(),
                  tapLink: el.txURL,
                  onNameTap: () => identity != null
                      ? UIHelper.showIdentityDetailDialog(context,
                          name: identity, address: el.owner)
                      : null,
                  forceSafariVC: true,
                  title: Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          child: Text(
                            identityTitle ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headline4,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: youAddresses.contains(el.owner),
                        child: Text(
                          "_you".tr(),
                          style: theme.textTheme.headline4,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                ),
                const Divider(height: 32.0),
              ],
            );
          }).toList()
        ],
      ),
    ],
  );
}

Widget _artworkRightView(BuildContext context, {TextStyle? linkStyle}) {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "rights".tr(),
        style: theme.textTheme.headline2,
      ),
      const SizedBox(height: 23.0),
      Text(
        "ff_protect".tr(),
        style: theme.textTheme.bodyText1,
      ),
      const SizedBox(height: 18.0),
      TextButton(
        style: theme.textButtonNoPadding,
        onPressed: () => launchUrl(
            Uri.parse("https://feralfile.com/docs/artist-collector-rights")),
        child: Text(
          "learn_artist".tr(),
          style: linkStyle ??
              theme.textTheme.linkStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
      const SizedBox(height: 23.0),
      _artworkRightItem(context, "download".tr(), "download_text".tr()),
      const Divider(
        height: 32.0,
        color: AppColor.secondarySpanishGrey,
      ),
      _artworkRightItem(context, "display".tr(), "display_text".tr()),
      const Divider(
        height: 32.0,
        color: AppColor.secondarySpanishGrey,
      ),
      _artworkRightItem(context, "authenticate".tr(), "authenticate_text".tr()),
      const Divider(
        height: 32.0,
        color: AppColor.secondarySpanishGrey,
      ),
      _artworkRightItem(
          context, "loan_or_lease".tr(), "loan_or_lease_text".tr()),
      const Divider(
        height: 32.0,
        color: AppColor.secondarySpanishGrey,
      ),
      _artworkRightItem(
          context, "resell_or_transfer".tr(), "resell_or_transfer_text".tr()),
      const Divider(
        height: 32.0,
        color: AppColor.secondarySpanishGrey,
      ),
      _artworkRightItem(
          context, "remain_anonymous".tr(), "remain_anonymous_text".tr()),
      const Divider(
        height: 32.0,
        color: AppColor.secondarySpanishGrey,
      ),
      _artworkRightItem(context, "respect_artist_right".tr(),
          "respect_artist_right_text".tr()),
    ],
  );
}

Widget _artworkRightItem(BuildContext context, String name, String body) {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            name,
            style: theme.textTheme.headline4,
          ),
        ],
      ),
      const SizedBox(height: 16.0),
      Text(
        body,
        textAlign: TextAlign.start,
        style: theme.textTheme.bodyText1,
      ),
    ],
  );
}

Widget _rowItem(
  BuildContext context,
  String name,
  String? value, {
  String? subTitle,
  Function()? onNameTap,
  String? tapLink,
  bool? forceSafariVC,
  Function()? onValueTap,
  Widget? title,
  int maxLines = 2,
}) {
  if (onValueTap == null && tapLink != null) {
    final uri = Uri.parse(tapLink);
    onValueTap = () => launchUrl(uri,
        mode: forceSafariVC == true
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault);
  }
  final theme = Theme.of(context);

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onNameTap,
              child: title ?? Text(name, style: theme.textTheme.headline4),
            ),
            if (subTitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subTitle,
                style: ResponsiveLayout.isMobile
                    ? theme.textTheme.atlasBlackBold12
                    : theme.textTheme.atlasBlackBold14,
              ),
            ]
          ],
        ),
      ),
      Flexible(
        flex: 4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onValueTap,
                child: Semantics(
                  label: name,
                  child: Text(
                    value ?? '',
                    textAlign: TextAlign.end,
                    maxLines: maxLines,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: onValueTap != null
                        ? theme.textTheme.subtitle1
                        : ResponsiveLayout.isMobile
                            ? theme.textTheme.ibmGreyMediumNormal16
                            : theme.textTheme.ibmGreyMediumNormal20,
                  ),
                ),
              ),
            ),
            if (onValueTap != null) ...[
              const SizedBox(width: 8.0),
              SvgPicture.asset(
                'assets/images/iconForward.svg',
                color: theme.textTheme.bodyText1?.color,
              ),
            ]
          ],
        ),
      )
    ],
  );
}

Widget previewCloseIcon(BuildContext context) {
  final theme = Theme.of(context);
  return Semantics(
    label: "CloseArtwork",
    child: GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: closeIcon(color: theme.colorScheme.secondary),
    ),
  );
}

class ArtworkRightWidget extends StatelessWidget {
  const ArtworkRightWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final linkStyle = Theme.of(context).primaryTextTheme.linkStyle.copyWith(
          color: Colors.white,
          decorationColor: Colors.white,
        );
    return _artworkRightView(context, linkStyle: linkStyle);
  }
}

class FeralfileArtworkDetailsMetadataSection extends StatelessWidget {
  final Exhibition exhibition;

  const FeralfileArtworkDetailsMetadataSection({
    Key? key,
    required this.exhibition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = exhibition.airdropArtwork;
    final artist = exhibition.getArtist(artwork);
    final contract = exhibition.airdropContract;
    final df = DateFormat('yyyy-MMM-dd hh:mm');
    final mintDate = artwork?.createdAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "metadata".tr(),
          style: theme.textTheme.headline2,
        ),
        const SizedBox(height: 23.0),
        _rowItem(context, "title".tr(), artwork?.title),
        const Divider(
          height: 32.0,
          color: AppColor.secondarySpanishGrey,
        ),
        _rowItem(
          context,
          "artist".tr(),
          artist?.getDisplayName(),
          tapLink: "${Environment.feralFileAPIURL}/profiles/${artist?.id}",
        ),
        if (exhibition.maxEdition > 0) ...[
          const Divider(
            height: 32.0,
            color: AppColor.secondarySpanishGrey,
          ),
          _rowItem(
            context,
            "edition_size".tr(),
            exhibition.maxEdition.toString(),
          ),
        ],
        const Divider(
          height: 32.0,
          color: AppColor.secondarySpanishGrey,
        ),
        _rowItem(
          context,
          "token".tr(),
          "Feral File",
          tapLink:
              null, // "${Environment.feralFileAPIURL}/artworks/${artwork?.id}"
        ),
        const Divider(
          height: 32.0,
          color: AppColor.secondarySpanishGrey,
        ),
        _rowItem(
          context,
          "contract".tr(),
          contract?.blockchainType.capitalize() ?? '',
          tapLink: contract?.getBlockChainUrl(),
        ),
        const Divider(
          height: 32.0,
          color: AppColor.secondarySpanishGrey,
        ),
        _rowItem(
          context,
          "medium".tr(),
          artwork?.medium.capitalize() ?? "",
        ),
        const Divider(
          height: 32.0,
          color: AppColor.secondarySpanishGrey,
        ),
        _rowItem(
          context,
          "date_minted".tr(),
          mintDate != null ? df.format(mintDate).toUpperCase() : null,
          maxLines: 1,
        ),
      ],
    );
  }
}
