//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/connection/persona_connections_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/shared.dart';
import 'package:autonomy_flutter/util/connection_request_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_address_ext.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/select_account_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:walletconnect_flutter_v2/apis/core/verify/models/verify_context.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/sign_client_models.dart';

/*
 Because WalletConnect & TezosBeacon are using same logic:
 - select persona
 - suggest to generate persona
 => use this page for both WalletConnect & TezosBeacon connect
import 'package:flutter_svg/flutter_svgconnect
*/

// const scamBtnColor = Color.fromRGBO(255, 71, 71, 1);
// const warningBtnColor = Color.fromRGBO(255, 128, 10, 1);
const scamBtnColor = AppColor.feralFileHighlight;
const warningBtnColor = AppColor.feralFileHighlight;

class WCConnectPage extends StatefulWidget {
  final ConnectionRequest connectionRequest;

  const WCConnectPage({
    required this.connectionRequest,
    super.key,
  });

  @override
  State<WCConnectPage> createState() => _WCConnectPageState();
}

class _WCConnectPageState extends State<WCConnectPage>
    with RouteAware, WidgetsBindingObserver, AfterLayoutMixin<WCConnectPage> {
  WalletIndex? selectedPersona;
  List<Account>? categorizedAccounts;
  bool createPersona = false;
  final metricClient = injector.get<MetricClientService>();
  bool isWarningConfirmed = false;
  final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
  late ConnectionRequest connectionRequest;
  final tezosBeaconService = injector<TezosBeaconService>();
  final configurationService = injector<ConfigurationService>();

  late String warningTitle;
  late String warningContent;
  late Color warningColor;

  bool get _confirmEnable =>
      categorizedAccounts != null &&
      categorizedAccounts!.isNotEmpty &&
      selectedPersona != null;

  @override
  void initState() {
    super.initState();
    connectionRequest = widget.connectionRequest;
    injector<NavigationService>().setIsWCConnectInShow(true);
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
    injector<NavigationService>().setIsWCConnectInShow(false);
    Future.delayed(const Duration(seconds: 2), () {
      unawaited(tezosBeaconService.handleNextRequest(isRemoved: true));
    });
  }

  void confirmWarning() {
    setState(() {
      isWarningConfirmed = true;
    });
  }

  Future<void> _reject() async {
    if (connectionRequest.isWalletConnect2) {
      try {
        await injector<Wc2Service>().rejectSession(
          connectionRequest.id,
          reason: 'User reject',
        );
      } catch (e) {
        log.info('[WCConnectPage] Reject WalletConnect2 Proposal $e');
      }
      return;
    }

    if (connectionRequest.isBeaconConnect) {
      unawaited(injector<TezosBeaconService>()
          .permissionResponse(null, null, connectionRequest.id, null, null));
    }
  }

  Future _approve({bool onBoarding = false}) async {
    if (selectedPersona == null) {
      return;
    }

    dynamic approveResponse;

    unawaited(
        UIHelper.showLoadingScreen(context, text: 'connecting_wallet'.tr()));
    late String payloadAddress;
    late CryptoType payloadType;
    try {
      switch (connectionRequest.runtimeType) {
        case const (Wc2Proposal):
          final address = await injector<EthereumService>()
              .getETHAddress(selectedPersona!.wallet, selectedPersona!.index);
          approveResponse = await injector<Wc2Service>().approveSession(
            connectionRequest as Wc2Proposal,
            accounts: [address],
            connectionKey: address,
            accountNumber: address,
          );
          payloadType = CryptoType.ETH;
          payloadAddress = address;

        case const (BeaconRequest):
          final wallet = selectedPersona!.wallet;
          final index = selectedPersona!.index;
          final publicKey = await wallet.getTezosPublicKey(index: index);
          final address = wallet.getTezosAddressFromPubKey(publicKey);
          approveResponse =
              await injector<TezosBeaconService>().permissionResponse(
            wallet.uuid,
            index,
            (connectionRequest as BeaconRequest).id,
            publicKey,
            address,
          );
          payloadAddress = address;
          payloadType = CryptoType.XTZ;
        default:
      }
    } catch (e, s) {
      log.info('[WCConnectPage] Approve error $e $s');
      unawaited(Sentry.captureException(e, stackTrace: s));
      if (!mounted) {
        return;
      }
      // Pop Loading screen
      Navigator.of(context).pop();
      // Pop connect screen
      Navigator.of(context).pop();
      final message = 'connect_to_failed'.tr(namedArgs: {
        'name': connectionRequest.name ?? 'Secondary Wallet',
      });
      await UIHelper.showConnectFailed(context, message: message);
      return;
    }

    if (!mounted) {
      return;
    }
    UIHelper.hideInfoDialog(context);
    if (memoryValues.scopedPersona != null) {
      Navigator.of(context).pop();
      return;
    }

    final payload = PersonaConnectionsPayload(
      personaUUID: selectedPersona!.wallet.uuid,
      index: selectedPersona!.index,
      address: payloadAddress,
      type: payloadType,
      isBackHome: onBoarding,
    );
    unawaited(Navigator.of(context).pushReplacementNamed(
      AppRouter.personaConnectionsPage,
      arguments: payload,
    ));
    if (approveResponse is ApproveResponse) {
      injector<Wc2Service>().addApprovedTopic([approveResponse.topic]);
    }
  }

  Future<void> _approveThenNotify({bool onBoarding = false}) async {
    await _approve(onBoarding: onBoarding);

    if (!mounted) {
      return;
    }

    showSimpleNotificationToast(
      key: const Key('connected'),
      content: '${'connected_to'.tr()} ',
      leading: SvgPicture.asset(
        'assets/images/checkbox_icon.svg',
        width: 24,
      ),
      addOnTextSpan: [
        TextSpan(
          text: connectionRequest.name,
          style: Theme.of(context).textTheme.ppMori400FFYellow14,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'connect'.tr(),
          onBack: () async {
            await _reject();
            if (!context.mounted) {
              return;
            }
            Navigator.pop(context);
          },
        ),
        body: Container(
          margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton
              .copyWith(left: 0, right: 0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      addTitleSpace(),
                      Padding(
                        padding: padding,
                        child: _appInfo(context),
                      ),
                      const SizedBox(height: 32),
                      addDivider(height: 52),
                      const SizedBox(height: 10),
                      if (connectionRequest.validationState !=
                              Validation.VALID &&
                          !isWarningConfirmed)
                        _suspiciousDappWarning(context)
                      else ...[
                        Padding(
                          padding: padding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (connectionRequest.validationState !=
                                  Validation.VALID) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: AppColor.feralFileHighlight,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    warningTitle,
                                    style: theme.textTheme.ppMori700Black14,
                                  ),
                                ),
                                const SizedBox(
                                  height: 32,
                                ),
                              ],
                              Text(
                                'you_about_to_grant'.tr(),
                                style: theme.textTheme.ppMori400Black16,
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColor.auGrey,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ...grantPermissions.map(
                                        (permission) => Row(
                                          children: [
                                            const SizedBox(
                                              width: 6,
                                            ),
                                            Text('•',
                                                style: theme.textTheme
                                                    .ppMori400Black14),
                                            const SizedBox(
                                              width: 6,
                                            ),
                                            Text(permission,
                                                style: theme.textTheme
                                                    .ppMori400Black14),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        SelectAccount(
                          connectionRequest: connectionRequest,
                          onSelectPersona: (
                            persona,
                          ) {
                            if (mounted) {
                              setState(() {
                                selectedPersona = persona;
                              });
                            }
                          },
                          onCategorizedAccountsChanged: (accounts) {
                            if (mounted) {
                              setState(() {
                                categorizedAccounts = accounts;
                                createPersona =
                                    categorizedAccounts?.isEmpty ?? true;
                              });
                            }
                          },
                        )
                      ],
                    ],
                  ),
                ),
              ),
              if (connectionRequest.validationState != Validation.VALID &&
                  !isWarningConfirmed)
                _confirmWarningButton(context)
              else
                _connect(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget _appInfo(BuildContext context) {
    if (connectionRequest.isWalletConnect2) {
      final wc2Proposer = (connectionRequest as Wc2Proposal).proposer;
      final peer = AppMetadata(
        name: wc2Proposer.name,
        url: wc2Proposer.url,
        description: wc2Proposer.description,
        icons: wc2Proposer.icons,
      );
      return _wcAppInfo(context, peer);
    }

    if (connectionRequest.isBeaconConnect) {
      return _tbAppInfo(context, connectionRequest as BeaconRequest);
    }

    return const SizedBox();
  }

  Widget _suspiciousDappWarning(BuildContext context) {
    final theme = Theme.of(context);
    switch (connectionRequest.validationState) {
      case Validation.INVALID:
        warningTitle = 'invalid_dapp_detected_title'.tr();
        warningContent = 'invalid_dapp_detected_content'.tr();
        warningColor = scamBtnColor;
      case Validation.SCAM:
        warningTitle = 'scam_dapp_detected_title'.tr();
        warningContent = 'scam_dapp_detected_content'.tr();
        warningColor = scamBtnColor;
      case Validation.UNKNOWN:
        warningTitle = 'unverified_dapp_detected_title'.tr();
        warningContent = 'unverified_dapp_detected_content'.tr();
        warningColor = warningBtnColor;
      default:
    }
    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: warningColor.withAlpha(50),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              warningTitle,
              style: theme.textTheme.ppMori700Black14,
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              warningContent,
              style: theme.textTheme.ppMori400Black14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmWarningButton(BuildContext context) => Row(
        children: [
          Expanded(
            child: Padding(
              padding: padding,
              child: PrimaryButton(
                color: warningColor,
                text: 'continue'.tr(),
                onTap: confirmWarning,
              ),
            ),
          )
        ],
      );

  Widget _connect(BuildContext context) {
    if (createPersona) {
      return _createAccountAndConnect(context);
    } else {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: padding,
              child: PrimaryButton(
                enabled: _confirmEnable,
                text: 'h_confirm'.tr(),
                onTap: selectedPersona != null
                    ? () {
                        withDebounce(() => unawaited(_approveThenNotify()));
                      }
                    : null,
              ),
            ),
          )
        ],
      );
    }
  }

  Widget _wcAppInfo(BuildContext context, AppMetadata peerMeta) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (peerMeta.icons.isNotEmpty) ...[
          CachedNetworkImage(
            imageUrl: peerMeta.icons.first,
            width: 64,
            height: 64,
            errorWidget: (context, url, error) => SizedBox(
                width: 64,
                height: 64,
                child:
                    Image.asset('assets/images/walletconnect-alternative.png')),
          ),
        ] else ...[
          SizedBox(
              width: 64,
              height: 64,
              child:
                  Image.asset('assets/images/walletconnect-alternative.png')),
        ],
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(peerMeta.name, style: theme.textTheme.ppMori700Black24),
            ],
          ),
        )
      ],
    );
  }

  Widget _tbAppInfo(BuildContext context, BeaconRequest request) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (request.icon != null)
          CachedNetworkImage(
            imageUrl: request.icon!,
            width: 64,
            height: 64,
            errorWidget: (context, url, error) => SvgPicture.asset(
              'assets/images/tezos_social_icon.svg',
              width: 64,
              height: 64,
            ),
          )
        else
          SvgPicture.asset(
            'assets/images/tezos_social_icon.svg',
            width: 64,
            height: 64,
          ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.appName ?? '',
                  style: theme.textTheme.ppMori700Black24),
            ],
          ),
        )
      ],
    );
  }

  Widget _createAccountAndConnect(BuildContext context) => Padding(
        padding: ResponsiveLayout.pageHorizontalEdgeInsets,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'h_confirm'.tr(),
                    onTap: () {
                      withDebounce(() async => _createAccount(context));
                    },
                  ),
                )
              ],
            ),
          ],
        ),
      );

  Future _createAccount(BuildContext context) async {
    unawaited(UIHelper.showLoadingScreen(context, text: 'connecting'.tr()));
    final walletAddresses = await injector<AccountService>().insertNextAddress(
        connectionRequest.isBeaconConnect
            ? WalletType.Tezos
            : WalletType.Ethereum);
    if (!mounted) {
      return;
    }
    setState(() {
      selectedPersona = WalletIndex(walletAddresses.first.wallet, 0);
    });
    unawaited(_approveThenNotify(onBoarding: true));
  }
}
