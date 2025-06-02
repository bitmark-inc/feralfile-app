import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook_workspace/mock/mock_accounts_bloc.dart';
import 'package:widgetbook_workspace/mock/mock_injector.dart';

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
      create: (context) => MockInjector.get<MockAccountsBloc>(),
      child: child,
    );
  }
}
