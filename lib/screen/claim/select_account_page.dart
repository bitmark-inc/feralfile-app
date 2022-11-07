import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/account_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectAccountPageArgs {
  final String? blockchain;

  final Exhibition exhibition;

  final Otp? otp;

  SelectAccountPageArgs(
    this.blockchain,
    this.exhibition,
    this.otp,
  );
}

class SelectAccountPage extends StatefulWidget {
  final String? blockchain;
  final Exhibition exhibition;
  final Otp? otp;

  const SelectAccountPage({
    Key? key,
    this.blockchain,
    required this.exhibition,
    this.otp,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SelectAccountPageState();
  }
}

class _SelectAccountPageState extends State<SelectAccountPage> with RouteAware {
  Account? _selectedAccount;
  bool _processing = false;

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
              "where_do_want_to_receive_gift".tr(),
              style: theme.textTheme.headline1,
            ),
            const SizedBox(
              height: 40,
            ),
            Text(
              "claim_airdrop_select_account_desc".tr(),
              style: theme.textTheme.bodyText1,
            ),
            const SizedBox(
              height: 40,
            ),
            Expanded(child: _buildPersonaList(context)),
            AuFilledButton(
                isProcessing: _processing,
                enabled: !_processing,
                text: "confirm".tr(),
                onPress: _selectedAccount == null
                    ? null
                    : () async {
                        await _claimToken(
                          _selectedAccount!,
                          widget.exhibition.id,
                          otp: widget.otp,
                        );
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

  void _setProcessingState(bool processing) {
    setState(() {
      _processing = processing;
    });
  }

  Future _claimToken(
    Account account,
    String exhibitionId, {
    Otp? otp,
  }) async {
    try {
      _setProcessingState(true);
      final ffService = injector<FeralFileService>();
      final address = await account.getAddress(widget.blockchain ?? "tezos");
      await ffService.claimToken(
        exhibitionId: exhibitionId,
        address: address,
        otp: otp,
      );
      memoryValues.airdropFFExhibitionId.value = null;
    } catch (e) {
      log.info("[SelectAccountPage] Claim token failed. $e");
      await UIHelper.showClaimTokenError(context, e, exhibition: widget.exhibition);
      memoryValues.airdropFFExhibitionId.value = null;
    } finally {
      _setProcessingState(false);
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.homePage,
      (route) => false,
    );
  }
}
