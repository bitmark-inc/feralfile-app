import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/claim/claim_token_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/list_address_account.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectAccountPageArgs {
  final String? blockchain;

  final FFSeries? artwork;
  final bool fromWebview;

  final Otp? otp;
  final bool withViewOnly;

  SelectAccountPageArgs(
    this.blockchain,
    this.artwork,
    this.otp, {
    this.fromWebview = false,
    this.withViewOnly = false,
  });
}

class SelectAccountPage extends StatefulWidget {
  final String? blockchain;
  final FFSeries? artwork;
  final bool? fromWebview;
  final Otp? otp;
  final bool withViewOnly;

  const SelectAccountPage({
    Key? key,
    this.blockchain,
    required this.artwork,
    this.otp,
    this.fromWebview = false,
    this.withViewOnly = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SelectAccountPageState();
  }
}

class _SelectAccountPageState extends State<SelectAccountPage> with RouteAware {
  String? _selectedAddress;
  late final bool _isTezos;

  @override
  void initState() {
    _isTezos = widget.blockchain?.toLowerCase() == "tezos";
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
        includeLinkedAccount: widget.withViewOnly));
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
                  widget.blockchain ?? "Tezos",
                  widget.blockchain ?? "Tezos",
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
                text: "h_confirm".tr(),
                onTap: () async {
                  if (widget.fromWebview == true) {
                    Navigator.pop(context, _selectedAddress);
                    return;
                  }
                  if (widget.artwork != null) {
                    await _claimToken(
                      context,
                      _selectedAddress!,
                      widget.artwork!.id,
                      otp: widget.otp,
                    );
                  }
                },
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

      return ListAccountConnect(
        accounts: accounts,
        onSelectEth: !_isTezos ? select : null,
        onSelectTez: _isTezos ? select : null,
      );
    });
  }

  Future _claimToken(
    BuildContext context,
    String address,
    String artworkId, {
    Otp? otp,
  }) async {
    ClaimResponse? claimResponse;
    try {
      final ffService = injector<FeralFileService>();
      claimResponse = await ffService.claimToken(
        seriesId: artworkId,
        address: address,
        otp: otp,
      );
      final metricClient = injector.get<MetricClientService>();
      metricClient.addEvent(
        MixpanelEvent.acceptOwnershipSuccess,
        data: {
          "id": widget.artwork?.id,
        },
      );
      memoryValues.branchDeeplinkData.value = null;
    } catch (e) {
      log.info("[SelectAccountPage] Claim token failed. $e");
      if (mounted) {
        await UIHelper.showClaimTokenError(
          context,
          e,
          series: widget.artwork!,
        );
      }
      memoryValues.branchDeeplinkData.value = null;
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.homePage,
      (route) => false,
    );
    final token = claimResponse?.token;
    final caption = claimResponse?.airdropInfo.twitterCaption;
    if (token == null) {
      return;
    }
    Navigator.of(context).pushNamed(
      AppRouter.artworkDetailsPage,
      arguments: ArtworkDetailPayload(
          [ArtworkIdentity(token.id, token.owner)], 0,
          twitterCaption: caption ?? ""),
    );
  }
}
