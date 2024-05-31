import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/feralfile_artwork_preview_widget.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart';

class FeralFileArtworkPreviewPage extends StatefulWidget {
  const FeralFileArtworkPreviewPage({required this.payload, super.key});

  final FeralFileArtworkPreviewPagePayload payload;

  @override
  State<FeralFileArtworkPreviewPage> createState() =>
      _FeralFileArtworkPreviewPageState();
}

class _FeralFileArtworkPreviewPageState
    extends State<FeralFileArtworkPreviewPage> with AfterLayoutMixin {
  final _metricClient = injector.get<MetricClientService>();
  final _canvasDeviceBloc = injector.get<CanvasDeviceBloc>();

  void _sendViewArtworkEvent(Artwork artwork) {
    final data = {
      MixpanelProp.tokenId: artwork.metricTokenId,
    };
    _metricClient.addEvent(MixpanelEvent.viewArtwork, data: data);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _sendViewArtworkEvent(widget.payload.artwork);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getFFAppBar(
          context,
          onBack: () => Navigator.pop(context),
          action: FFCastButton(
            onDeviceSelected: _onDeviceSelected,
          ),
        ),
        backgroundColor: AppColor.primaryBlack,
        body: Column(
          children: [
            Expanded(
              child: FeralfileArtworkPreviewWidget(
                payload: FeralFileArtworkPreviewWidgetPayload(
                  artwork: widget.payload.artwork,
                  isMute: false,
                  isScrollable: widget.payload.artwork.isScrollablePreviewURL,
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _onDeviceSelected(CanvasDevice device) async {
    final exhibitionId = widget.payload.artwork.series?.exhibitionID;
    if (exhibitionId == null) {
      await Sentry.captureMessage('Exhibition ID is null for artwork '
          '${widget.payload.artwork.id}');
    } else {
      final artworkId = widget.payload.artwork.id;
      final request = CastExhibitionRequest(
        exhibitionId: exhibitionId,
        katalog: ExhibitionKatalog.ARTWORK,
        katalogId: artworkId,
      );
      _canvasDeviceBloc.add(CanvasDeviceCastExhibitionEvent(device, request));
    }
  }
}

class FeralFileArtworkPreviewPagePayload {
  final Artwork artwork;

  const FeralFileArtworkPreviewPagePayload({required this.artwork});
}
