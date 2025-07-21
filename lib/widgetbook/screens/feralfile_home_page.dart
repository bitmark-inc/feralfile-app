import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';

class FeralfileHomePageComponent extends StatelessWidget {
  const FeralfileHomePageComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FeralfileHomeBloc>(
          create: (_) => FeralfileHomeBloc(
            MockInjector.get(),
          ),
        ),
        BlocProvider<SubscriptionBloc>(
          create: (_) => SubscriptionBloc(
            MockInjector.get(),
          ),
        ),
      ],
      child: const FeralfileHomePage(),
    );
  }
}
