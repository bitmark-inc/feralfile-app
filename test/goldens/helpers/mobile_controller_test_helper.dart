import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/explore/bloc/record_controller_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channels/bloc/channels_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlists/bloc/playlists_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/home/view/home_mobile_controller.dart';
import 'package:autonomy_flutter/widgetbook/components/mock_wrapper.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_one_signal.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/mock_mobile_controller.dart';
import 'package:flutter/material.dart';

class MobileControllerTestHelper {
  static Future<void> setupMockData() async {
    // Setup mock injector
    await MockInjector.setup();

    // Setup OneSignal mock to avoid MissingPluginException
    MockOneSignal.setup();

    // Trigger initial data loading for blocs
    final recordBloc = injector<RecordBloc>();
    final channelsBloc = injector<ChannelsBloc>();
    final playlistsBloc = injector<PlaylistsBloc>();

    // Add initial events to load data
    channelsBloc.add(const LoadChannelsEvent());
    playlistsBloc.add(const LoadPlaylistsEvent());
  }

  static Widget createTestWidget({
    required Widget child,
    ThemeData? theme,
    bool useScaffold = true,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.dark(),
      home: useScaffold
          ? Scaffold(
              body: child,
            )
          : child,
    );
  }

  static Widget createTestWidgetWithSize({
    required Widget child,
    ThemeData? theme,
    bool useScaffold = true,
    Size size = const Size(393, 852),
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.dark(),
      home: useScaffold
          ? Scaffold(
              body: child,
            )
          : child,
    );
  }

  static Widget createMobileControllerTestWidget({
    int initialPageIndex = 0,
    ThemeData? theme,
    bool useScaffold = true,
  }) {
    return createTestWidget(
      theme: theme,
      useScaffold: useScaffold,
      child: MockWrapper(
        child: MobileControllerHomePage(initialPageIndex: initialPageIndex),
      ),
    );
  }
}
