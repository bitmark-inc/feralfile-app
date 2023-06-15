import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/detail/royalty/royalty_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:gif_view/gif_view.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/provenance.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

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

class MintTokenWidget extends StatelessWidget {
  final String? thumbnail;
  final String? tokenId;

  const MintTokenWidget({Key? key, this.thumbnail, this.tokenId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: "gallery_artwork_${tokenId}_minting",
      child: Container(
        color: theme.auLightGrey,
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(child: SvgPicture.asset('assets/images/mint_icon.svg')),
            Align(
              alignment: AlignmentDirectional.bottomStart,
              child: Text(
                "minting_token".tr(),
                style: theme.textTheme.ppMori700QuickSilver8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PendingTokenWidget extends StatelessWidget {
  final String? thumbnail;
  final String? tokenId;

  const PendingTokenWidget({Key? key, this.thumbnail, this.tokenId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: "gallery_artwork_${tokenId}_pending",
      child: Container(
        color: theme.auLightGrey,
        padding: const EdgeInsets.all(10),
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
            ] else ...[
              Center(
                child: loadingIndicator(
                  size: 22,
                  strokeWidth: 1.5,
                  valueColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ],
            Align(
              alignment: AlignmentDirectional.bottomStart,
              child: Text(
                "pending_token".tr(),
                style: theme.textTheme.ppMori700QuickSilver8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final Map<String, Future<bool>> _cachingStates = {};

Widget tokenGalleryThumbnailWidget(
  BuildContext context,
  CompactedAssetToken token,
  int cachedImageSize, {
  bool usingThumbnailID = true,
  bool useHero = true,
}) {
  final thumbnailUrl =
      token.getGalleryThumbnailUrl(usingThumbnailID: usingThumbnailID);

  if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
    return GalleryNoThumbnailWidget(
      assetToken: token,
    );
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
    label: "gallery_artwork_${token.title}",
    child: Hero(
      tag: useHero
          ? "gallery_thumbnail_${token.id}_${token.owner}"
          : const Uuid().v4(),
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

class GalleryUnSupportThumbnailWidget extends StatelessWidget {
  final String type;

  const GalleryUnSupportThumbnailWidget({Key? key, this.type = '.svg'})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    return Container(
      width: size.width,
      height: size.width,
      padding: const EdgeInsets.all(10),
      color: theme.auLightGrey,
      child: Stack(
        children: [
          Center(
            child: SvgPicture.asset(
              'assets/images/unsupported_token.svg',
              width: 24,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Text(
              'unsupported_token'.tr(),
              style: theme.textTheme.ppMori700QuickSilver8,
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryThumbnailErrorWidget extends StatelessWidget {
  const GalleryThumbnailErrorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10.0),
      color: theme.auLightGrey,
      child: Stack(
        children: [
          Center(
            child: SvgPicture.asset(
              'assets/images/ipfs_error_icon.svg',
              width: 24,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Text(
              "IPFS_error".tr(),
              style: theme.textTheme.ppMori700QuickSilver8,
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryNoThumbnailWidget extends StatelessWidget {
  final CompactedAssetToken assetToken;

  const GalleryNoThumbnailWidget({Key? key, required this.assetToken})
      : super(key: key);

  String getAssetDefault() {
    switch (assetToken.getMimeType) {
      case RenderingType.modelViewer:
        return 'assets/images/icon_3d.svg';
      case RenderingType.webview:
        return 'assets/images/icon_software.svg';
      case RenderingType.video:
        return 'assets/images/icon_video.svg';
      default:
        return 'assets/images/no_thumbnail.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    return Container(
      height: size.width,
      width: size.width,
      padding: const EdgeInsets.all(10),
      color: theme.auLightGrey,
      child: Stack(
        children: [
          Center(
            child: SvgPicture.asset(
              getAssetDefault(),
              width: 24,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Text(
              "no_thumbnail".tr(),
              style: theme.textTheme.ppMori700QuickSilver8,
            ),
          ),
        ],
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
    return Semantics(
      label: loading ? "loading" : "",
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(10),
          color: theme.auLightGrey,
          child: Stack(
            children: [
              Visibility(
                visible: loading,
                child: Center(
                  child: loadingIndicator(
                    size: 22,
                    strokeWidth: 1.5,
                    valueColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                ),
              ),
              Visibility(
                visible: loading,
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Text(
                    "loading".tr(),
                    style: theme.textTheme.ppMori700QuickSilver8,
                  ),
                ),
              ),
            ],
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
      color: AppColor.primaryBlack,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GifView.asset(
              "assets/images/loading_white.gif",
              width: 52,
              height: 52,
              frameRate: 12,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              "loading...".tr(),
              style: ResponsiveLayout.isMobile
                  ? theme.textTheme.ppMori400White12
                  : theme.textTheme.ppMori400White14,
            ),
          ],
        ),
      ),
    ),
  );
}

INFTRenderingWidget buildRenderingWidget(
  BuildContext context,
  AssetToken assetToken, {
  int? attempt,
  String? overriddenHtml,
  bool isMute = false,
  Function({int? time})? onLoaded,
  Function({int? time})? onDispose,
  FocusNode? focusNode,
  Widget? loadingWidget,
}) {
  String mimeType = assetToken.getMimeType;

  final renderingWidget = typesOfNFTRenderingWidget(mimeType);

  renderingWidget.setRenderWidgetBuilder(RenderingWidgetBuilder(
    previewURL: attempt == null
        ? assetToken.getPreviewUrl()
        : "${assetToken.getPreviewUrl()}?t=$attempt",
    thumbnailURL: assetToken.getGalleryThumbnailUrl(usingThumbnailID: false),
    loadingWidget: loadingWidget ?? previewPlaceholder(context),
    errorWidget: BrokenTokenWidget(token: assetToken),
    cacheManager: injector<CacheManager>(),
    onLoaded: onLoaded,
    onDispose: onDispose,
    overriddenHtml: overriddenHtml,
    skipViewport: assetToken.scrollable ?? false,
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

class PreviewUnSupportedTokenWidget extends StatelessWidget {
  final AssetToken token;

  const PreviewUnSupportedTokenWidget({Key? key, required this.token})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: size.width,
      padding: const EdgeInsets.all(10),
      color: AppColor.auGreyBackground,
      child: Stack(
        children: [
          Center(
            child: SvgPicture.asset(
              'assets/images/unsupported_token.svg',
              width: 40,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Row(
              children: [
                Text(
                  'unsupported_token'.tr(),
                  style: theme.textTheme.ppMori700QuickSilver8
                      .copyWith(fontSize: 12),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    "hide_from_collection".tr(),
                    style: theme.textTheme.ppMori400Black12
                        .copyWith(color: AppColor.auSuperTeal),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
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
  final metricClient = injector.get<MetricClientService>();

  @override
  void initState() {
    injector<CustomerSupportService>().reportIPFSLoadingError(widget.token);
    metricClient.addEvent(
      MixpanelEvent.displayUnableLoadIPFS,
      data: {'id': widget.token.id},
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: size.width,
      padding: const EdgeInsets.all(10),
      color: AppColor.auGreyBackground,
      child: Stack(
        children: [
          Center(
            child: SvgPicture.asset(
              'assets/images/ipfs_error_icon.svg',
              width: 40,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Row(
              children: [
                Text(
                  'unable_to_load_artwork_preview_from_ipfs'.tr(),
                  style: theme.textTheme.ppMori700QuickSilver8
                      .copyWith(fontSize: 12),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    metricClient.addEvent(
                      MixpanelEvent.clickLoadIPFSAgain,
                      data: {'id': widget.token.id},
                    );
                    context.read<RetryCubit>().refresh();
                  },
                  child: Text(
                    "reload".tr(),
                    style: theme.textTheme.ppMori400Black12
                        .copyWith(color: AppColor.auSuperTeal),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
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
  final metricClient = injector.get<MetricClientService>();

  @override
  void initState() {
    metricClient.timerEvent(
      MixpanelEvent.showLoadingArtwork,
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    metricClient.addEvent(
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
            GifView.asset(
              "assets/images/loading_white.gif",
              width: 52,
              height: 52,
              frameRate: 12,
            ),
            const SizedBox(
              height: 13,
            ),
            Text(
              "loading...".tr(),
              style: ResponsiveLayout.isMobile
                  ? theme.textTheme.ppMori400White12
                  : theme.textTheme.ppMori400White14,
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
            child: Text(
              '$text:  $value',
              style: theme.textTheme.ppMori400White12,
            ),
          );
        }

        return Column(
          children: [
            addDivider(),
            Text(
              "debug_info".tr(),
              style: theme.textTheme.ppMori400White12,
            ),
            buildInfo('IndexerID', token.id),
            buildInfo(
                'galleryThumbnailURL', token.getGalleryThumbnailUrl() ?? ''),
            buildInfo('previewURL', token.getPreviewUrl() ?? ''),
            addDivider(),
          ],
        );
      });
}

Widget artworkDetailsRightSection(BuildContext context, AssetToken assetToken) {
  final artworkID =
      ((assetToken.swapped ?? false) && assetToken.originTokenInfoId != null)
          ? assetToken.originTokenInfoId
          : assetToken.id.split("-").last;
  if (assetToken.source == "feralfile") {
    return ArtworkRightsView(
      contract: FFContract("", "", assetToken.contractAddress ?? ""),
      artworkID: artworkID,
    );
  }
  if (assetToken.isPostcard) {
    return PostcardRightsView(
      editionID: artworkID,
    );
  }
  return const SizedBox();
}

class ListItemExpandedWidget extends StatefulWidget {
  final List<TextSpan> children;
  final int unexpandedCount;

  const ListItemExpandedWidget(
      {Key? key, required this.children, required this.unexpandedCount})
      : super(key: key);

  @override
  State<ListItemExpandedWidget> createState() => _ListItemExpandedWidgetState();
}

class _ListItemExpandedWidgetState extends State<ListItemExpandedWidget> {
  bool _isExpanded = false;

  Widget unexpanedWidget(BuildContext context) {
    final theme = Theme.of(context);
    final expandText = (widget.children.length - widget.unexpandedCount > 0)
        ? TextSpan(
            text: " +${widget.children.length - widget.unexpandedCount}",
            style: theme.textTheme.ppMori400SupperTeal12.copyWith(fontSize: 14),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                setState(() {
                  _isExpanded = true;
                });
              },
          )
        : const TextSpan();
    final subList = widget.children
        .sublist(0, min(widget.unexpandedCount, widget.children.length));
    return RichText(
      text: TextSpan(
        children: subList
            .mapIndexed((index, child) => [
                  child,
                  if (index != widget.children.length - 1)
                    TextSpan(
                      text: ", ",
                      style: theme.textTheme.ppMori400White14,
                    ),
                ])
            .flattened
            .toList()
          ..add(expandText),
      ),
    );
  }

  Widget expanedWidget(BuildContext context) {
    // final hideText = TextSpan(
    //   text: " -",
    //   style: Theme.of(context).textTheme.ppMori400White14,
    //   recognizer: TapGestureRecognizer()
    //     ..onTap = () {
    //       setState(() {
    //         _isExpanded = false;
    //       });
    //     },
    // );
    return RichText(
      text: TextSpan(
          children: widget.children
              .mapIndexed((index, child) => [
                    child,
                    if (index != widget.children.length - 1)
                      TextSpan(
                        text: ", ",
                        style: Theme.of(context).textTheme.ppMori400White14,
                      ),
                  ])
              .flattened
              .toList()
          // ..add(hideText),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isExpanded ? expanedWidget(context) : unexpanedWidget(context);
  }
}

class SectionExpandedWidget extends StatefulWidget {
  final String? header;
  final Widget? child;

  const SectionExpandedWidget({Key? key, this.header, this.child})
      : super(key: key);

  @override
  State<SectionExpandedWidget> createState() => _SectionExpandedWidgetState();
}

class _SectionExpandedWidgetState extends State<SectionExpandedWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(
              color: theme.colorScheme.secondary,
              thickness: 1,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Row(
                  children: [
                    Text(
                      widget.header ?? '',
                      style: theme.textTheme.ppMori400White16,
                    ),
                    const Spacer(),
                    RotatedBox(
                      quarterTurns: _isExpanded ? -1 : 1,
                      child: Icon(
                        AuIcon.chevron_Sm,
                        size: 12,
                        color: theme.colorScheme.secondary,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 23.0),
        Visibility(
          visible: _isExpanded,
          child: widget.child ?? const SizedBox(),
        )
      ],
    );
  }
}

Widget postcardDetailsMetadataSection(
    BuildContext context, AssetToken assetToken, List<String?> owners) {
  final theme = Theme.of(context);
  final ownersList = owners.whereNotNull().toList();
  return SectionExpandedWidget(
    header: "metadata".tr(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetaDataItem(
          title: "title".tr(),
          value: assetToken.title ?? '',
        ),
        if (ownersList.isNotEmpty) ...[
          Divider(
            height: 32.0,
            color: theme.auLightGrey,
          ),
          CustomMetaDataItem(
            title: "artists".tr(),
            content: ListItemExpandedWidget(
              children: [
                ...ownersList
                    .mapIndexed((index, artistName) => TextSpan(
                          text: artistName,
                          style: theme.textTheme.ppMori400White14,
                        ))
                    .toList(),
              ],
              unexpandedCount: 2,
            ),
          ),
        ],
        (assetToken.fungible == false)
            ? Column(
                children: [
                  Divider(
                    height: 32.0,
                    color: theme.auLightGrey,
                  ),
                  _getEditionNameRow(context, assetToken),
                ],
              )
            : const SizedBox(),
        Divider(
          height: 32.0,
          color: theme.auLightGrey,
        ),
        MetaDataItem(
          title: "token".tr(),
          value: polishSource(assetToken.source ?? ""),
          tapLink: assetToken.isAirdrop ? null : assetToken.assetURL,
          forceSafariVC: true,
        ),
        Divider(
          height: 32.0,
          color: theme.auLightGrey,
        ),
        MetaDataItem(
          title: "contract".tr(),
          value: assetToken.blockchain.capitalize(),
          tapLink: assetToken.getBlockchainUrl(),
          forceSafariVC: true,
        ),
        Divider(
          height: 32.0,
          color: theme.auLightGrey,
        ),
        MetaDataItem(
          title: "medium".tr(),
          value: assetToken.medium?.capitalize() ?? '',
        ),
        Divider(
          height: 32.0,
          color: theme.auLightGrey,
        ),
        MetaDataItem(
          title: "date_minted".tr(),
          value: assetToken.mintedAt != null
              ? localTimeString(assetToken.mintedAt!)
              : '',
        ),
        assetToken.assetData != null && assetToken.assetData!.isNotEmpty
            ? Column(
                children: [
                  const Divider(height: 32.0),
                  MetaDataItem(
                    title: "artwork_data".tr(),
                    value: assetToken.assetData!,
                  )
                ],
              )
            : const SizedBox(),
        const Divider(height: 32.0),
      ],
    ),
  );
}

Widget artworkDetailsMetadataSection(
    BuildContext context, AssetToken assetToken, String? artistName) {
  final theme = Theme.of(context);
  final artworkID =
      ((assetToken.swapped ?? false) && assetToken.originTokenInfoId != null)
          ? assetToken.originTokenInfoId ?? ""
          : assetToken.id.split("-").last;
  return SectionExpandedWidget(
    header: "metadata".tr(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetaDataItem(
          title: "title".tr(),
          value: assetToken.title ?? '',
        ),
        if (artistName != null) ...[
          Divider(
            height: 32.0,
            color: theme.auLightGrey,
          ),
          MetaDataItem(
            title: "artist".tr(),
            value: artistName,
            onTap: () {
              final metricClient = injector.get<MetricClientService>();

              metricClient.addEvent(MixpanelEvent.clickArtist, data: {
                'id': assetToken.id,
                'artistID': assetToken.artistID,
              });
              final uri = Uri.parse(
                  assetToken.artistURL?.split(" & ").firstOrNull ?? "");
              launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            forceSafariVC: true,
          ),
        ],
        (assetToken.fungible == false)
            ? Column(
                children: [
                  Divider(
                    height: 32.0,
                    color: theme.auLightGrey,
                  ),
                  _getEditionNameRow(context, assetToken),
                ],
              )
            : const SizedBox(),
        Divider(
          height: 32.0,
          color: theme.auLightGrey,
        ),
        MetaDataItem(
          title: "token".tr(),
          value: polishSource(assetToken.source ?? ""),
          tapLink: assetToken.isAirdrop ? null : assetToken.assetURL,
          forceSafariVC: true,
        ),
        Divider(
          height: 32.0,
          color: theme.auLightGrey,
        ),
        artworkID.isNotEmpty
            ? FutureBuilder<Exhibition?>(
                future: injector<FeralFileService>()
                    .getExhibitionFromTokenID(artworkID),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    return Column(
                      children: [
                        MetaDataItem(
                          title: "exhibition".tr(),
                          value: snapshot.data!.title,
                          tapLink: feralFileExhibitionUrl(snapshot.data!.slug),
                          forceSafariVC: true,
                        ),
                        Divider(
                          height: 32.0,
                          color: theme.auLightGrey,
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              )
            : const SizedBox(),
        MetaDataItem(
          title: "contract".tr(),
          value: assetToken.blockchain.capitalize(),
          tapLink: assetToken.getBlockchainUrl(),
          forceSafariVC: true,
        ),
        Divider(
          height: 32.0,
          color: theme.auLightGrey,
        ),
        MetaDataItem(
          title: "medium".tr(),
          value: assetToken.medium?.capitalize() ?? '',
        ),
        Divider(
          height: 32.0,
          color: theme.auLightGrey,
        ),
        MetaDataItem(
          title: "date_minted".tr(),
          value: assetToken.mintedAt != null
              ? localTimeString(assetToken.mintedAt!)
              : '',
        ),
        assetToken.assetData != null && assetToken.assetData!.isNotEmpty
            ? Column(
                children: [
                  const Divider(height: 32.0),
                  MetaDataItem(
                    title: "artwork_data".tr(),
                    value: assetToken.assetData!,
                  )
                ],
              )
            : const SizedBox(),
        const Divider(height: 32.0),
      ],
    ),
  );
}

Widget _getEditionNameRow(BuildContext context, AssetToken assetToken) {
  if (assetToken.editionName != null && assetToken.editionName != "") {
    return MetaDataItem(
      title: "edition".tr(),
      value: assetToken.editionName!,
    );
  }
  return MetaDataItem(
    title: "edition".tr(),
    value: assetToken.edition.toString(),
  );
}

Widget postcardOwnership(
    BuildContext context, AssetToken assetToken, List<String> addresses) {
  final theme = Theme.of(context);

  final sentTokens = injector<ConfigurationService>().getRecentlySentToken();
  final expiredTime = DateTime.now().subtract(SENT_ARTWORK_HIDE_TIME);

  final totalSentQuantity = sentTokens
      .where((element) =>
          element.tokenID == assetToken.id &&
          element.timestamp.isAfter(expiredTime))
      .fold<int>(
          0, (previousValue, element) => previousValue + element.sentQuantity);

  int ownedTokens = assetToken.balance ?? 0;
  if (ownedTokens == 0) {
    ownedTokens =
        addresses.map((address) => assetToken.owners[address] ?? 0).sum;
    if (ownedTokens == 0) {
      ownedTokens = addresses.contains(assetToken.owner) ? 1 : 0;
    }
  }

  if (ownedTokens > 0) {
    ownedTokens -= totalSentQuantity;
  }

  return SectionExpandedWidget(
    header: "token_ownership".tr(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "how_many_shares_you_own".tr(),
          style: theme.textTheme.ppMori400White14,
        ),
        const SizedBox(height: 32.0),
        MetaDataItem(
          title: "shares".tr(),
          value: "${assetToken.maxEdition}",
          tapLink: assetToken.tokenURL,
          forceSafariVC: true,
        ),
        Divider(
          height: 32.0,
          color: theme.auLightGrey,
        ),
        MetaDataItem(
          title: "owned".tr(),
          value: "$ownedTokens",
          tapLink: assetToken.tokenURL,
          forceSafariVC: true,
        ),
        const SizedBox(height: 16.0),
      ],
    ),
  );
}

Widget tokenOwnership(
    BuildContext context, AssetToken assetToken, Map<String, int> owners) {
  final theme = Theme.of(context);

  final sentTokens = injector<ConfigurationService>().getRecentlySentToken();
  final expiredTime = DateTime.now().subtract(SENT_ARTWORK_HIDE_TIME);

  int ownedTokens = assetToken.balance ?? 0;
  final ownerAddress = assetToken.owner;
  final List<MapEntry<String, int>> values = owners.entries.toList()
    ..sort((a, b) {
      return a.key == ownerAddress
          ? -1
          : b.key == ownerAddress
              ? 1
              : a.key.compareTo(b.key);
    });
  final tapLink = assetToken.tokenURL;

  final totalSentQuantity = sentTokens
      .where((element) =>
          element.tokenID == assetToken.id &&
          ownerAddress == element.address &&
          element.timestamp.isAfter(expiredTime))
      .fold<int>(
          0, (previousValue, element) => previousValue + element.sentQuantity);

  if (ownedTokens > 0) {
    ownedTokens -= totalSentQuantity;
  }

  return SectionExpandedWidget(
    header: "token_ownership".tr(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "how_many_editions_you_own".tr(),
          style: theme.textTheme.ppMori400White14,
        ),
        const SizedBox(height: 32.0),
        MetaDataItem(
          title: "editions".tr(),
          value: "${assetToken.maxEdition}",
          tapLink: assetToken.tokenURL,
          forceSafariVC: true,
        ),
        Divider(
          height: 32.0,
          color: theme.auLightGrey,
        ),
        MetaDataMultiItem(
          title: "owned".tr(),
          values: values,
          tapLink: tapLink,
          forceSafariVC: true,
        ),
      ],
    ),
  );
}

class CustomMetaDataItem extends StatelessWidget {
  final String title;
  final Widget content;
  final bool? forceSafariVC;

  const CustomMetaDataItem({
    Key? key,
    required this.title,
    required this.content,
    this.forceSafariVC,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: theme.textTheme.ppMori400Grey14,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Expanded(flex: 3, child: content),
      ],
    );
  }
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
            style: theme.textTheme.ppMori400Grey14,
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
                  ? theme.textTheme.ppMori400Green14
                  : theme.textTheme.ppMori400White14,
            ),
          ),
        ),
      ],
    );
  }
}

class MetaDataMultiItem extends StatelessWidget {
  final String title;
  final List<MapEntry<String, int>> values;
  final String? tapLink;
  final bool? forceSafariVC;

  const MetaDataMultiItem({
    Key? key,
    required this.title,
    required this.values,
    this.tapLink,
    this.forceSafariVC,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: theme.textTheme.ppMori400Grey14,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: values
                .map(
                  (e) => Column(
                    children: [
                      Row(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (tapLink != null &&
                                      tapLink!.isValidUrl()) {
                                    final uri = Uri.parse(tapLink!);
                                    launchUrl(uri,
                                        mode: forceSafariVC == true
                                            ? LaunchMode.externalApplication
                                            : LaunchMode.platformDefault);
                                  }
                                },
                                child: Text(
                                  e.value.toString(),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style:
                                      tapLink != null && tapLink!.isValidUrl()
                                          ? theme.textTheme.ppMori400Green14
                                          : theme.textTheme.ppMori400White14,
                                ),
                              ),
                              Text(
                                " (${e.key.maskOnly(5)})",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: theme.textTheme.ppMori400White14,
                              )
                            ],
                          ),
                        ],
                      ),
                      if (e != values.last)
                        const Divider(
                          color: AppColor.auLightGrey,
                        ),
                    ],
                  ),
                )
                .toList(),
          ),
        )
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
              style: theme.textTheme.ppMori400White14,
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
            style: theme.textTheme.ppMori400White14,
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
                    style: theme.textTheme.ppMori400Green14,
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
      SectionExpandedWidget(
        header: "provenance".tr(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...provenances.map((el) {
              final identity = identityMap[el.owner];
              final identityTitle = el.owner.toIdentityOrMask(identityMap);
              final youTitle =
                  youAddresses.contains(el.owner) ? "_you".tr() : "";
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
      ),
    ],
  );
}

class PostcardRightsView extends StatefulWidget {
  final TextStyle? linkStyle;
  final String? editionID;

  const PostcardRightsView({
    Key? key,
    this.linkStyle,
    this.editionID,
  }) : super(key: key);

  @override
  State<PostcardRightsView> createState() => _PostcardRightsViewState();
}

class _PostcardRightsViewState extends State<PostcardRightsView> {
  final dio = Dio(BaseOptions(
    connectTimeout: 2000,
  ));

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Response<String>>(
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data?.statusCode == 200) {
            return SectionExpandedWidget(
              header: "rights".tr(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Markdown(
                    key: const Key("rightsSection"),
                    data: snapshot.data!.data!.replaceAll(".**", "**"),
                    softLineBreak: true,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(0),
                    styleSheet: markDownRightStyle(context),
                    onTapLink: (text, href, title) async {
                      if (href == null) return;
                      launchUrl(Uri.parse(href),
                          mode: LaunchMode.externalApplication);
                    },
                  ),
                  const SizedBox(height: 23.0),
                ],
              ),
            );
          } else {
            return const SizedBox();
          }
        },
        future: dio.get<String>(
          POSTCARD_RIGHTS_DOCS,
        ));
  }
}

class ArtworkRightsView extends StatefulWidget {
  final TextStyle? linkStyle;
  final FFContract contract;
  final String? artworkID;
  final String? exhibitionID;

  const ArtworkRightsView(
      {Key? key,
      this.linkStyle,
      required this.contract,
      this.artworkID,
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
        artworkID: widget.artworkID,
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
      if (state.markdownData != null) {
        return SectionExpandedWidget(
          header: "rights".tr(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Markdown(
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
                },
              ),
              const SizedBox(height: 23.0),
            ],
          ),
        );
      } else {
        return const SizedBox();
      }
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
  final FFSeries series;

  const FeralfileArtworkDetailsMetadataSection({
    Key? key,
    required this.series,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artist = series.artist;
    final contract = series.contract;
    final df = DateFormat('yyyy-MMM-dd hh:mm');
    final mintDate = series.createdAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "metadata".tr(),
          style: theme.textTheme.displayMedium,
        ),
        const SizedBox(height: 23.0),
        _rowItem(context, "title".tr(), series.title),
        const Divider(
          height: 32.0,
          color: AppColor.secondarySpanishGrey,
        ),
        if (artist != null) ...[
          _rowItem(
            context,
            "artist".tr(),
            artist.getDisplayName(),
            tapLink: "${Environment.feralFileAPIURL}/profiles/${artist.id}",
          ),
          const Divider(
            height: 32.0,
            color: AppColor.secondarySpanishGrey,
          )
        ],
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
          series.medium.capitalize(),
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

class ExpandedWidget extends StatefulWidget {
  final Widget? header;
  final Widget? child;
  final Widget? unexpendedChild;

  const ExpandedWidget(
      {Key? key, this.header, this.child, this.unexpendedChild})
      : super(key: key);

  @override
  State<ExpandedWidget> createState() => _ExpandedWidgetState();
}

class _ExpandedWidgetState extends State<ExpandedWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              Expanded(child: widget.header ?? const SizedBox()),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: RotatedBox(
                  quarterTurns: _isExpanded ? 1 : 0,
                  child: const Icon(
                    AuIcon.chevron_Sm,
                    size: 12,
                    color: AppColor.primaryBlack,
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 23.0),
        if (_isExpanded)
          widget.child ?? const SizedBox()
        else
          widget.unexpendedChild ?? const SizedBox(),
      ],
    );
  }
}
