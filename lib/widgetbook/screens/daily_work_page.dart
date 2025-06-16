import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DailyWorkPageComponent extends StatelessWidget {
  const DailyWorkPageComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DailyWorkBloc>.value(
          value: MockInjector.get<DailyWorkBloc>(),
        ),
        BlocProvider<CanvasDeviceBloc>.value(
          value: MockInjector.get<CanvasDeviceBloc>(),
        ),
        BlocProvider<IdentityBloc>.value(
          value: MockInjector.get<IdentityBloc>(),
        ),
        BlocProvider<RetryCubit>(
          create: (context) => RetryCubit(),
        )
      ],
      child: const DailyWorkPage(),
    );
  }
}
