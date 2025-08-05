import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/explore/bloc/record_controller_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/explore/view/record_controller.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/home/widgets/icon_switcher.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channels/bloc/channels_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/index.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlists/bloc/playlists_bloc.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/home_page_helper.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MobileControllerHomePage extends StatefulWidget {
  const MobileControllerHomePage({super.key, this.initialPageIndex = 0});

  final int initialPageIndex;

  @override
  State<MobileControllerHomePage> createState() =>
      _MobileControllerHomePageState();
}

class _MobileControllerHomePageState
    extends ObservingState<MobileControllerHomePage> {
  late int _currentPageIndex;
  late PageController _pageController;

  final _recordBloc = injector<RecordBloc>();
  final _channelsBloc = injector<ChannelsBloc>();
  final _playlistsBloc = injector<PlaylistsBloc>();

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: _currentPageIndex);

    // load channel and playlist
    _channelsBloc.add(const LoadChannelsEvent());
    _playlistsBloc.add(const LoadPlaylistsEvent());

    HomePageHelper.instance.onHomePageInit(context, this);
  }

  // dispose
  @override
  void dispose() {
    _pageController.dispose();
    HomePageHelper.instance.onHomePageDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: _recordBloc,
          ),
        ],
        child: const RecordControllerScreen(),
      ),
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _channelsBloc),
          BlocProvider.value(value: _playlistsBloc),
        ],
        child: const ListDirectoryPage(),
      ),
    ];
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: getDarkEmptyAppBar(Colors.transparent),
        backgroundColor: AppColor.auGreyBackground,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        body: _buildPageView(
          pages,
        ),
      ),
    );
  }

  Widget _buildPageView(List<Widget> pages) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        PageView.builder(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          itemCount: pages.length,
          itemBuilder: (context, index) {
            return Container(
                color: AppColor.auGreyBackground, child: pages[index]);
          },
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top,
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: _topControlsBar(context),
          ),
        )

        // fade effect on bottom
        // MultiValueListenableBuilder(
        //   valueListenables: [
        //     nowDisplayingShowing,
        //   ],
        //   builder: (context, values, _) {
        //     return values.every((value) => value as bool)
        //         ? Positioned(
        //             bottom: 0,
        //             left: 0,
        //             right: 0,
        //             child: IgnorePointer(
        //               child: Container(
        //                 height: 160,
        //                 decoration: BoxDecoration(
        //                   gradient: LinearGradient(
        //                     begin: Alignment.topCenter,
        //                     end: Alignment.bottomCenter,
        //                     stops: const [0.0, 0.37, 0.37],
        //                     colors: [
        //                       AppColor.auGreyBackground.withAlpha(0),
        //                       AppColor.auGreyBackground,
        //                       AppColor.auGreyBackground,
        //                     ],
        //                   ),
        //                 ),
        //               ),
        //             ),
        //           )
        //         : Container();
        //   },
        // ),
      ],
    );
  }

  Widget _topControlsBar(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: _buildSwitcher(context, _currentPageIndex),
        ),
        if (_currentPageIndex == 0)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                BlocBuilder<RecordBloc, RecordState>(
                  bloc: _recordBloc,
                  builder: (context, state) {
                    if (state is RecordSuccessState &&
                        state.lastDP1Call!.items.isNotEmpty) {
                      return FFCastButton(
                        displayKey: state.lastDP1Call!.id,
                        onDeviceSelected: (device) async {
                          final lastIntent = state.lastIntent!;
                          final lastDP1Call = state.lastDP1Call!;
                          final deviceName = lastIntent.deviceName;
                          final device = await BluetoothDeviceManager()
                              .pickADeviceToDisplay(deviceName ?? '');
                          if (device == null) {
                            await UIHelper.showInfoDialog(
                              context,
                              'Device not found',
                              'Can not find a device to display your artworks',
                            );
                            return;
                          }
                          if (BluetoothDeviceManager().castingBluetoothDevice !=
                              device) {
                            await BluetoothDeviceManager().switchDevice(device);
                          }
                          final completer = Completer<void>();
                          injector<CanvasDeviceBloc>().add(
                            CanvasDeviceCastDP1PlaylistEvent(
                                device: device,
                                playlist: lastDP1Call,
                                intent: lastIntent,
                                onDoneCallback: () {
                                  completer.complete();
                                }),
                          );
                          await completer.future;
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: chatModeNotifier,
                  builder: (context, chatModeView, child) {
                    if (chatModeView) {
                      return child ?? const SizedBox();
                    }
                    return const SizedBox();
                  },
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      // close button
                      GestureDetector(
                        onTap: () {
                          _recordBloc.add(ResetPlaylistEvent());
                          chatModeNotifier.value = false;
                        },
                        child: SvgPicture.asset(
                          'assets/images/close.svg',
                          colorFilter: const ColorFilter.mode(
                            AppColor.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  FutureOr<void> onSwitchPage(int index) {
    routeObserver.onCurrentRouteChanged();
  }

  Widget _buildSwitcher(BuildContext context, int currentIndex) {
    return IconSwitcher(
      initialIndex: _currentPageIndex,
      items: [
        IconSwitcherItem(
          icon: SvgPicture.asset(
            'assets/images/cycle.svg',
            colorFilter: const ColorFilter.mode(
              AppColor.disabledColor,
              BlendMode.srcIn,
            ),
          ),
          iconOnSelected: SvgPicture.asset(
            'assets/images/cycle.svg',
            colorFilter: const ColorFilter.mode(
              AppColor.white,
              BlendMode.srcIn,
            ),
          ),
          onTap: () {
            _pageController.jumpToPage(0);
            if (_recordBloc.state is RecordSuccessState) {
              _recordBloc.add(ResetPlaylistEvent());
            }
            chatModeNotifier.value = false;
            onSwitchPage(0);
          },
        ),
        IconSwitcherItem(
          icon: SvgPicture.asset(
            'assets/images/list.svg',
            colorFilter: const ColorFilter.mode(
              AppColor.disabledColor,
              BlendMode.srcIn,
            ),
          ),
          iconOnSelected: SvgPicture.asset(
            'assets/images/list.svg',
            colorFilter: const ColorFilter.mode(
              AppColor.white,
              BlendMode.srcIn,
            ),
          ),
          onTap: () {
            _pageController.jumpToPage(1);
            onSwitchPage(1);
          },
        ),
      ],
    );
  }
}
