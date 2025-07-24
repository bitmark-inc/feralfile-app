import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/device/base_device.dart';
import 'package:autonomy_flutter/model/now_displaying_object.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/explore/view/record_controller.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/custom_route_observer.dart';
import 'package:autonomy_flutter/util/now_displaying_manager.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/expandable_now_displaying_view.dart';
import 'package:collection/collection.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

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
          default:
            return _noDeviceView(context);
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
    return NowDisplayingStatusView(
      status:
          'Unlock your personal gallery! Pair an FF1 device to display your collection and curated art on any screen.',
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

class TokenNowDisplayingView extends StatelessWidget {
  const TokenNowDisplayingView(this.assetToken, {super.key});

  final CompactedAssetToken assetToken;

  IdentityBloc get _identityBloc => injector<IdentityBloc>();

  @override
  Widget build(BuildContext context) {
    _identityBloc.add(GetIdentityEvent([assetToken.artistTitle ?? '']));
    return BlocBuilder<IdentityBloc, IdentityState>(
      bloc: _identityBloc,
      builder: (context, state) {
        final artistTitle =
            assetToken.artistTitle?.toIdentityOrMask(state.identityMap) ??
                assetToken.artistTitle;
        return ExpandableNowDisplayingView(
          headerBuilder: (onMoreTap, isExpanded) {
            return NowDisplayingView(
              thumbnailBuilder: thumbnailBuilder,
              titleBuilder: (context) => titleBuilder(context, artistTitle),
              customAction: [
                if (CustomRouteObserver.currentRoute is CupertinoPageRoute &&
                    (CustomRouteObserver.currentRoute! as CupertinoPageRoute)
                            .settings
                            .name ==
                        AppRouter.homePage)
                  GestureDetector(
                    child: SvgPicture.asset('assets/images/run.svg'),
                    onTap: () {
                      chatModeNotifier.value = !chatModeNotifier.value;
                      // injector<RecordBloc>().add(
                      //   ResetPlaylistEvent(),
                      // );
                    },
                  ),
              ],
              onMoreTap: () {
                onMoreTap();
              },
              moreIcon: SvgPicture.asset(
                isExpanded
                    ? 'assets/images/close.svg'
                    : 'assets/images/icon_drawer.svg',
                width: 22,
                colorFilter: const ColorFilter.mode(
                  AppColor.primaryBlack,
                  BlendMode.srcIn,
                ),
              ), // Pass the dynamic icon here
            );
          },
        );
      },
    );
  }

  Widget thumbnailBuilder(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: tokenGalleryThumbnailWidget(
        context,
        assetToken,
        65,
        useHero: false,
      ),
    );
  }

  Widget titleBuilder(BuildContext context, String? artistTitle) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        children: [
          if (artistTitle != null)
            TextSpan(
              text: artistTitle,
              style: theme.textTheme.ppMori400Black14.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColor.primaryBlack,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  if (assetToken.isFeralfile) {
                    injector<NavigationService>().openFeralFileArtistPage(
                      assetToken.artistID!,
                    );
                  } else {
                    final uri = Uri.parse(
                      assetToken.artistURL?.split(' & ').firstOrNull ?? '',
                    );
                    injector<NavigationService>().openUrl(uri);
                  }
                },
            ),
          if (artistTitle != null)
            TextSpan(
              text: ', ',
              style: theme.textTheme.ppMori400Black14,
            ),
          TextSpan(
            text: assetToken.displayTitle,
            style: theme.textTheme.ppMori400Black14,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class DP1NowDisplayingView extends StatelessWidget {
  const DP1NowDisplayingView(this.object, {super.key});

  final DP1NowDisplayingObject object;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetToken = object.assetToken;
    final device = BluetoothDeviceManager().castingBluetoothDevice;
    return ExpandableNowDisplayingView(
      headerBuilder: (onMoreTap, isExpanded) {
        return NowDisplayingView(
          thumbnailBuilder: (context) {
            if (assetToken != null) {
              return AspectRatio(
                aspectRatio: 1,
                child: tokenGalleryThumbnailWidget(
                  context,
                  CompactedAssetToken.fromAssetToken(assetToken),
                  65,
                  useHero: false,
                ),
              );
            }
            return AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: AppColor.auLightGrey,
              ),
            );
          },
          titleBuilder: (context) {
            final title = assetToken?.title ?? '';
            return Text(
              title,
              style: theme.textTheme.ppMori400Black14,
              overflow: TextOverflow.ellipsis,
            );
          },
          onMoreTap: () {
            onMoreTap();
          },
          moreIcon: SvgPicture.asset(
            isExpanded
                ? 'assets/images/close.svg'
                : 'assets/images/icon_drawer.svg',
            width: 22,
            colorFilter: const ColorFilter.mode(
              AppColor.primaryBlack,
              BlendMode.srcIn,
            ),
          ),
          customAction: [
            if (CustomRouteObserver.currentRoute is CupertinoPageRoute &&
                (CustomRouteObserver.currentRoute! as CupertinoPageRoute)
                        .settings
                        .name ==
                    AppRouter.homePage)
              GestureDetector(
                child: SvgPicture.asset('assets/images/run.svg'),
                onTap: () {
                  chatModeNotifier.value = !chatModeNotifier.value;
                  // injector<RecordBloc>().add(
                  //   ResetPlaylistEvent(),
                  // );
                },
              ),
          ],
        );
      },
    );
  }
}

class NowDisplayingView extends StatelessWidget {
  const NowDisplayingView({
    required this.thumbnailBuilder,
    required this.titleBuilder,
    this.onMoreTap,
    this.device,
    super.key,
    this.customAction = const [],
    this.moreIcon, // Added parameter for custom icon
  });

  final Widget Function(BuildContext) thumbnailBuilder;
  final Widget Function(BuildContext) titleBuilder;
  final BaseDevice? device;
  final void Function()? onMoreTap;
  final List<Widget> customAction;
  final Widget? moreIcon; // Declare the new parameter

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      constraints: const BoxConstraints(
        maxHeight: kNowDisplayingHeight,
        minHeight: kNowDisplayingHeight,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 65, minWidth: 65),
            child: thumbnailBuilder(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Now Displaying: ${device?.name ?? ''}',
                  style: theme.textTheme.ppMori400Black14,
                  overflow: TextOverflow.ellipsis,
                ),
                Expanded(child: titleBuilder(context)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ...customAction
              .map(
                (action) => [
                  const SizedBox(width: 10),
                  action,
                ],
              )
              .flattened,
          if (onMoreTap != null)
            IconButton(
              onPressed: () {
                onMoreTap?.call();
              },
              icon: moreIcon ??
                  SvgPicture.asset(
                    'assets/images/icon_drawer.svg',
                    width: 22,
                    colorFilter: const ColorFilter.mode(
                      AppColor.primaryBlack,
                      BlendMode.srcIn,
                    ),
                  ),
            ),
        ],
      ),
    );
  }
}

class CustomNowDisplayingView extends StatelessWidget {
  const CustomNowDisplayingView({
    required this.builder,
    this.onMoreTap,
    this.device,
    super.key,
    this.customAction = const [],
    this.moreIcon, // Added parameter for custom icon
  });

  final Widget Function(BuildContext) builder;
  final BaseDevice? device;
  final void Function()? onMoreTap;
  final List<Widget> customAction;
  final Widget? moreIcon; // Declare the new parameter

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      constraints: const BoxConstraints(
        maxHeight: kNowDisplayingHeight,
        minHeight: kNowDisplayingHeight,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: builder(context),
          ),
          const SizedBox(width: 10),
          ...customAction
              .map(
                (action) => [
                  const SizedBox(width: 10),
                  action,
                ],
              )
              .flattened,
          if (onMoreTap != null)
            IconButton(
              onPressed: () {
                onMoreTap?.call();
              },
              icon: moreIcon ??
                  SvgPicture.asset(
                    'assets/images/icon_drawer.svg',
                    width: 22,
                    colorFilter: const ColorFilter.mode(
                      AppColor.primaryBlack,
                      BlendMode.srcIn,
                    ),
                  ),
            ),
        ],
      ),
    );
  }
}

class NowDisplayingStatusView extends StatelessWidget {
  const NowDisplayingStatusView({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    return ExpandableNowDisplayingView(
      headerBuilder: (onMoreTap, isExpanded) {
        return CustomNowDisplayingView(
          builder: (context) {
            return Container(
              constraints: const BoxConstraints(
                maxHeight: kNowDisplayingHeight,
                minHeight: kNowDisplayingHeight,
              ),
              child: Column(
                children: [
                  Text(
                    status,
                    style: Theme.of(context).textTheme.ppMori400Black14,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
          onMoreTap: () {
            onMoreTap();
          },
          moreIcon: SvgPicture.asset(
            isExpanded
                ? 'assets/images/close.svg'
                : 'assets/images/icon_drawer.svg',
            width: 22,
            colorFilter: const ColorFilter.mode(
              AppColor.primaryBlack,
              BlendMode.srcIn,
            ),
          ),
          customAction: [
            if (CustomRouteObserver.currentRoute is CupertinoPageRoute &&
                (CustomRouteObserver.currentRoute! as CupertinoPageRoute)
                        .settings
                        .name ==
                    AppRouter.homePage)
              GestureDetector(
                child: SvgPicture.asset('assets/images/run.svg'),
                onTap: () {
                  chatModeNotifier.value = !chatModeNotifier.value;
                  // injector<RecordBloc>().add(
                  //   ResetPlaylistEvent(),
                  // );
                },
              ),
          ],
        );
      },
    );
  }
}
