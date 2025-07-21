import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/home/organize_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autonomy_flutter/widgetbook/mock/mock_injector.dart';

class OrganizeHomePageComponent extends StatelessWidget {
  const OrganizeHomePageComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SubscriptionBloc>(
          create: (_) => SubscriptionBloc(MockInjector.get()),
        ),
      ],
      child: const OrganizeHomePage(),
    );
  }
}
