import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/list_address_account.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReceivePostcardSelectAccountPageArgs {
  final String? blockchain;
  final bool withLinked;

  ReceivePostcardSelectAccountPageArgs(this.blockchain,
      {this.withLinked = true});
}

class ReceivePostcardSelectAccountPage extends StatefulWidget {
  final String? blockchain;
  final bool withLinked;

  const ReceivePostcardSelectAccountPage({
    super.key,
    this.blockchain,
    this.withLinked = true,
  });

  @override
  State<StatefulWidget> createState() =>
      _ReceivePostcardSelectAccountPageState();
}

class _ReceivePostcardSelectAccountPageState
    extends State<ReceivePostcardSelectAccountPage> with RouteAware {
  final bool _processing = false;
  String? _selectedAddress;
  late final bool _isTezos;

  @override
  void initState() {
    _isTezos = widget.blockchain?.toLowerCase() == 'tezos';
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
        includeLinkedAccount: widget.withLinked));
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
                'receive_postcard_desc'.tr(args: [
                  widget.blockchain ?? 'Tezos',
                  widget.blockchain ?? 'Tezos',
                ]),
                style: theme.textTheme.ppMori400Black14,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(child: SingleChildScrollView(child: _buildAddressList())),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: PrimaryButton(
                  isProcessing: _processing,
                  enabled: !_processing,
                  text: 'h_confirm'.tr(),
                  onTap: _selectedAddress == null
                      ? null
                      : () {
                          Navigator.pop(context, _selectedAddress);
                        }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList() =>
      BlocBuilder<AccountsBloc, AccountsState>(builder: (context, state) {
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
      });
}
