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

class SelectAccountScreen extends StatefulWidget {
  final String blockchain;
  final bool withLinked;
  final Future Function(String) onConfirm;

  const SelectAccountScreen({
    super.key,
    required this.blockchain,
    required this.onConfirm,
    this.withLinked = true,
  });

  @override
  State<SelectAccountScreen> createState() => _SelectAccountScreenState();
}

class _SelectAccountScreenState extends State<SelectAccountScreen> {
  String? _selectedAddress;
  bool _isConfirming = false;

  @override
  void initState() {
    _callAccountEvent();
    super.initState();
  }

  void _callAccountEvent() {
    if (widget.blockchain.toLowerCase() == "tezos") {
      context
          .read<AccountsBloc>()
          .add(GetCategorizedAccountsEvent(getEth: false));
    } else {
      context
          .read<AccountsBloc>()
          .add(GetCategorizedAccountsEvent(getTezos: false));
    }
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
        title: "gift_edition".tr(),
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
                "where_do_want_to_receive_gift".tr(),
                style: theme.textTheme.ppMori700Black24,
              ),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Text(
                "claim_airdrop_select_account_desc".tr(args: [
                  widget.blockchain,
                  widget.blockchain,
                ]),
                style: theme.textTheme.ppMori400Black14,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: _buildAddressList(context),
              ),
            ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: PrimaryButton(
                text: "h_confirm".tr(),
                isProcessing: _isConfirming,
                onTap: _selectedAddress != null
                    ? () async {
                        setState(() {
                          _isConfirming = true;
                        });
                        await widget.onConfirm(_selectedAddress!);
                        setState(() {
                          _isConfirming = false;
                        });
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(BuildContext context) {
    return BlocBuilder<AccountsBloc, AccountsState>(builder: (context, state) {
      final accounts = state.accounts ?? [];
      return ListAccountConnect(
        accounts: accounts,
        onSelectEth: (value) {
          setState(() {
            if (widget.blockchain.toLowerCase() != "tezos") {
              _selectedAddress = value.accountNumber;
            }
          });
        },
        onSelectTez: (value) {
          setState(() {
            if (widget.blockchain.toLowerCase() == "tezos") {
              _selectedAddress = value.accountNumber;
            }
          });
        },
      );
    });
  }
}
