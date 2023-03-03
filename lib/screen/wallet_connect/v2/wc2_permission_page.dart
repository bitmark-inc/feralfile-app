//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/radio_check_box.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';

class Wc2RequestPage extends StatefulWidget {
  final Wc2Request request;

  const Wc2RequestPage({Key? key, required this.request}) : super(key: key);

  @override
  State<Wc2RequestPage> createState() => _Wc2RequestPageState();
}

class _Wc2RequestPageState extends State<Wc2RequestPage>
    with RouteAware, WidgetsBindingObserver {
  Persona? selectedPersona;
  List<Persona>? personas;

  bool get _isAccountSelected =>
      selectedAddress.values.every((element) => element != null);
  late Wc2PermissionsRequestParams params;
  bool _selectETHAddress = false;
  bool _selectXTZAddress = false;

  final selectedAddress = {};
  bool _includeLinkedAccount = false;

  @override
  void initState() {
    super.initState();
    params = Wc2PermissionsRequestParams.fromJson(widget.request.params);

    // ignore: avoid_function_literals_in_foreach_calls
    params.permissions.firstOrNull?.request.chains.forEach((element) {
      selectedAddress[element] = null;
    });

    _includeLinkedAccount =
        params.permissions.firstOrNull?.includeLinkedAccount ?? false;

    _selectETHAddress = selectedAddress.containsKey('eip155:1');
    _selectXTZAddress = selectedAddress.containsKey('tezos');

    context.read<AccountsBloc>().add(
          GetCategorizedAccountsEvent(
            includeLinkedAccount: _includeLinkedAccount,
            getEth: _selectETHAddress,
            getTezos: _selectXTZAddress,
          ),
        );
    injector<NavigationService>().setIsWCConnectInShow(true);
  }

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
  }

  Future _reject() async {
    log.info("[Wc2RequestPage] Reject request.");
    try {
      await injector<Wc2Service>().respondOnReject(
        widget.request.topic,
        reason: "User reject",
      );
    } catch (e) {
      log.info("[Wc2RequestPage] Reject request error. $e");
    }
  }

  Future<String> _handleAuPermissionRequest({
    required Wc2PermissionsRequestParams params,
  }) async {
    final accountService = injector<AccountService>();

    final signature = await (await accountService.getDefaultAccount())
        .getAccountDIDSignature(params.message);
    final permissionResults = params.permissions.map((permission) async {
      final chainFutures = permission.request.chains.map((chain) async {
        try {
          final account = await accountService.getAccountByAddress(
              chain: chain, address: selectedAddress[chain]);
          final chainResp = await account.signPermissionRequest(
            chain: chain,
            message: params.message,
          );
          return chainResp;
        } on AccountException {
          return Wc2Chain(
            chain: chain,
            address: selectedAddress[chain],
          );
        }
      });
      final chains = (await Future.wait(chainFutures))
          .where((e) => e != null)
          .map((e) => e as Wc2Chain)
          .toList();
      return Wc2PermissionResult(
        type: permission.type,
        result: Wc2ChainResult(
          chains: chains,
        ),
      );
    });
    final result = Wc2PermissionResponse(
      signature: signature,
      permissionResults: await Future.wait(permissionResults),
    );
    return jsonEncode(result);
  }

  Future _approve() async {
    final wc2Service = injector<Wc2Service>();
    final params = Wc2PermissionsRequestParams.fromJson(widget.request.params);

    final response = await _handleAuPermissionRequest(
      params: params,
    );
    await wc2Service.respondOnApprove(widget.request.topic, response);

    if (!mounted) return;
    Navigator.of(context).pop();

    showInfoNotification(
      const Key("signed"),
      "signed".tr(),
      frontWidget: SvgPicture.asset(
        "assets/images/checkbox_icon.svg",
        width: 24,
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      showInfoNotification(const Key("switchBack"), "you_all_set".tr());
    });
  }

  Widget _wcAppInfo() {
    final theme = Theme.of(context);
    final proposer = widget.request.proposer;
    if (proposer == null) return const SizedBox();
    final peerMeta = WCPeerMeta(
      name: proposer.name,
      url: proposer.url,
      description: proposer.description,
      icons: proposer.icons,
    );
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
              child: Image.asset(
                "assets/images/walletconnect-alternative.png",
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: 64,
            height: 64,
            child: Image.asset(
              "assets/images/walletconnect-alternative.png",
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        await _reject();
        return true;
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () async {
            await _reject();
            if (!mounted) return;
            Navigator.pop(context);
          },
          title: "address_request".tr(),
        ),
        body: Container(
          margin: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              Padding(
                padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                child: addTitleSpace(),
              ),
              Padding(
                padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                child: _wcAppInfo(),
              ),
              const SizedBox(height: 32),
              addDivider(height: 52),
              Expanded(
                child: SingleChildScrollView(
                  child: BlocConsumer<AccountsBloc, AccountsState>(
                      listener: (context, state) async {
                    final categorizedAccounts = state.categorizedAccounts ?? [];

                    final selectManual = categorizedAccounts.length > 1 ||
                        (_selectETHAddress &&
                            categorizedAccounts.first.ethAccounts.length > 1) ||
                        (_selectXTZAddress &&
                            categorizedAccounts.first.xtzAccounts.length > 1);

                    if (!selectManual) {
                      selectedAddress['eip155:1'] = categorizedAccounts
                          .first.ethAccounts.first.accountNumber;
                      selectedAddress['tezos'] = categorizedAccounts
                          .first.xtzAccounts.first.accountNumber;
                      setState(() {});
                    }
                  }, builder: (context, state) {
                    final categorizedAccounts = state.categorizedAccounts ?? [];
                    if (categorizedAccounts.isEmpty) return const SizedBox();

                    final selectManual = categorizedAccounts.length > 1 ||
                        (_selectETHAddress &&
                            categorizedAccounts.first.ethAccounts.length > 1) ||
                        (_selectXTZAddress &&
                            categorizedAccounts.first.xtzAccounts.length > 1);

                    if (!selectManual) {
                      return Column(
                        children: [
                          Padding(
                            padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                            child: Text(
                              'verify_the_addresses'.tr(),
                              style: theme.textTheme.ppMori400Black16,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          PersonalConnectItem(
                            categorizedAccount: categorizedAccounts.first,
                            isAutoSelect: true,
                            isExpand: true,
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                          child: Text(
                            _selectETHAddress && _selectXTZAddress
                                ? "select_tezo_and_eth_address"
                                    .tr(args: ['1', '1'])
                                : _selectETHAddress
                                    ? 'select_eth_address'.tr(args: ['1'])
                                    : _selectXTZAddress
                                        ? 'select_tezos_address'.tr(args: ['1'])
                                        : 'select_grand_access'.tr(),
                            style: theme.textTheme.ppMori400Black16,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        ListAccountConnect(
                          categorizedAccounts: categorizedAccounts,
                          onSelectEth: (value) {
                            setState(() {
                              selectedAddress['eip155:1'] = value;
                            });
                          },
                          onSelectTez: (value) {
                            setState(() {
                              selectedAddress['tezos'] = value;
                            });
                          },
                        ),
                      ],
                    );
                  }),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                      child: PrimaryButton(
                        enabled: _isAccountSelected,
                        text: "h_confirm".tr(),
                        onTap: _isAccountSelected
                            ? () => withDebounce(() => _approve())
                            : null,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ListAccountConnect extends StatefulWidget {
  final List<CategorizedAccounts> categorizedAccounts;
  final Function(String)? onSelectEth;
  final Function(String)? onSelectTez;

  const ListAccountConnect({
    Key? key,
    required this.categorizedAccounts,
    this.onSelectEth,
    this.onSelectTez,
  }) : super(key: key);

  @override
  State<ListAccountConnect> createState() => _ListAccountConnectState();
}

class _ListAccountConnectState extends State<ListAccountConnect> {
  late List<CategorizedAccounts> categorizedAccounts;
  String? tezSelectedAddress;
  String? ethSelectedAddress;

  @override
  void initState() {
    categorizedAccounts = widget.categorizedAccounts;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...categorizedAccounts
            .map((categorizedAccount) => Column(
                  children: [
                    PersonalConnectItem(
                      categorizedAccount: categorizedAccount,
                      ethSelectedAddress: ethSelectedAddress,
                      tezSelectedAddress: tezSelectedAddress,
                      isExpand: categorizedAccounts.first == categorizedAccount,
                      onSelectEth: (value) {
                        widget.onSelectEth?.call(value);
                        setState(() {
                          ethSelectedAddress = value;
                        });
                      },
                      onSelectTez: (value) {
                        widget.onSelectTez?.call(value);
                        setState(() {
                          tezSelectedAddress = value;
                        });
                      },
                    )
                  ],
                ))
            .toList(),
      ],
    );
  }
}

class AddressItem extends StatelessWidget {
  const AddressItem({
    Key? key,
    required this.cryptoType,
    required this.address,
    this.ethSelectedAddress,
    this.tezSelectedAddress,
    this.onTap,
    this.isAutoSelect = false,
  }) : super(key: key);

  final CryptoType cryptoType;
  final String address;
  final String? ethSelectedAddress;
  final String? tezSelectedAddress;
  final bool isAutoSelect;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: ResponsiveLayout.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LogoCrypto(
                  cryptoType: cryptoType,
                  size: 24,
                ),
                const SizedBox(
                  width: 34,
                ),
                Text(
                  cryptoType == CryptoType.ETH
                      ? 'Ethereum'
                      : cryptoType == CryptoType.XTZ
                          ? 'Tezos'
                          : '',
                  style: theme.textTheme.ppMori700Black14,
                ),
                const Spacer(),
                Visibility(
                  visible: !isAutoSelect,
                  child: RadioSelectAddress(
                    isChecked: address == ethSelectedAddress ||
                        address == tezSelectedAddress,
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              address,
              style: theme.textTheme.ibmBlackNormal14,
            )
          ],
        ),
      ),
    );
  }
}

class PersonalConnectItem extends StatefulWidget {
  final CategorizedAccounts categorizedAccount;
  final String? tezSelectedAddress;
  final String? ethSelectedAddress;

  final Function(String)? onSelectEth;
  final Function(String)? onSelectTez;

  final bool isAutoSelect;
  final bool isExpand;

  const PersonalConnectItem({
    Key? key,
    required this.categorizedAccount,
    this.tezSelectedAddress,
    this.ethSelectedAddress,
    this.onSelectEth,
    this.onSelectTez,
    this.isAutoSelect = false,
    this.isExpand = false,
  }) : super(key: key);

  @override
  State<PersonalConnectItem> createState() => _PersonalConnectItemState();
}

class _PersonalConnectItemState extends State<PersonalConnectItem> {
  bool _showDetail = false;

  @override
  void initState() {
    super.initState();
    _showDetail = widget.isExpand;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          onTap: () {
            setState(() {
              _showDetail = !_showDetail;
            });
          },
          title: Padding(
            padding: ResponsiveLayout.pageHorizontalEdgeInsets,
            child: Row(
              children: [
                accountLogo(context, widget.categorizedAccount.accounts.first,
                    size: 24),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    widget.categorizedAccount.category,
                    style: theme.textTheme.ppMori400Black14,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Visibility(
                    visible: !widget.categorizedAccount.isPersona,
                    child: linkedBox(context)),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: _showDetail ? 0.75 : 0.5,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      AuIcon.chevron,
                      size: 12,
                    ),
                  ),
                )
              ],
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        Divider(
          height: 1.0,
          color: theme.auQuickSilver,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showDetail
              ? Column(
                  children: [
                    ...widget.categorizedAccount.accounts.map(
                      (e) => Column(
                        children: [
                          AddressItem(
                            onTap: () {
                              if (e.isEth) {
                                widget.onSelectEth?.call(e.accountNumber);
                              }
                              if (e.isTez) {
                                widget.onSelectTez?.call(e.accountNumber);
                              }
                            },
                            isAutoSelect: widget.isAutoSelect,
                            address: e.accountNumber,
                            cryptoType:
                                e.isEth ? CryptoType.ETH : CryptoType.XTZ,
                            ethSelectedAddress: widget.ethSelectedAddress,
                            tezSelectedAddress: widget.tezSelectedAddress,
                          ),
                          Divider(
                            height: 1.0,
                            color: theme.auLightGrey,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox(),
        ),
      ],
    );
  }
}

class LogoCrypto extends StatelessWidget {
  final CryptoType? cryptoType;
  final double? size;

  const LogoCrypto({Key? key, this.cryptoType, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cryptoType == CryptoType.XTZ) {
      return SvgPicture.asset(
        "assets/images/tez.svg",
        width: size,
        height: size,
      );
    }
    if (cryptoType == CryptoType.ETH) {
      return SvgPicture.asset(
        'assets/images/ether.svg',
        width: size,
        height: size,
      );
    }
    return Container();
  }
}
