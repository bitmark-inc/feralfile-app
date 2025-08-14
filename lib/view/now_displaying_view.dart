import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/now_displaying_object.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/now_displaying_manager.dart';
import 'package:autonomy_flutter/view/now_displaying/dp1_now_displaying_view.dart';
import 'package:autonomy_flutter/view/now_displaying/now_displaying_status_view.dart';
import 'package:autonomy_flutter/view/now_displaying/token_now_displaying_view.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const double kNowDisplayingHeight = 60;

class NowDisplaying extends StatefulWidget {
  const NowDisplaying({super.key});

  @override
  State<NowDisplaying> createState() => _NowDisplayingState();
}

class _NowDisplayingState extends State<NowDisplaying>
    with AfterLayoutMixin<NowDisplaying> {
  final NowDisplayingManager _manager = NowDisplayingManager();
  late NowDisplayingStatus nowDisplayingStatus;

  @override
  void initState() {
    super.initState();
    nowDisplayingStatus = _manager.nowDisplayingStatus;
    _manager.nowDisplayingStream.listen(
      (status) {
        if (mounted) {
          setState(
            () {
              nowDisplayingStatus = status;
            },
          );
        }
      },
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CanvasDeviceBloc, CanvasDeviceState>(
      bloc: injector<CanvasDeviceBloc>(),
      listener: (context, state) {},
      builder: (context, state) {
        final nowDisplayingStatus = this.nowDisplayingStatus;

        switch (nowDisplayingStatus.runtimeType) {
          case DeviceDisconnected:
            return _connectFailedView(context, nowDisplayingStatus);
          case ConnectionLost:
            return _connectionLostView(
              context,
              nowDisplayingStatus,
            );
          case NowDisplayingError:
            return _getNowDisplayingErrorView(context, nowDisplayingStatus);
          case NowDisplayingSuccess:
            return NowDisplayingSuccessWidget(
              object: (nowDisplayingStatus as NowDisplayingSuccess).object,
            );
          case NoDevicePaired:
            return _noDeviceView(context);
          default:
            return const SizedBox();
        }
      },
    );
  }

  Widget _connectFailedView(BuildContext context, NowDisplayingStatus status) {
    final device = (status as DeviceDisconnected).device;
    final deviceName =
        device.name.isNotEmpty == true ? device.name : 'Portal (FF-X1)';
    return NowDisplayingStatusView(
      status: 'Device $deviceName is offline or disconnected.',
    );
  }

  Widget _connectionLostView(
    BuildContext context,
    NowDisplayingStatus status,
  ) {
    final device = (status as ConnectionLost).device;
    final deviceName =
        device.name.isNotEmpty == true ? device.name : 'Portal (FF-X1)';
    return NowDisplayingStatusView(
      status: 'Connection to $deviceName lost.',
    );
  }

  Widget _getNowDisplayingErrorView(
    BuildContext context,
    NowDisplayingStatus nowDisplayingStatus,
  ) {
    final error = (nowDisplayingStatus as NowDisplayingError).error;
    return NowDisplayingStatusView(
      status: 'Error: $error',
    );
  }

  // there no device setuped
  Widget _noDeviceView(BuildContext context) {
    return const NowDisplayingStatusView(
      status:
          'Pair an FF1 to display your collection and curated art on any screen.',
    );
  }
}

class NowDisplayingSuccessWidget extends StatefulWidget {
  const NowDisplayingSuccessWidget({required this.object, super.key});

  final NowDisplayingObjectBase object;

  @override
  State<NowDisplayingSuccessWidget> createState() =>
      _NowDisplayingSuccessWidgetState();
}

class _NowDisplayingSuccessWidgetState
    extends State<NowDisplayingSuccessWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final nowDisplaying = widget.object;
    if (nowDisplaying is DP1NowDisplayingObject) {
      return _dp1NowDisplayingView(context, nowDisplaying);
    } else if (nowDisplaying is NowDisplayingObject) {
      return _nowDisplayingView(context, nowDisplaying);
    }

    return const SizedBox();
  }

  Widget _dp1NowDisplayingView(
    BuildContext context,
    DP1NowDisplayingObject nowDisplaying,
  ) {
    return GestureDetector(
      child: DP1NowDisplayingView(
        nowDisplaying,
      ),
      onTap: () {
        injector<NavigationService>().navigateTo(AppRouter.nowDisplayingPage);
      },
    );
  }

  Widget _nowDisplayingView(
    BuildContext context,
    NowDisplayingObject nowDisplaying,
  ) {
    final assetToken = nowDisplaying.assetToken;
    if (assetToken != null) {
      return _tokenNowDisplayingView(context, assetToken);
    }
    if (nowDisplaying.dailiesWorkState != null) {
      return _dailyWorkNowDisplayingView(
        context,
        nowDisplaying.dailiesWorkState!,
      );
    }
    return const SizedBox();
  }
}

Widget _tokenNowDisplayingView(BuildContext context, AssetToken assetToken) {
  return GestureDetector(
    child: TokenNowDisplayingView(
      CompactedAssetToken.fromAssetToken(assetToken),
    ),
    onTap: () {
      const pageName = AppRouter.nowDisplayingPage;
      injector<NavigationService>().navigateTo(
        pageName,
      );
    },
  );
}

Widget _dailyWorkNowDisplayingView(
  BuildContext context,
  DailiesWorkState state,
) {
  final assetToken = state.assetTokens.firstOrNull;
  if (assetToken == null) {
    return const SizedBox();
  }
  return GestureDetector(
    child: TokenNowDisplayingView(
      CompactedAssetToken.fromAssetToken(assetToken),
    ),
    onTap: () {
      injector<NavigationService>().navigateTo(
        AppRouter.nowDisplayingPage,
      );
    },
  );
}
