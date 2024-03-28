import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/list_address_account.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectAccount extends StatefulWidget {
  final ConnectionRequest connectionRequest;
  final Function(WalletIndex?)? onSelectPersona;
  final Function(List<Account>)? onCategorizedAccountsChanged;
  const SelectAccount(
      {required this.connectionRequest,
      super.key,
      this.onSelectPersona,
      this.onCategorizedAccountsChanged});

  @override
  State<SelectAccount> createState() => _SelectAccountState();
}

class _SelectAccountState extends State<SelectAccount> with RouteAware {
  final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
  late ConnectionRequest connectionRequest;
  WalletIndex? selectedPersona;
  List<Account>? categorizedAccounts;

  @override
  void initState() {
    super.initState();
    connectionRequest = widget.connectionRequest;
    callAccountBloc();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    callAccountBloc();
  }

  void callAccountBloc() {
    context.read<AccountsBloc>().add(GetCategorizedAccountsEvent(
        getTezos: widget.connectionRequest.isBeaconConnect ||
            widget.connectionRequest.isAutonomyConnect,
        getEth: !widget.connectionRequest.isBeaconConnect));
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<AccountsBloc, AccountsState>(
        listener: (context, state) async {
          var stateCategorizedAccounts = state.accounts;

          if (connectionRequest.isAutonomyConnect) {
            final persona =
                await injector<AccountService>().getOrCreateDefaultPersona();
            selectedPersona = WalletIndex(persona.wallet(), 0);
            widget.onSelectPersona?.call(selectedPersona);
          }
          if (!mounted) {
            return;
          }
          categorizedAccounts = stateCategorizedAccounts;
          widget.onCategorizedAccountsChanged?.call(categorizedAccounts!);
          if (categorizedAccounts?.isEmpty ?? true) {
            return;
          }
          await _autoSelectDefault(categorizedAccounts);

          if (mounted) {
            setState(() {});
          }
        },
        builder: (context, state) => _selectAccount(context),
      );

  Future _autoSelectDefault(List<Account>? categorizedAccounts) async {
    if (categorizedAccounts == null) {
      return;
    }
    if (categorizedAccounts.length != 1) {
      return;
    }
    final persona = categorizedAccounts.first.persona;
    if (persona == null) {
      return;
    }

    final ethAccounts = categorizedAccounts.where((element) => element.isEth);
    final xtzAccounts = categorizedAccounts.where((element) => element.isTez);

    if (ethAccounts.length == 1) {
      selectedPersona = WalletIndex(persona.wallet(),
          (await persona.getEthWalletAddresses()).first.index);
      widget.onSelectPersona?.call(selectedPersona);
    }

    if (xtzAccounts.length == 1) {
      selectedPersona = WalletIndex(persona.wallet(),
          (await persona.getTezWalletAddresses()).first.index);
      widget.onSelectPersona?.call(selectedPersona);
    }
  }

  Widget _selectAccount(BuildContext context) {
    final stateCategorizedAccounts = categorizedAccounts;
    if (stateCategorizedAccounts == null) {
      return const SizedBox();
    }

    if (stateCategorizedAccounts.isEmpty) {
      return const SizedBox(); // Expanded(child: _createAccountAndConnect());
    }
    if (connectionRequest.isAutonomyConnect) {
      return const SizedBox();
    }
    return _selectPersonaWidget(context, stateCategorizedAccounts);
  }

  Widget _selectPersonaWidget(BuildContext context, List<Account> accounts) {
    final theme = Theme.of(context);
    String select = '';
    if (widget.connectionRequest.isBeaconConnect) {
      select = 'select_tezos'.tr(args: ['1']);
    } else if (widget.connectionRequest.isWalletConnect2) {
      select = 'select_ethereum'.tr(args: ['1']);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Text(
            select,
            style: theme.textTheme.ppMori400Black16,
          ),
        ),
        const SizedBox(height: 16),
        ListAccountConnect(
          accounts: accounts,
          onSelectEth: (value) {
            int index = value.walletAddress?.index ?? 0;
            selectedPersona = WalletIndex(value.persona!.wallet(), index);
            widget.onSelectPersona?.call(selectedPersona);
          },
          onSelectTez: (value) {
            int index = value.walletAddress?.index ?? 0;
            selectedPersona = WalletIndex(value.persona!.wallet(), index);
            widget.onSelectPersona?.call(selectedPersona);
          },
          isAutoSelect: accounts.length == 1,
        ),
      ],
    );
  }
}
