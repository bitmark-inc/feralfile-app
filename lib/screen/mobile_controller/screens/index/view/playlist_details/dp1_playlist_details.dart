import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/constants/ui_constants.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/dp1_call.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/intent.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/detail_page_appbar.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/playlist_item.dart';
import 'package:autonomy_flutter/service/dp1_playlist_service.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/dp1_playlist_grid_view.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DP1PlaylistDetailsScreenPayload {
  const DP1PlaylistDetailsScreenPayload({
    required this.playlist,
    this.backTitle,
  });

  final DP1Call playlist;
  final String? backTitle;
}

class DP1PlaylistDetailsScreen extends StatefulWidget {
  const DP1PlaylistDetailsScreen({required this.payload, super.key});

  final DP1PlaylistDetailsScreenPayload payload;

  @override
  State<DP1PlaylistDetailsScreen> createState() =>
      _DP1PlaylistDetailsScreenState();
}

class _DP1PlaylistDetailsScreenState extends State<DP1PlaylistDetailsScreen> {
  CanvasDeviceBloc get _canvasDeviceBloc => injector<CanvasDeviceBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
      bloc: _canvasDeviceBloc,
      builder: (context, state) {
        return Scaffold(
          appBar: DetailPageAppBar(
            title: widget.payload.backTitle ?? 'Playlists',
            actions: [
              FFCastButton(
                displayKey: widget.payload.playlist.id,
                onDeviceSelected: (device) {
                  _canvasDeviceBloc.add(
                    CanvasDeviceCastDP1PlaylistEvent(
                      device: device,
                      playlist: widget.payload.playlist,
                      intent: DP1Intent.displayNow(),
                    ),
                  );
                },
              )
            ],
          ),
          backgroundColor: AppColor.auGreyBackground,
          body: _body(context),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    final channel = injector<Dp1PlaylistService>()
        .getChannelByPlaylistId(widget.payload.playlist.id);
    final playlist = widget.payload.playlist;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: PlaylistAssetGridView(
            header: Column(
              children: [
                const SizedBox(height: UIConstants.detailPageHeaderPadding),
                if (playlist.title.isNotEmpty)
                  PlaylistItem(
                    playlist: playlist,
                    channel: channel,
                    clickable: false,
                  )
              ],
            ),
            playlist: playlist,
            padding: const EdgeInsets.only(bottom: 120),
          ),
        ),
      ],
    );
  }
}
