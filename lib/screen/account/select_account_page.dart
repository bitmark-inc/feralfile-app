import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/postcard_list_address_account.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
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
  late final bool _isTezos;

  @override
  void initState() {
    _isTezos = widget.blockchain.toLowerCase() == "tezos";
    _callAccountEvent();
    super.initState();
  }

  void _callAccountEvent() {
    context.read<AccountsBloc>().add(
        GetCategorizedAccountsEvent(getEth: !_isTezos, getTezos: _isTezos));
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
        title: "claim_address".tr(),
        titleStyle: theme.textTheme.moMASans700Black16.copyWith(fontSize: 18),
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
                "select_address_claim_postcard".tr(args: [
                  widget.blockchain,
                ]),
                style:
                    theme.textTheme.moMASans400Black16.copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: _buildAddressList(),
              ),
            ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: PostcardButton(
                text: "continue".tr(),
                fontSize: 18,
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
                color: const Color.fromRGBO(79, 174, 79, 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList() {
    return BlocBuilder<AccountsBloc, AccountsState>(builder: (context, state) {
      final accounts = state.accounts ?? [];
      void select(Account value) {
        setState(() {
          _selectedAddress = value.accountNumber;
        });
      }

      return PostcardListAccountConnect(
        accounts: accounts,
        onSelectEth: !_isTezos ? select : null,
        onSelectTez: _isTezos ? select : null,
      );
    });
  }
}
