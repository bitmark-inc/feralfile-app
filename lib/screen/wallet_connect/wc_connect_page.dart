//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/wc2_proposal.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/connection/persona_connections_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';

import '../../service/account_service.dart';

/*
 Because WalletConnect & TezosBeacon are using same logic:
 - select persona 
 - suggest to generate persona
 => use this page for both WalletConnect & TezosBeacon connect
*/
class WCConnectPage extends StatefulWidget {
  static const String tag = AppRouter.wcConnectPage;

  final WCConnectPageArgs? wcConnectArgs;
  final BeaconRequest? beaconRequest;
  final Wc2Proposal? wc2Proposal;

  const WCConnectPage({
    Key? key,
    required this.wcConnectArgs,
    required this.beaconRequest,
    required this.wc2Proposal,
  }) : super(key: key);

  @override
  State<WCConnectPage> createState() => _WCConnectPageState();
}

class _WCConnectPageState extends State<WCConnectPage>
    with RouteAware, WidgetsBindingObserver {
  Persona? selectedPersona;
  List<Persona>? personas;
  bool generatedPersona = false;
  final metricClient = injector.get<MetricClientService>();
  bool _isAccountSelected = false;
  final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);

  @override
  void initState() {
    super.initState();
    context
        .read<PersonaBloc>()
        .add(GetListPersonaEvent(useDidKeyForAlias: true));
    injector<NavigationService>().setIsWCConnectInShow(true);
    memoryValues.deepLink.value = null;
    metricClient.timerEvent(MixpanelEvent.backConnectMarket);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    context
        .read<PersonaBloc>()
        .add(GetListPersonaEvent(useDidKeyForAlias: true));
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
    injector<NavigationService>().setIsWCConnectInShow(false);
  }

  Future<void> _reject() async {
    final wc2Proposal = widget.wc2Proposal;
    final wcConnectArgs = widget.wcConnectArgs;
    final beaconRequest = widget.beaconRequest;

    if (wc2Proposal != null) {
      try {
        await injector<Wc2Service>().rejectSession(
          wc2Proposal.id,
          reason: "User reject",
        );
      } catch (e) {
        log.info("[WCConnectPage] Reject WC2 Proposal $e");
      }
    } else if (wcConnectArgs != null) {
      injector<WalletConnectService>().rejectSession(wcConnectArgs.peerMeta);
    }

    if (beaconRequest != null) {
      injector<TezosBeaconService>()
          .permissionResponse(null, beaconRequest.id, null, null);
    }
  }

  Future _approve({bool onBoarding = false}) async {
    if (selectedPersona == null) return;

    final wc2Proposal = widget.wc2Proposal;
    final wcConnectArgs = widget.wcConnectArgs;
    final beaconRequest = widget.beaconRequest;

    UIHelper.showLoadingScreen(context, text: 'connecting_wallet'.tr());
    late String payloadAddress;
    late CryptoType payloadType;

    if (wc2Proposal != null) {
      final accountDid = await selectedPersona!.wallet().getAccountDID();
      await injector<Wc2Service>().approveSession(
        wc2Proposal,
        accountDid: accountDid.substring("did:key:".length),
        personalUUID: selectedPersona!.uuid,
      );
      payloadType = CryptoType.ETH;
      payloadAddress = await selectedPersona!.wallet().getETHEip55Address();
    } else if (wcConnectArgs != null) {
      final address = await injector<EthereumService>()
          .getETHAddress(selectedPersona!.wallet());

      final chainId = Environment.web3ChainId;

      final approvedAddresses = [address];
      log.info(
          "[WCConnectPage] approve WCConnect with addresses $approvedAddresses");
      await injector<WalletConnectService>().approveSession(
          selectedPersona!.uuid,
          wcConnectArgs.peerMeta,
          approvedAddresses,
          chainId);

      payloadAddress = address;
      payloadType = CryptoType.ETH;
      if (onBoarding) {
        _navigateHome();
        return;
      } else {
        if (wcConnectArgs.peerMeta.url.contains("feralfile")) {
          _navigateWhenConnectFeralFile();
          return;
        }
      }

      if (wcConnectArgs.peerMeta.name == AUTONOMY_TV_PEER_NAME) {
        metricClient.addEvent(MixpanelEvent.connectAutonomyDisplay);
      } else {
        metricClient.addEvent(
          MixpanelEvent.connectExternal,
          data: {
            "method": "wallet_connect",
            "name": wcConnectArgs.peerMeta.name,
            "url": wcConnectArgs.peerMeta.url,
          },
        );
      }
    } else if (beaconRequest != null) {
      final wallet = selectedPersona!.wallet();
      final publicKey = await wallet.getTezosPublicKey();
      final address = await wallet.getTezosAddress();
      await injector<TezosBeaconService>().permissionResponse(
        selectedPersona!.uuid,
        beaconRequest.id,
        publicKey,
        address,
      );
      payloadAddress = address;
      payloadType = CryptoType.XTZ;
    }

    final payload = PersonaConnectionsPayload(
        personaUUID: selectedPersona!.uuid,
        address: payloadAddress,
        type: payloadType,
        personaName: selectedPersona!.name,
        isBackHome: true);
    if (!mounted) return;
    UIHelper.hideInfoDialog(context);

    if (memoryValues.scopedPersona != null) {
      // from persona details flow
      Navigator.of(context).pop();
    } else {
      if (onBoarding) {
        _navigateHome();
      } else {
        Navigator.of(context).pushReplacementNamed(
            AppRouter.personaConnectionsPage,
            arguments: payload);
      }
    }

    metricClient.addEvent(
      MixpanelEvent.connectExternal,
      data: {
        "method": "tezos_beacon",
        "name": beaconRequest?.appName ?? "unknown",
        "url": beaconRequest?.sourceAddress ?? "unknown",
      },
    );
  }

  Future<void> _approveThenNotify({bool onBoarding = false}) async {
    await _approve(onBoarding: onBoarding);
    final notificationEnable =
        injector<ConfigurationService>().isNotificationEnabled() ?? false;
    if (notificationEnable) {
      if (widget.beaconRequest?.appName != null) {
        metricClient.addEvent(MixpanelEvent.connectMarketSuccess);
        if (!mounted) return;
        showInfoNotification(
          const Key("connected"),
          "connected_to".tr(),
          frontWidget: SvgPicture.asset(
            "assets/images/checkbox_icon.svg",
            width: 24,
          ),
          addOnTextSpan: [
            TextSpan(
              text: widget.beaconRequest!.appName!,
              style: Theme.of(context).textTheme.ppMori400Green14,
            )
          ],
        );
      } else if (widget.wcConnectArgs?.peerMeta.name != null) {
        metricClient.addEvent(MixpanelEvent.connectMarketSuccess);
        if (!mounted) return;
        showInfoNotification(
          const Key("connected"),
          "connected_to".tr(),
          frontWidget: SvgPicture.asset(
            "assets/images/checkbox_icon.svg",
            width: 24,
          ),
          addOnTextSpan: [
            TextSpan(
              text: widget.beaconRequest!.appName!,
              style: Theme.of(context).textTheme.ppMori400Green14,
            )
          ],
        );
      } else if (widget.wc2Proposal?.proposer.name != null) {
        metricClient.addEvent(MixpanelEvent.connectMarketSuccess);
        if (!mounted) return;
        showInfoNotification(
          const Key("connected"),
          "connected_to".tr(),
          frontWidget: SvgPicture.asset(
            "assets/images/checkbox_icon.svg",
            width: 24,
          ),
          addOnTextSpan: [
            TextSpan(
              text: widget.beaconRequest!.appName!,
              style: Theme.of(context).textTheme.ppMori400Green14,
            )
          ],
        );
      }
    }
  }

  void _navigateWhenConnectFeralFile() {
    Navigator.of(context).pop();
  }

  void _navigateHome() {
    injector<NavigationService>().navigateUntil(
      AppRouter.homePage,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return WillPopScope(
      onWillPop: () async {
        metricClient.addEvent(MixpanelEvent.backConnectMarket);
        _reject();
        return true;
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'connect'.tr(),
          onBack: () async {
            metricClient.addEvent(MixpanelEvent.backConnectMarket);
            await _reject();
            if (!mounted) return;
            Navigator.pop(context);
          },
        ),
        body: Container(
          margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton
              .copyWith(left: 0, right: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              addTitleSpace(),
              Padding(
                padding: padding,
                child: _appInfo(),
              ),
              const SizedBox(height: 32),
              addDivider(height: 52),
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "you_have_permission".tr(),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...grantPermissions
                                .map(
                                  (permission) => Row(
                                    children: [
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      Text("•",
                                          style:
                                              theme.textTheme.ppMori400Black14),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      Text(permission,
                                          style:
                                              theme.textTheme.ppMori400Black14),
                                    ],
                                  ),
                                )
                                .toList(),
                          ],
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              BlocConsumer<PersonaBloc, PersonaState>(
                  listener: (context, state) {
                var statePersonas = state.personas;
                if (statePersonas == null) return;

                final scopedPersonaUUID = memoryValues.scopedPersona;
                if (scopedPersonaUUID != null) {
                  final scopedPersona = statePersonas.firstWhere(
                      (element) => element.uuid == scopedPersonaUUID);
                  statePersonas = [scopedPersona];
                }

                if (statePersonas.length == 1) {
                  setState(() {
                    selectedPersona = statePersonas?.first;
                  });
                }

                if (widget.wc2Proposal != null) {
                  setState(() {
                    selectedPersona = statePersonas
                        ?.firstWhereOrNull((e) => e.defaultAccount == 1);
                  });
                }

                setState(() {
                  personas = statePersonas;
                });
              }, builder: (context, state) {
                return _selectAccount();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appInfo() {
    final wc2Proposer = widget.wc2Proposal?.proposer;
    if (wc2Proposer != null) {
      final peer = WCPeerMeta(
        name: wc2Proposer.name,
        url: wc2Proposer.url,
        description: wc2Proposer.description,
        icons: wc2Proposer.icons,
      );
      return _wcAppInfo(peer);
    } else if (widget.wcConnectArgs != null) {
      return _wcAppInfo(widget.wcConnectArgs!.peerMeta);
    }

    if (widget.beaconRequest != null) {
      return _tbAppInfo(widget.beaconRequest!);
    }

    return const SizedBox();
  }

  Widget _selectAccount() {
    final statePersonas = personas;
    if (statePersonas == null) return const SizedBox();

    if (statePersonas.isEmpty) {
      return Expanded(child: _createAccountAndConnect());
    }
    if (widget.wc2Proposal != null) {
      return Expanded(
        child: Column(
          children: [
            const Expanded(child: SizedBox()),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: padding,
                    child: AuPrimaryButton(
                      text: "connect".tr(),
                      onPressed: () => withDebounce(() => _approveThenNotify()),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      );
    }
    return Expanded(child: _selectPersonaWidget(statePersonas));
  }

  Widget _wcAppInfo(WCPeerMeta peerMeta) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (peerMeta.icons.isNotEmpty) ...[
          CachedNetworkImage(
            imageUrl: peerMeta.icons.first,
            width: 64.0,
            height: 64.0,
            errorWidget: (context, url, error) => SizedBox(
                width: 64,
                height: 64,
                child:
                    Image.asset("assets/images/walletconnect-alternative.png")),
          ),
        ] else ...[
          SizedBox(
              width: 64,
              height: 64,
              child:
                  Image.asset("assets/images/walletconnect-alternative.png")),
        ],
        const SizedBox(width: 16.0),
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

  Widget _tbAppInfo(BeaconRequest request) {
    final theme = Theme.of(context);

    return Row(
      children: [
        request.icon != null
            ? CachedNetworkImage(
                imageUrl: request.icon!,
                width: 64.0,
                height: 64.0,
                errorWidget: (context, url, error) => SvgPicture.asset(
                  "assets/images/tezos_social_icon.svg",
                  width: 64.0,
                  height: 64.0,
                ),
              )
            : SvgPicture.asset(
                "assets/images/tezos_social_icon.svg",
                width: 64.0,
                height: 64.0,
              ),
        const SizedBox(width: 24.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.appName ?? "",
                  style: theme.textTheme.ppMori700Black24),
            ],
          ),
        )
      ],
    );
  }

  Widget _selectPersonaWidget(List<Persona> personas) {
    bool hasRadio = personas.length > 1;
    final theme = Theme.of(context);
    if (!hasRadio) _isAccountSelected = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Text(
            "select_grand_access".tr(), //"Select an account to grant access:",
            style: theme.textTheme.ppMori400Black16,
          ),
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: ListView(
            children: <Widget>[
              ...personas
                  .map((persona) => Column(
                        children: [
                          Padding(
                            padding: ResponsiveLayout.pageEdgeInsets
                                .copyWith(top: 0, bottom: 0),
                            child: GestureDetector(
                              child: ListTile(
                                title: Row(
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      height: 32,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Image.asset(
                                              "assets/images/moma_logo.png"),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    FutureBuilder<String>(
                                      future: persona.wallet().getAccountDID(),
                                      builder: (context, snapshot) {
                                        final name = persona.name.isNotEmpty
                                            ? persona.name
                                            : snapshot.data ?? '';
                                        return Expanded(
                                          child: Text(
                                            name.replaceFirst('did:key:', ''),
                                            style: theme
                                                .textTheme.ppMori400Black14,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                contentPadding: EdgeInsets.zero,
                                trailing: (hasRadio
                                    ? AuRadio(
                                        onTap: (Persona? persona) {
                                          setState(() {
                                            selectedPersona = persona;
                                            _isAccountSelected = true;
                                          });
                                        },
                                        value: persona,
                                        groupValue: selectedPersona,
                                      )
                                    : null),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedPersona = persona;
                                  _isAccountSelected = true;
                                });
                              },
                            ),
                          ),
                          addOnlyDivider(),
                        ],
                      ))
                  .toList(),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: padding,
                child: AuPrimaryButton(
                  text: "connect".tr(),
                  onPressed: _isAccountSelected
                      ? () {
                          metricClient.addEvent(MixpanelEvent.connectMarket);
                          withDebounce(() => _approveThenNotify());
                        }
                      : null,
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _createAccountAndConnect() {
    return Padding(
      padding: ResponsiveLayout.pageHorizontalEdgeInsets,
      child: Column(
        children: [
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: "connect".tr(),
                  onTap: () {
                    metricClient.addEvent(MixpanelEvent.connectMarket);
                    withDebounce(() => _createAccount());
                  },
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Future _createAccount() async {
    UIHelper.showLoadingScreen(context, text: "connecting".tr());
    final account = await injector<AccountService>().getDefaultAccount();
    final defaultName = await account.getAccountDID();
    var persona =
        await injector<CloudDatabase>().personaDao.findById(account.uuid);
    final namedPersona =
        await injector<AccountService>().namePersona(persona!, defaultName);
    injector<ConfigurationService>().setDoneOnboarding(true);
    injector<MetricClientService>().mixPanelClient.initIfDefaultAccount();
    selectedPersona = namedPersona;
    _approveThenNotify(onBoarding: true);
  }
}

class WCConnectPageArgs {
  final int id;
  final WCPeerMeta peerMeta;

  WCConnectPageArgs(this.id, this.peerMeta);
}
