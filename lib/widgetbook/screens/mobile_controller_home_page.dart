import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/home/view/home_mobile_controller.dart';
import 'package:autonomy_flutter/widgetbook/components/mock_wrapper.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook/widgetbook.dart';

// widgetbook component for MobileControllerHomePage
// @UseCase(
//   name: 'Mobile Controller Home Page',
//   type: MobileControllerHomePage,
// )
// Widget mobileControllerHomePageComponent(BuildContext context) {
//   return const MockWrapper(
//     child: MobileControllerHomePage(),
//   );
// }

WidgetbookComponent mobileControllerHomePageComponent = WidgetbookComponent(
  name: 'Mobile Controller Home Page',
  useCases: [
    WidgetbookUseCase(
      name: 'Default',
      builder: (context) {
        return MockWrapper(
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => HomeBloc(),
              ),
              BlocProvider.value(value: MockInjector.get<CanvasDeviceBloc>()),
              BlocProvider.value(value: MockInjector.get<SubscriptionBloc>()),
            ],
            child: const MobileControllerHomePage(),
          ),
        );
      },
    ),
  ],
);

// // widgetbook component for MobileControllerHomePage with initial page index
// @UseCase(
//   name: 'Mobile Controller Home Page - Initial Page 1',
//   type: MobileControllerHomePage,
// )
// Widget mobileControllerHomePageWithIndexComponent(BuildContext context) {
//   return const MockWrapper(
//     child: MobileControllerHomePage(initialPageIndex: 1),
//   );
// }
