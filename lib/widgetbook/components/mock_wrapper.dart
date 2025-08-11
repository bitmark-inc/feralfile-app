import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/explore/bloc/record_controller_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channels/bloc/channels_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlists/bloc/playlists_bloc.dart';
import 'package:autonomy_flutter/nft_collection/widgets/nft_collection_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MockWrapper extends StatelessWidget {
  final Widget child;

  const MockWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Setup mock services
    MockInjector.setup();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AccountsBloc>(
          create: (context) => MockInjector.get<AccountsBloc>(),
        ),
        BlocProvider<RecordBloc>(
          create: (context) => MockInjector.get<RecordBloc>(),
        ),
        BlocProvider<ChannelsBloc>(
          create: (context) => MockInjector.get<ChannelsBloc>(),
        ),
        BlocProvider<PlaylistsBloc>(
          create: (context) => MockInjector.get<PlaylistsBloc>(),
        ),
        BlocProvider<NftCollectionBloc>(
          create: (context) => MockInjector.get<NftCollectionBloc>(),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(),
        ),
        BlocProvider<CanvasDeviceBloc>(
          create: (context) => MockInjector.get<CanvasDeviceBloc>(),
        ),
        BlocProvider<SubscriptionBloc>(
          create: (context) => MockInjector.get<SubscriptionBloc>(),
        ),
      ],
      child: child,
    );
  }
}
