import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectAccountPage extends StatefulWidget {
  final String? blockchain;

  const SelectAccountPage({
    Key? key,
    this.blockchain,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SelectAccountPageState();
  }
}

class _SelectAccountPageState extends State<SelectAccountPage> with RouteAware {
  Account? _selectedAccount;

  @override
  void initState() {
    context.read<AccountsBloc>().add(GetAccountsEvent());
    super.initState();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<AccountsBloc>().add(GetAccountsEvent());
    super.didPopNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(context, onBack: () {
        Navigator.of(context).pop();
      }),
      body: Container(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 24,
            ),
            Text(
              "Where do you want to receive your gift?",
              style: theme.textTheme.headline1,
            ),
            const SizedBox(
              height: 40,
            ),
            Text(
              "This artwork has been minted on the Tezos blockchain. Select your Tezos account.",
              style: theme.textTheme.bodyText1,
            ),
            const SizedBox(
              height: 40,
            ),
            Expanded(child: _buildPersonaList(context)),
            AuFilledButton(
                text: "CONFIRM",
                onPress: _selectedAccount == null
                    ? null
                    : () {
                        Navigator.of(context).pop(_selectedAccount);
                      }),
          ],
        ),
      ),
    );
  }

  Widget _accountItem(BuildContext context, Account account) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: IgnorePointer(
        child: Row(
          children: [
            Expanded(child: accountItem(context, account)),
            Transform.scale(
              scale: 1.2,
              child: Radio(
                activeColor: theme.colorScheme.primary,
                value: account.key,
                groupValue: _selectedAccount?.key,
                onChanged: (_) {},
              ),
            )
          ],
        ),
      ),
      onTap: () {
        setState(() {
          _selectedAccount = account;
        });
      },
    );
  }

  Widget _buildPersonaList(BuildContext context) {
    final connectionType =
        widget.blockchain == "Tezos" ? "walletBeacon" : "walletConnect";
    return BlocBuilder<AccountsBloc, AccountsState>(builder: (context, state) {
      final accounts = state.accounts
              ?.where((e) =>
                  e.persona != null ||
                  e.connections?.any((connection) =>
                          connection.connectionType == connectionType) ==
                      true)
              .toList() ??
          [];
      final accountWidgets =
          accounts.map((e) => _accountItem(context, e)).toList();
      return ListView.separated(
        itemBuilder: (context, index) {
          return _accountItem(context, accounts[index]);
        },
        separatorBuilder: (_, index) => const Divider(
          height: 1.0,
        ),
        itemCount: accountWidgets.length,
      );
    });
  }
}
