import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IRLGetAddressPayLoad {
  final String? blockchain;
  final Map<String, dynamic>? params;
  final Map<String, dynamic>? metadata;

  IRLGetAddressPayLoad({
    this.blockchain,
    this.params,
    this.metadata,
  });
}

class IRLGetAddressPage extends StatefulWidget {
  final IRLGetAddressPayLoad? payload;

  const IRLGetAddressPage({
    Key? key,
    this.payload,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _IRLGetAddressPageState();
  }
}

class _IRLGetAddressPageState extends State<IRLGetAddressPage> with RouteAware {
  Account? _selectedAccount;

  @override
  void initState() {
    context.read<AccountsBloc>().add(
          GetAccountsIRLEvent(
            param: widget.payload?.params,
            blockchain: widget.payload?.blockchain,
          ),
        );
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
    context.read<AccountsBloc>().add(GetAccountsIRLEvent(
          param: widget.payload?.params,
          blockchain: widget.payload?.blockchain,
        ));
    super.didPopNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
        title: "address_request".tr(),
      ),
      body: Container(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            addTitleSpace(),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Text(
                "address_request".tr(),
                style: theme.textTheme.ppMori700Black24,
              ),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Text(
                widget.payload?.metadata?['description'] ?? '',
                style: theme.textTheme.ppMori400Black14,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(child: _buildPersonaList(context)),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: PrimaryButton(
                text: "h_confirm".tr(),
                onTap: _selectedAccount == null
                    ? null
                    : () async {
                        Navigator.pop(context, _selectedAccount);
                        return;
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountItem(BuildContext context, Account account) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: IgnorePointer(
        child: Row(
          children: [
            Expanded(child: accountItem(context, account)),
            AuRadio(
                onTap: (_) {},
                value: account.key,
                groupValue: _selectedAccount?.key)
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
    final connectionType = widget.payload?.blockchain == Wc2Chain.tezos
        ? "walletBeacon"
        : "walletConnect";
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
      return ListView.builder(
        itemBuilder: (context, index) {
          return Column(
            children: [
              Padding(
                padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                child: _accountItem(context, accounts[index]),
              ),
              if (accountWidgets.length > 1) ...[const Divider(height: 1.0)],
            ],
          );
        },
        itemCount: accountWidgets.length,
      );
    });
  }
}
