import 'dart:async';

import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_state.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DailyWorkPage extends StatefulWidget {
  const DailyWorkPage({super.key});

  @override
  State<DailyWorkPage> createState() => _DailyWorkPageState();
}

class _DailyWorkPageState extends State<DailyWorkPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    context.read<DailyWorkBloc>().add(GetDailyAssetTokenEvent());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void scheduleNextDailyWork(BuildContext context) {
    final now = DateTime.now();
    final startNextDay = DateTime(now.year, now.month, now.day + 1).add(
      const Duration(seconds: 3),
    ); // add 3 seconds to avoid the same artwork
    final duration = startNextDay.difference(now);
    _timer?.cancel();
    _timer = Timer(duration, () {
      context.read<DailyWorkBloc>().add(GetDailyAssetTokenEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getPlaylistAppBar(
        context,
        title: Expanded(
          child: Text('Daily work',
              style: theme.textTheme.ppMori700Black36
                  .copyWith(color: AppColor.white),
              textAlign: TextAlign.left),
        ),
        actions: [
          FFCastButton(
            displayKey: CastDailyWorkRequest.displayKey,
            onDeviceSelected: (device) {
              final canvasDeviceBloc = context.read<CanvasDeviceBloc>();
              canvasDeviceBloc.add(CanvasDeviceCastDailyWorkEvent(
                  device, CastDailyWorkRequest()));
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildBody() => Column(
        children: [
          BlocConsumer<DailyWorkBloc, DailiesWorkState>(
            listener: (context, state) {
              if (state.assetTokens.isNotEmpty) {
                scheduleNextDailyWork(context);
              }
            },
            builder: (context, state) {
              final assetToken = state.assetTokens.firstOrNull;
              if (assetToken == null) {
                return loadingIndicator();
              }
              return Expanded(
                child: ArtworkPreviewWidget(
                  useIndexer: true,
                  identity: ArtworkIdentity(
                    assetToken.id,
                    assetToken.owner,
                  ),
                ),
              );
            },
          ),
        ],
      );
}
