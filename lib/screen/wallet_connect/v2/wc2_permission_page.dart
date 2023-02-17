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
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/account_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
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

import '../../../util/string_ext.dart';

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

    context
        .read<PersonaBloc>()
        .add(GetListPersonaEvent(useDidKeyForAlias: true));
    context.read<AccountsBloc>().add(GetAccountsEvent());
    injector<NavigationService>().setIsWCConnectInShow(true);
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
                    var statePersonas = state.accounts;
                    if (statePersonas == null) return;
                    final personaAccount = statePersonas
                        .where((element) => element.persona != null)
                        .toList();
                    if (personaAccount.length == 1 &&
                        personaAccount.first.persona != null &&
                        !_includeLinkedAccount) {
                      selectedAddress['eip155:1'] =
                          await personaAccount.first.getAddress('eip155:1');
                      selectedAddress['tezos'] =
                          await personaAccount.first.getAddress('tezos');
                      setState(() {});
                    }
                  }, builder: (context, state) {
                    final stateAccount = state.accounts;
                    if (stateAccount == null) return const SizedBox();
                    final personaAccount = stateAccount
                        .where((element) => element.persona != null)
                        .toList();
                    if (personaAccount.length == 1 &&
                        personaAccount.first.persona != null &&
                        !_includeLinkedAccount) {
                      return Column(
                        children: [
                          Padding(
                            padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                            child: Text(
                              'Verify the addresses that will be accessed before confirming:',
                              style: theme.textTheme.ppMori400Black16,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          PersionalConnectItem(
                            account: personaAccount.first,
                            showETH: _selectETHAddress,
                            showXTZ: _selectXTZAddress,
                            isSingleMode: true,
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
                          includeLinkedAccount: _includeLinkedAccount,
                          accounts: stateAccount,
                          showETH: _selectETHAddress,
                          showXTZ: _selectXTZAddress,
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
  final List<Account> accounts;
  final bool showETH;
  final bool showXTZ;
  final bool includeLinkedAccount;
  final Function(String)? onSelectEth;
  final Function(String)? onSelectTez;

  const ListAccountConnect({
    Key? key,
    required this.accounts,
    this.showETH = true,
    this.showXTZ = true,
    this.onSelectEth,
    this.onSelectTez,
    required this.includeLinkedAccount,
  }) : super(key: key);

  @override
  State<ListAccountConnect> createState() => _ListAccountConnectState();
}

class _ListAccountConnectState extends State<ListAccountConnect> {
  late List<Account> accounts;
  String? tezSelectedAddress;
  String? ethSelectedAddress;

  @override
  void initState() {
    accounts = widget.accounts;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...accounts
            .map((account) => Column(
                  children: [
                    if (account.persona != null)
                      PersionalConnectItem(
                        account: account,
                        ethSelectedAddress: ethSelectedAddress,
                        tezSelectedAddress: tezSelectedAddress,
                        showETH: widget.showETH,
                        showXTZ: widget.showXTZ,
                        isExpand: accounts.first == account,
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
                    else if (widget.includeLinkedAccount)
                      LinkedAccountConnectItem(
                        account: account,
                        ethSelectedAddress: ethSelectedAddress,
                        tezSelectedAddress: tezSelectedAddress,
                        showETH: widget.showETH,
                        showXTZ: widget.showXTZ,
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
                      ),
                  ],
                ))
            .toList(),
      ],
    );
  }
}

class LinkedAccountConnectItem extends StatefulWidget {
  final Account account;
  final String? tezSelectedAddress;
  final String? ethSelectedAddress;

  final bool showETH;
  final bool showXTZ;

  final Function(String)? onSelectEth;
  final Function(String)? onSelectTez;

  const LinkedAccountConnectItem({
    Key? key,
    required this.account,
    this.tezSelectedAddress,
    this.ethSelectedAddress,
    this.onSelectEth,
    this.onSelectTez,
    required this.showETH,
    required this.showXTZ,
  }) : super(key: key);

  @override
  State<LinkedAccountConnectItem> createState() =>
      _LinkedAccountConnectItemState();
}

class _LinkedAccountConnectItemState extends State<LinkedAccountConnectItem> {
  final List<ContextedAddress> listAddress = [];

  bool _showAccount = false;
  bool _showDetail = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final connection = widget.account.connections?.firstOrNull;
    if (connection == null) return;
    final address = connection.accountNumber;

    switch (connection.connectionType) {
      case 'feralFileWeb3':
      case 'feralFileToken':
        listAddress.add(ContextedAddress(CryptoType.UNKNOWN, address));

        final ffAccount = connection.ffConnection?.ffAccount ??
            connection.ffWeb3Connection?.ffAccount;
        final ethereumAddress = ffAccount?.ethereumAddress;
        final tezosAddress = ffAccount?.tezosAddress;

        if (ethereumAddress != null) {
          listAddress.add(ContextedAddress(CryptoType.ETH, ethereumAddress));
        }

        if (tezosAddress != null) {
          listAddress.add(ContextedAddress(CryptoType.XTZ, tezosAddress));
        }

        break;

      case "walletBeacon":
        listAddress.add(ContextedAddress(CryptoType.XTZ, address));
        break;

      case "walletConnect":
        listAddress.add(ContextedAddress(CryptoType.ETH, address));
        break;

      case "walletBrowserConnect":
        listAddress.add(ContextedAddress(CryptoType.ETH, address));
        break;

      case 'ledger':
        final data = connection.ledgerConnection;
        final ethereumAddress = data?.etheremAddress.firstOrNull;
        final tezosAddress = data?.tezosAddress.firstOrNull;

        if (ethereumAddress != null) {
          listAddress.add(ContextedAddress(CryptoType.ETH, ethereumAddress));
        }

        if (tezosAddress != null) {
          listAddress.add(ContextedAddress(CryptoType.XTZ, tezosAddress));
        }
        break;
      case "manuallyAddress":
        listAddress.add(
            ContextedAddress(CryptoType.UNKNOWN, connection.accountNumber));
        break;

      default:
        break;
    }
    setState(() {
      _showAccount = listAddress.any((element) => widget.showETH
          ? element.cryptoType == CryptoType.ETH
          : widget.showXTZ
              ? element.cryptoType == CryptoType.XTZ
              : false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final connection = widget.account.connections?.firstOrNull;
    if (connection == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Visibility(
      visible: _showAccount,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _showDetail = !_showDetail;
              });
            },
            title: Padding(
              padding: ResponsiveLayout.paddingAll,
              child: Row(
                children: [
                  accountLogo(context, widget.account),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      connection.name.isNotEmpty
                          ? connection.name.maskIfNeeded()
                          : connection.accountNumber.mask(4),
                      style: theme.textTheme.ppMori400Black14,
                    ),
                  ),
                  linkedBox(context),
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
          ...listAddress.map(
            (e) => Visibility(
              visible: e.cryptoType == CryptoType.ETH
                  ? widget.showETH
                  : e.cryptoType == CryptoType.XTZ
                      ? widget.showXTZ
                      : false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showDetail
                    ? AddressItem(
                        cryptoType: e.cryptoType,
                        address: e.address,
                        ethSelectedAddress: widget.ethSelectedAddress,
                        tezSelectedAddress: widget.tezSelectedAddress,
                        onTap: () {
                          e.cryptoType == CryptoType.ETH
                              ? widget.onSelectEth?.call(e.address)
                              : e.cryptoType == CryptoType.XTZ
                                  ? widget.onSelectTez?.call(e.address)
                                  : '';
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          const Divider(height: 16.0),
        ],
      ),
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
    this.isSingleMode = false,
  }) : super(key: key);

  final CryptoType cryptoType;
  final String address;
  final String? ethSelectedAddress;
  final String? tezSelectedAddress;
  final bool isSingleMode;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveLayout.paddingAll,
        color: isSingleMode ? Colors.transparent : Colors.black,
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
                  style: isSingleMode
                      ? theme.textTheme.ppMori700Black14
                      : theme.textTheme.ppMori700White14,
                ),
                const Spacer(),
                Visibility(
                  visible: !isSingleMode,
                  child: RadioCheckBox(
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
              style: isSingleMode
                  ? theme.textTheme.ibmBlackNormal14
                  : theme.textTheme.ibmWhiteNormal14,
            )
          ],
        ),
      ),
    );
  }
}

class PersionalConnectItem extends StatefulWidget {
  final Account account;
  final String? tezSelectedAddress;
  final String? ethSelectedAddress;

  final bool showETH;
  final bool showXTZ;

  final Function(String)? onSelectEth;
  final Function(String)? onSelectTez;

  final bool isSingleMode;
  final bool isExpand;

  const PersionalConnectItem({
    Key? key,
    required this.account,
    this.tezSelectedAddress,
    this.ethSelectedAddress,
    this.onSelectEth,
    this.onSelectTez,
    required this.showETH,
    required this.showXTZ,
    this.isSingleMode = false,
    this.isExpand = false,
  }) : super(key: key);

  @override
  State<PersionalConnectItem> createState() => _PersionalConnectItemState();
}

class _PersionalConnectItemState extends State<PersionalConnectItem> {
  final ethereumBloc = EthereumBloc(injector());
  final tezosBloc = TezosBloc(injector());
  bool _showDetail = false;

  @override
  void initState() {
    super.initState();
    _showDetail = widget.isExpand;
    if (widget.account.persona?.uuid != null) {
      ethereumBloc.add(GetEthereumAddressEvent(widget.account.persona!.uuid));
      tezosBloc.add(GetTezosAddressEvent(widget.account.persona!.uuid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uuid = widget.account.persona?.uuid;
    if (uuid == null) return const SizedBox();
    final theme = Theme.of(context);
    return Visibility(
      visible: widget.showETH || widget.showXTZ,
      child: Column(
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
                  accountLogo(context, widget.account, size: 24),
                  const SizedBox(width: 16.0),
                  FutureBuilder<String>(
                    future: widget.account.persona?.wallet().getAccountDID(),
                    builder: (context, snapshot) {
                      final name =
                          widget.account.persona?.name.isNotEmpty ?? false
                              ? widget.account.persona?.name
                              : snapshot.data ?? '';
                      return Expanded(
                        child: Text(
                          name?.replaceFirst('did:key:', '') ?? '',
                          style: theme.textTheme.ppMori400Black14,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showDetail
                ? Column(
                    children: [
                      Visibility(
                        visible: widget.showETH,
                        child: Column(
                          children: [
                            BlocBuilder<EthereumBloc, EthereumState>(
                              bloc: ethereumBloc,
                              builder: (context, state) {
                                final ethAddress =
                                    state.personaAddresses?[uuid];
                                if (ethAddress == null) return const SizedBox();
                                return AddressItem(
                                  onTap: () {
                                    widget.onSelectEth?.call(ethAddress);
                                  },
                                  isSingleMode: widget.isSingleMode,
                                  address: ethAddress,
                                  cryptoType: CryptoType.ETH,
                                  ethSelectedAddress: widget.ethSelectedAddress,
                                  tezSelectedAddress: widget.tezSelectedAddress,
                                );
                              },
                            ),
                            const Divider(
                              height: 1.0,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: widget.showXTZ,
                        child: Column(
                          children: [
                            BlocBuilder<TezosBloc, TezosState>(
                              bloc: tezosBloc,
                              builder: (context, state) {
                                final tezAddress =
                                    state.personaAddresses?[uuid];
                                if (tezAddress == null) return const SizedBox();
                                return AddressItem(
                                  onTap: () {
                                    widget.onSelectTez?.call(tezAddress);
                                  },
                                  address: tezAddress,
                                  isSingleMode: widget.isSingleMode,
                                  cryptoType: CryptoType.XTZ,
                                  ethSelectedAddress: widget.ethSelectedAddress,
                                  tezSelectedAddress: widget.tezSelectedAddress,
                                );
                              },
                            ),
                            const Divider(
                              height: 1.0,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
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
