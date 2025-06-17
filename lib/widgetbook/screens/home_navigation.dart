// HomeNavigation Page
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/detail/royalty/royalty_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_navigation_page.dart';
import 'package:autonomy_flutter/screen/home/list_playlist_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent homeNavigationPageComponent = WidgetbookComponent(
  name: 'Home Navigation Page',
  useCases: [
    WidgetbookUseCase(
      name: 'Default',
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => HomeBloc(),
            ),
            BlocProvider.value(
              value: injector<IdentityBloc>(),
            ),
            BlocProvider.value(
              value: injector<RoyaltyBloc>(),
            ),
            BlocProvider.value(
              value: injector<SubscriptionBloc>(),
            ),
            BlocProvider.value(
              value: injector<CanvasDeviceBloc>(),
            ),
            BlocProvider.value(
              value: injector<ListPlaylistBloc>(),
            ),
          ],
          child: HomeNavigationPage(
            key: homePageNoTransactionKey,
            payload: HomeNavigationPagePayload(
              fromOnboarding: false,
            ),
          ),
        );
      },
    ),
  ],
);
