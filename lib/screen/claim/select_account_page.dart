import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/list_address_account.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectAddressPagePayload {
  final String? blockchain;
  final bool withViewOnly;

  SelectAddressPagePayload({
    this.blockchain,
    this.withViewOnly = false,
  });
}

class SelectAccountPage extends StatefulWidget {
  final SelectAddressPagePayload payload;

  const SelectAccountPage({
    required this.payload,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _SelectAccountPageState();
}

class _SelectAccountPageState extends State<SelectAccountPage> with RouteAware {
  String? _selectedAddress;
  late final bool _isTezos;

  @override
  void initState() {
    _isTezos = widget.payload.blockchain?.toLowerCase() == 'tezos';
    _callAccountEvent();
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
    _callAccountEvent();
    super.didPopNext();
  }

  void _callAccountEvent() {
    context.read<AccountsBloc>().add(GetCategorizedAccountsEvent(
        getEth: !_isTezos,
        getTezos: _isTezos,
        includeLinkedAccount: widget.payload.withViewOnly));
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
        title: 'gift_edition'.tr(),
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
                'where_do_want_to_receive_gift'.tr(),
                style: theme.textTheme.ppMori700Black24,
              ),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Text(
                'claim_airdrop_select_account_desc'.tr(args: [
                  widget.payload.blockchain ?? 'Tezos',
                  widget.payload.blockchain ?? 'Tezos',
                ]),
                style: theme.textTheme.ppMori400Black14,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(child: _buildAddressList()),
            ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: PrimaryAsyncButton(
                text: 'h_confirm'.tr(),
                enabled: _selectedAddress != null,
                onTap: () async {
                  Navigator.pop(context, _selectedAddress);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList() => BlocBuilder<AccountsBloc, AccountsState>(
        builder: (context, state) {
          final accounts = state.accounts ?? [];
          void select(Account value) {
            setState(() {
              _selectedAddress = value.accountNumber;
            });
          }

          return ListAccountConnect(
            accounts: accounts,
            onSelectEth: !_isTezos ? select : null,
            onSelectTez: _isTezos ? select : null,
          );
        },
      );
}
