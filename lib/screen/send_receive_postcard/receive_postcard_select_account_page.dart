import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/v2/wc2_permission_page.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';

class ReceivePostcardSelectAccountPageArgs {
  final String? blockchain;
  final AssetToken asset;

  ReceivePostcardSelectAccountPageArgs(
    this.blockchain,
    this.asset,
  );
}

class ReceivePostcardSelectAccountPage extends StatefulWidget {
  final String? blockchain;
  final AssetToken asset;

  const ReceivePostcardSelectAccountPage({
    Key? key,
    this.blockchain,
    required this.asset,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ReceivePostcardSelectAccountPageState();
  }
}

class _ReceivePostcardSelectAccountPageState
    extends State<ReceivePostcardSelectAccountPage> with RouteAware {
  bool _processing = false;
  String? _selectedAddress;

  @override
  void initState() {
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
    if (widget.blockchain?.toLowerCase() == "tezos") {
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
        title: "receive_postcard".tr(),
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
                "where_do_want_to_receive_postcard".tr(),
                style: theme.textTheme.ppMori700Black24,
              ),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Text(
                "claim_airdrop_select_account_desc".tr(args: [
                  widget.blockchain ?? "Tezos",
                  widget.blockchain ?? "Tezos",
                ]),
                style: theme.textTheme.ppMori400Black14,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
                child:
                    SingleChildScrollView(child: _buildAddressList(context))),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: PrimaryButton(
                  isProcessing: _processing,
                  enabled: !_processing,
                  text: "h_confirm".tr(),
                  onTap: _selectedAddress == null
                      ? null
                      : () async {
                          await _receivePostcard(
                            context,
                            _selectedAddress!,
                          );
                        }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(BuildContext context) {
    return BlocBuilder<AccountsBloc, AccountsState>(builder: (context, state) {
      final categorizedAccounts = state.categorizedAccounts ?? [];
      return Column(
        children: [
          ...categorizedAccounts
              .map((account) => PersonalConnectItem(
                    categorizedAccount: account,
                    ethSelectedAddress: _selectedAddress,
                    tezSelectedAddress: _selectedAddress,
                    isExpand: true,
                    onSelectEth: (value) {
                      setState(() {
                        if (widget.blockchain?.toLowerCase() != "tezos") {
                          _selectedAddress = value;
                        }
                      });
                    },
                    onSelectTez: (value) {
                      setState(() {
                        if (widget.blockchain?.toLowerCase() == "tezos") {
                          _selectedAddress = value;
                        }
                      });
                    },
                  ))
              .toList(),
        ],
      );
    });
  }

  Future _receivePostcard(BuildContext context, String receiveAddress) async {
    final postcardService = injector<PostcardService>();
    final respone = await postcardService.receivePostcard(
        shareId: '', tokenId: '', address: receiveAddress, counter: 20);
    if (respone == null) {
      return;
    }
    await UIHelper.showReceivePostcardSuccess(context);
    setState(() {
      _processing = false;
    });
    if (mounted) {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.homePage,
        (route) => false,
      );
    }
  }
}
