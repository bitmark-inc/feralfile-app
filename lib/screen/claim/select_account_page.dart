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

  SelectAccountPageArgs(
    this.blockchain,
    this.artwork,
    this.otp, {
    this.fromWebview = false,
  });
}

class SelectAccountPage extends StatefulWidget {
  final String? blockchain;
  final FFSeries? artwork;
  final bool? fromWebview;
  final Otp? otp;

  const SelectAccountPage({
    Key? key,
    this.blockchain,
    required this.artwork,
    this.otp,
    this.fromWebview = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SelectAccountPageState();
  }
}

class _SelectAccountPageState extends State<SelectAccountPage> with RouteAware {
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
              child: SingleChildScrollView(child: _buildAddressList(context)),
            ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: PrimaryButton(
                isProcessing: _processing,
                enabled: !_processing,
                text: "h_confirm".tr(),
                onTap: _selectedAddress == null
                    ? null
                    : () async {
                        if (widget.fromWebview == true) {
                          Navigator.pop(context, _selectedAddress);
                          return;
                        }
                        if (widget.artwork != null) {
                          await _claimToken(
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

  Widget _buildAddressList(BuildContext context) {
    return BlocBuilder<AccountsBloc, AccountsState>(builder: (context, state) {
      final accounts = state.accounts ?? [];
      return ListAccountConnect(
        accounts: accounts,
        onSelectEth: (value) {
          setState(() {
            if (widget.blockchain?.toLowerCase() != "tezos") {
              _selectedAddress = value.accountNumber;
            }
          });
        },
        onSelectTez: (value) {
          setState(() {
            if (widget.blockchain?.toLowerCase() == "tezos") {
              _selectedAddress = value.accountNumber;
            }
          });
        },
      );
    });
  }

  void _setProcessingState(bool processing) {
    setState(() {
      _processing = processing;
    });
  }

  Future _claimToken(
    String address,
    String artworkId, {
    Otp? otp,
  }) async {
    ClaimResponse? claimRespone;
    try {
      _setProcessingState(true);
      final ffService = injector<FeralFileService>();
      claimRespone = await ffService.claimToken(
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
      memoryValues.airdropFFExhibitionId.value = null;
    } catch (e) {
      log.info("[SelectAccountPage] Claim token failed. $e");
      await UIHelper.showClaimTokenError(
        context,
        e,
        series: widget.artwork!,
      );
      memoryValues.airdropFFExhibitionId.value = null;
    } finally {
      _setProcessingState(false);
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.homePage,
      (route) => false,
    );
    final token = claimRespone?.token;
    final caption = claimRespone?.airdropInfo.twitterCaption;
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
