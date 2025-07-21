import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
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

    return BlocProvider<AccountsBloc>(
      create: (context) => MockInjector.get<AccountsBloc>(),
      child: child,
    );
  }
}
