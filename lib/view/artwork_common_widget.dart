import 'dart:async';
import 'dart:collection';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/detail/report_rendering_issue/any_problem_nft_widget.dart';
import 'package:autonomy_flutter/screen/detail/report_rendering_issue/report_rendering_issue_widget.dart';
import 'package:autonomy_flutter/screen/detail/royalty/royalty_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
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
import 'package:flutter_markdown/flutter_markdown.dart';
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
                  ? "${token.getThumbnailUrl(usingThumbnailID: false) ?? ''}?t=$attempt"
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
              errorWidget: (context, url, error) => CachedNetworkImage(
                imageUrl:
                    token.getGalleryThumbnailUrl(usingThumbnailID: false) ?? "",
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
            errorWidget: (context, url, error) => CachedNetworkImage(
              imageUrl:
                  token.getGalleryThumbnailUrl(usingThumbnailID: false) ?? "",
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
      height: isShowingArtwortReportProblemContainer ? 80 : 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: AnyProblemNFTWidget(
          asset: widget.token!,
        ),
      ),
    );
  }
}

INFTRenderingWidget buildRenderingWidget(
  BuildContext context,
  AssetToken token, {
  int? attempt,
  String? overriddenHtml,
  bool isMute = false,
  Function({int? time})? onLoaded,
  Function({int? time})? onDispose,
  FocusNode? focusNode,
  Widget? loadingWidget,
}) {
  String mimeType = token.getMimeType;

  final renderingWidget = typesOfNFTRenderingWidget(mimeType);

  renderingWidget.setRenderWidgetBuilder(RenderingWidgetBuilder(
    previewURL: attempt == null
        ? token.getPreviewUrl()
        : "${token.getPreviewUrl()}?t=$attempt",
    thumbnailURL: token.getThumbnailUrl(usingThumbnailID: false),
    loadingWidget: loadingWidget ?? previewPlaceholder(context),
    errorWidget: BrokenTokenWidget(token: token),
    cacheManager: injector<CacheManager>(),
    onLoaded: onLoaded,
    onDispose: onDispose,
    overriddenHtml: overriddenHtml,
    skipViewport:
        token.contractAddress == 'KT1RcZU4sphiF4b2mxW7zGkrfV8S2puKBFT3',
    isMute: isMute,
    focusNode: focusNode,
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
  final mixPanelClient = injector.get<MixPanelClientService>();

  @override
  void initState() {
    injector<CustomerSupportService>().reportIPFSLoadingError(widget.token);
    mixPanelClient.trackEvent(
      MixpanelEvent.displayUnableLoadIPFS,
      data: {'id': widget.token.id},
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            "unable_to_load_artwork_preview_from_ipfs".tr(),
            style: ResponsiveLayout.isMobile
                ? theme.textTheme.atlasGreyNormal12
                : theme.textTheme.atlasGreyNormal14,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          TextButton(
            onPressed: () {
              mixPanelClient.trackEvent(
                MixpanelEvent.clickLoadIPFSAgain,
                data: {'id': widget.token.id},
              );
              context.read<RetryCubit>().refresh();
            },
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
      ),
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
  return const PreviewPlaceholder();
}

class PreviewPlaceholder extends StatefulWidget {
  const PreviewPlaceholder({
    Key? key,
  }) : super(key: key);

  @override
  State<PreviewPlaceholder> createState() => _PreviewPlaceholderState();
}

class _PreviewPlaceholderState extends State<PreviewPlaceholder> {
  final mixPanelClient = injector.get<MixPanelClientService>();

  @override
  void initState() {
    mixPanelClient.timerEvent(
      MixpanelEvent.showLoadingArtwork,
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    mixPanelClient.trackEvent(
      MixpanelEvent.showLoadingArtwork,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loadingIndicator(
                valueColor: theme.colorScheme.surface,
                backgroundColor: theme.colorScheme.surface.withOpacity(0.5)),
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
      ),
    );
  }
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

        TextButton buildInfo(String text, String value) {
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
            buildInfo('IndexerID', token.id),
            buildInfo(
                'galleryThumbnailURL', token.getGalleryThumbnailUrl() ?? ''),
            buildInfo('thumbnailURL', token.getThumbnailUrl() ?? ''),
            buildInfo('previewURL', token.getPreviewUrl() ?? ''),
            addDivider(),
          ],
        );
      });
}

Widget artworkDetailsRightSection(BuildContext context, AssetToken token) {
  return token.source == "feralfile"
      ? ArtworkRightsView(
          contract: FFContract("", "", token.contractAddress ?? ""),
          editionID: token.id.split("-").last,
        )
      : const SizedBox();
}

Widget artworkDetailsMetadataSection(
    BuildContext context, AssetToken asset, String? artistName) {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      HeaderData(
        text: "metadata".tr(),
      ),
      const SizedBox(height: 23.0),
      MetaDataItem(
        title: "title".tr(),
        value: asset.title,
      ),
      if (artistName != null) ...[
        Divider(
          height: 32.0,
          color: theme.auLightGrey,
        ),
        MetaDataItem(
          title: "artist".tr(),
          value: artistName,
          tapLink: asset.artistURL?.split(" & ").firstOrNull,
          forceSafariVC: true,
        ),
      ],
      (asset.fungible == false)
          ? Column(
              children: [
                Divider(
                  height: 32.0,
                  color: theme.auLightGrey,
                ),
                _getEditionNameRow(context, asset),
              ],
            )
          : const SizedBox(),
      (asset.maxEdition ?? 0) > 0
          ? Column(
              children: [
                Divider(
                  height: 32.0,
                  color: theme.auLightGrey,
                ),
                MetaDataItem(
                  title: "edition_size".tr(),
                  value: asset.maxEdition.toString(),
                ),
              ],
            )
          : const SizedBox(),
      Divider(
        height: 32.0,
        color: theme.auLightGrey,
      ),
      MetaDataItem(
        title: "token".tr(),
        value: polishSource(asset.source ?? ""),
        tapLink: asset.isAirdrop ? null : asset.assetURL,
        forceSafariVC: true,
      ),
      Divider(
        height: 32.0,
        color: theme.auLightGrey,
      ),
      MetaDataItem(
        title: "contract".tr(),
        value: asset.blockchain.capitalize(),
        tapLink: asset.getBlockchainUrl(),
        forceSafariVC: true,
      ),
      Divider(
        height: 32.0,
        color: theme.auLightGrey,
      ),
      MetaDataItem(
        title: "medium".tr(),
        value: asset.medium?.capitalize() ?? '',
      ),
      Divider(
        height: 32.0,
        color: theme.auLightGrey,
      ),
      MetaDataItem(
        title: "date_minted".tr(),
        value: asset.mintedAt != null
            ? localTimeStringFromISO8601(asset.mintedAt!)
            : '',
      ),
      asset.assetData != null && asset.assetData!.isNotEmpty
          ? Column(
              children: [
                const Divider(height: 32.0),
                MetaDataItem(
                  title: "artwork_data".tr(),
                  value: asset.assetData!,
                )
              ],
            )
          : const SizedBox(),
    ],
  );
}

Widget _getEditionNameRow(BuildContext context, AssetToken asset) {
  if (asset.editionName != null && asset.editionName != "") {
    return MetaDataItem(
      title: "edition_name".tr(),
      value: asset.editionName!,
    );
  }
  return MetaDataItem(
    title: "edition_number".tr(),
    value: asset.edition.toString(),
  );
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
        style: theme.textTheme.ppMori400White12,
      ),
      const SizedBox(height: 23.0),
      Text(
        "how_many_editions_you_own".tr(),
        style: theme.textTheme.ppMori400White12,
      ),
      const SizedBox(height: 32.0),
      MetaDataItem(
        title: "editions".tr(),
        value: "${asset.maxEdition}",
        tapLink: asset.tokenURL,
        forceSafariVC: true,
      ),
      Divider(
        height: 32.0,
        color: theme.auLightGrey,
      ),
      MetaDataItem(
        title: "owned".tr(),
        value: "$ownedTokens",
        tapLink: asset.tokenURL,
        forceSafariVC: true,
      ),
    ],
  );
}

class MetaDataItem extends StatelessWidget {
  final String title;
  final String value;
  final Function()? onTap;
  final String? tapLink;
  final bool? forceSafariVC;

  const MetaDataItem({
    Key? key,
    required this.title,
    required this.value,
    this.onTap,
    this.tapLink,
    this.forceSafariVC,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Function()? onValueTap = onTap;

    if (onValueTap == null && tapLink != null) {
      final uri = Uri.parse(tapLink!);
      onValueTap = () => launchUrl(uri,
          mode: forceSafariVC == true
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault);
    }
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: theme.textTheme.ppMori400Grey12,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: onValueTap,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: onValueTap != null
                  ? theme.textTheme.ppMori400SupperTeal12
                  : theme.textTheme.ppMori400White12,
            ),
          ),
        ),
      ],
    );
  }
}

class ProvenanceItem extends StatelessWidget {
  final String title;
  final String value;
  final Function()? onTap;
  final Function()? onNameTap;
  final String? tapLink;
  final bool? forceSafariVC;

  const ProvenanceItem({
    Key? key,
    required this.title,
    required this.value,
    this.onTap,
    this.tapLink,
    this.forceSafariVC,
    this.onNameTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Function()? onValueTap = onTap;

    if (onValueTap == null && tapLink != null) {
      final uri = Uri.parse(tapLink!);
      onValueTap = () => launchUrl(uri,
          mode: forceSafariVC == true
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault);
    }
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: onNameTap,
            child: Text(
              title,
              style: theme.textTheme.ppMori400White12,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: theme.textTheme.ppMori400White12,
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onValueTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.auSuperTeal,
                    ),
                    borderRadius: BorderRadius.circular(64),
                  ),
                  child: Text(
                    'view'.tr(),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.ppMori400Green12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HeaderData extends StatelessWidget {
  final String text;

  const HeaderData({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: theme.colorScheme.secondary,
          thickness: 1,
        ),
        Row(
          children: [
            Text(
              text,
              style: theme.textTheme.ppMori400White14,
            ),
            const Spacer(),
            RotatedBox(
              quarterTurns: 1,
              child: Icon(
                AuIcon.chevron_Sm,
                size: 12,
                color: theme.colorScheme.secondary,
              ),
            )
          ],
        ),
      ],
    );
  }
}

Widget artworkDetailsProvenanceSectionNotEmpty(
    BuildContext context,
    List<Provenance> provenances,
    HashSet<String> youAddresses,
    Map<String, String> identityMap) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 40.0),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderData(
            text: "provenance".tr(),
          ),
          const SizedBox(height: 23.0),
          ...provenances.map((el) {
            final identity = identityMap[el.owner];
            final identityTitle = el.owner.toIdentityOrMask(identityMap);
            final youTitle = youAddresses.contains(el.owner) ? "_you".tr() : "";
            return Column(
              children: [
                ProvenanceItem(
                  title: (identityTitle ?? '') + youTitle,
                  value: localTimeString(el.timestamp),
                  // subTitle: el.blockchain.toUpperCase(),
                  tapLink: el.txURL,
                  onNameTap: () => identity != null
                      ? UIHelper.showIdentityDetailDialog(context,
                          name: identity, address: el.owner)
                      : null,
                  forceSafariVC: true,
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

class ArtworkRightsView extends StatefulWidget {
  final TextStyle? linkStyle;
  final FFContract contract;
  final String? editionID;
  final String? exhibitionID;

  const ArtworkRightsView(
      {Key? key,
      this.linkStyle,
      required this.contract,
      this.editionID,
      this.exhibitionID})
      : super(key: key);

  @override
  State<ArtworkRightsView> createState() => _ArtworkRightsViewState();
}

class _ArtworkRightsViewState extends State<ArtworkRightsView> {
  @override
  void initState() {
    super.initState();
    context.read<RoyaltyBloc>().add(GetRoyaltyInfoEvent(
        exhibitionID: widget.exhibitionID,
        editionID: widget.editionID,
        contractAddress: widget.contract.address));
  }

  String getUrl(RoyaltyState state) {
    if (state.exhibitionID != null) {
      return "$FF_ARTIST_COLLECTOR/${state.exhibitionID}";
    } else {
      return FF_ARTIST_COLLECTOR;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoyaltyBloc, RoyaltyState>(builder: (context, state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderData(
            text: "rights".tr(),
          ),
          const SizedBox(height: 23.0),
          state.markdownData == null
              ? const SizedBox()
              : Markdown(
                  key: const Key("rightsSection"),
                  data: state.markdownData!.replaceAll(".**", "**"),
                  softLineBreak: true,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(0),
                  styleSheet: markDownRightStyle(context),
                  onTapLink: (text, href, title) async {
                    if (href == null) return;
                    launchUrl(Uri.parse(href),
                        mode: LaunchMode.externalApplication);
                  }),
          const SizedBox(height: 23.0),
        ],
      );
    });
  }
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
              child:
                  title ?? Text(name, style: theme.textTheme.ppMori400White12),
            ),
            if (subTitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subTitle,
                style: ResponsiveLayout.isMobile
                    ? theme.textTheme.ppMori400White12
                    : theme.textTheme.ppMori400White14,
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
                        ? theme.textTheme.ppMori400White12
                        : ResponsiveLayout.isMobile
                            ? theme.textTheme.ppMori400White12
                            : theme.textTheme.ppMori400White12,
                  ),
                ),
              ),
            ),
            if (onValueTap != null) ...[
              const SizedBox(width: 8.0),
              SvgPicture.asset(
                'assets/images/iconForward.svg',
                color: theme.textTheme.ppMori400White12.color,
              ),
            ]
          ],
        ),
      )
    ],
  );
}

class ArtworkRightWidget extends StatelessWidget {
  final FFContract? contract;
  final String? exhibitionID;

  const ArtworkRightWidget(
      {Key? key, @required this.contract, this.exhibitionID})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final linkStyle = Theme.of(context).primaryTextTheme.linkStyle.copyWith(
          color: Colors.white,
          decorationColor: Colors.white,
        );
    return ArtworkRightsView(
      linkStyle: linkStyle,
      contract: FFContract("", "", ""),
      exhibitionID: exhibitionID,
    );
  }
}

class FeralfileArtworkDetailsMetadataSection extends StatelessWidget {
  final FFArtwork artwork;

  const FeralfileArtworkDetailsMetadataSection({
    Key? key,
    required this.artwork,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artist = artwork.artist;
    final contract = artwork.contract;
    final df = DateFormat('yyyy-MMM-dd hh:mm');
    final mintDate = artwork.createdAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "metadata".tr(),
          style: theme.textTheme.headline2,
        ),
        const SizedBox(height: 23.0),
        _rowItem(context, "title".tr(), artwork.title),
        const Divider(
          height: 32.0,
          color: AppColor.secondarySpanishGrey,
        ),
        _rowItem(
          context,
          "artist".tr(),
          artist.getDisplayName(),
          tapLink: "${Environment.feralFileAPIURL}/profiles/${artist.id}",
        ),
        if (artwork.maxEdition > 0) ...[
          const Divider(
            height: 32.0,
            color: AppColor.secondarySpanishGrey,
          ),
          _rowItem(
            context,
            "edition_size".tr(),
            artwork.maxEdition.toString(),
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
          // tapLink: "${Environment.feralFileAPIURL}/artworks/${artwork?.id}"
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
          artwork.medium.capitalize(),
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
