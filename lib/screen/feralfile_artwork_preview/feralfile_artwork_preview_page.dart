import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';
import 'package:autonomy_flutter/util/series_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/artwork_title_view.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/feralfile_artwork_preview_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:backdrop/backdrop.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:sentry/sentry.dart';

class FeralFileArtworkPreviewPage extends StatefulWidget {
  const FeralFileArtworkPreviewPage({required this.payload, super.key});

  final FeralFileArtworkPreviewPagePayload payload;

  @override
  State<FeralFileArtworkPreviewPage> createState() =>
      _FeralFileArtworkPreviewPageState();
}

class _FeralFileArtworkPreviewPageState
    extends State<FeralFileArtworkPreviewPage>
    with
        AfterLayoutMixin<FeralFileArtworkPreviewPage>,
        SingleTickerProviderStateMixin {
  final _metricClient = injector.get<MetricClientService>();
  final _canvasDeviceBloc = injector.get<CanvasDeviceBloc>();
  late SubscriptionBloc _subscriptionBloc;
  late bool isCrystallineWork;

  double? _appBarBottomDy;
  static const _infoShrinkPosition = 0.001;
  static const _infoExpandPosition = 0.99;
  static const toolbarHeight = 66.0;
  bool _isInfoExpand = false;

  ScrollController? _scrollController;
  late AnimationController _animationController;

  void _sendViewArtworkEvent(Artwork artwork) {
    final data = {
      MixpanelProp.tokenId: artwork.metricTokenId,
    };
    _metricClient.addEvent(MixpanelEvent.viewArtwork, data: data);
  }

  @override
  void initState() {
    isCrystallineWork = widget.payload.artwork.series?.exhibitionID ==
        JohnGerrardHelper.exhibitionID;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
      value: _infoShrinkPosition,
      upperBound: _infoExpandPosition,
    );
    _infoShrink();
    super.initState();
    _subscriptionBloc = injector<SubscriptionBloc>();
    _subscriptionBloc.add(GetSubscriptionEvent());
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _appBarBottomDy ??= MediaQuery.of(context).padding.top + kToolbarHeight;
    _sendViewArtworkEvent(widget.payload.artwork);
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSubscribed = _subscriptionBloc.state.isSubscribed;
    return BackdropScaffold(
      appBar: _isInfoExpand
          ? const PreferredSize(
              preferredSize: Size.fromHeight(toolbarHeight),
              child: SizedBox(
                height: toolbarHeight,
              ),
            )
          : getFFAppBar(
              context,
              onBack: () => Navigator.pop(context),
              action: isSubscribed
                  ? FFCastButton(
                      displayKey:
                          widget.payload.artwork.series?.exhibitionID ?? '',
                      onDeviceSelected: _onDeviceSelected,
                    )
                  : null,
            ),
      backgroundColor: AppColor.primaryBlack,
      frontLayerBackgroundColor: AppColor.primaryBlack,
      backLayerBackgroundColor: AppColor.primaryBlack,
      frontLayerScrim: Colors.transparent,
      backLayerScrim: Colors.transparent,
      reverseAnimationCurve: Curves.ease,
      animationController: _animationController,
      revealBackLayerAtStart: true,
      subHeaderAlwaysActive: false,
      frontLayerShape: const BeveledRectangleBorder(),
      backLayer: Column(
        children: [
          Expanded(
            child: _buildArtworkPreview(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: ArtworkDetailsHeader(
              title: 'I',
              subTitle: 'I',
              color: Colors.transparent,
            ),
          ),
        ],
      ),
      frontLayer: _infoContent(context, widget.payload.artwork),
      subHeader: DecoratedBox(
        decoration: const BoxDecoration(color: AppColor.primaryBlack),
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            final dy = details.primaryVelocity ?? 0;
            if (dy <= 0) {
              _infoExpand();
            } else {
              _infoShrink();
            }
          },
          child: _infoHeader(context, widget.payload.artwork),
        ),
      ),
    );
  }

  Widget _buildArtworkPreview() {
    final artworkPreviewWidget = FeralfileArtworkPreviewWidget(
      payload: FeralFileArtworkPreviewWidgetPayload(
        artwork: widget.payload.artwork,
        isMute: false,
        isScrollable: widget.payload.artwork.isScrollablePreviewURL,
      ),
    );
    if (isCrystallineWork) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: artworkPreviewWidget,
          ),
        ),
      );
    }
    return artworkPreviewWidget;
  }

  Future<void> _onDeviceSelected(CanvasDevice device) async {
    final exhibitionId = widget.payload.artwork.series?.exhibitionID;
    if (exhibitionId == null) {
      await Sentry.captureMessage('Exhibition ID is null for artwork '
          '${widget.payload.artwork.id}');
    } else {
      final artworkId = widget.payload.artwork.id;
      final request = CastExhibitionRequest(
        exhibitionId: exhibitionId,
        catalog: ExhibitionCatalog.artwork,
        catalogId: artworkId,
      );
      _canvasDeviceBloc.add(CanvasDeviceCastExhibitionEvent(device, request));
    }
  }

  void _infoShrink() {
    setState(() {
      _isInfoExpand = false;
    });
    _animationController.animateTo(_infoShrinkPosition);
  }

  void _infoExpand() {
    _scrollController?.jumpTo(0);
    _scrollController ??= ScrollController();
    setState(() {
      _isInfoExpand = true;
    });
    _animationController.animateTo(_infoExpandPosition);
  }

  Widget _artworkInfoIcon() => Semantics(
        label: 'artworkInfoIcon',
        child: IconButton(
            onPressed: () {
              _isInfoExpand ? _infoShrink() : _infoExpand();
            },
            constraints: const BoxConstraints(
              maxWidth: 44,
              maxHeight: 44,
              minWidth: 44,
              minHeight: 44,
            ),
            icon: Padding(
              padding: const EdgeInsets.all(5),
              child: SvgPicture.asset(
                !_isInfoExpand
                    ? 'assets/images/info_white.svg'
                    : 'assets/images/info_white_active.svg',
                width: 22,
                height: 22,
              ),
            )),
      );

  Widget _infoHeader(BuildContext context, Artwork artwork) => Padding(
        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ArtworkTitleView(
                    artwork: artwork,
                  ),
                  if (isCrystallineWork) ...[
                    const SizedBox(height: 20),
                    ArtworkAttributesText(
                      artwork: artwork,
                    ),
                  ]
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 60),
              child: _artworkInfoIcon(),
            ),
          ],
        ),
      );

  Widget _infoContent(BuildContext context, Artwork artwork) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Visibility(
              visible: artwork.series!.mediumDescription != null,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: ResponsiveLayout.getPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.series!.mediumDescription ?? '',
                        style: theme.textTheme.ppMori400White14,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: ResponsiveLayout.getPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: 'Desc',
                    child: HtmlWidget(
                      customStylesBuilder: auHtmlStyle,
                      artwork.series!.description ?? '',
                      textStyle: theme.textTheme.ppMori400White14,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FFArtworkDetailsMetadataSection(artwork: artwork),
                  if (artwork.series?.exhibition != null)
                    ArtworkRightsView(
                      contractAddress: artwork
                          .getContract(artwork.series!.exhibition)
                          ?.address,
                      artworkID: artwork.id,
                      exhibitionID: artwork.series!.exhibitionID,
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeralFileArtworkPreviewPagePayload {
  final Artwork artwork;

  const FeralFileArtworkPreviewPagePayload({required this.artwork});
}
