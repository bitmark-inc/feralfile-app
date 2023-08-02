//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';

class LinkedAccountDetailsPage extends StatefulWidget {
  final Connection connection;

  const LinkedAccountDetailsPage({Key? key, required this.connection})
      : super(key: key);

  @override
  State<LinkedAccountDetailsPage> createState() =>
      _LinkedAccountDetailsPageState();
}

class _LinkedAccountDetailsPageState extends State<LinkedAccountDetailsPage>
    with RouteAware {
  final Map<String, String> _balances = {};
  List<ContextedAddress> contextAddresses = [];
  String _source = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final address = widget.connection.accountNumber;

    switch (widget.connection.connectionType) {
      case 'feralFileWeb3':
      case 'feralFileToken':
        _source = "FeralFile";

        context
            .read<FeralfileBloc>()
            .add(GetFFAccountInfoEvent(widget.connection));

        final ffAccount = widget.connection.ffConnection?.ffAccount ??
            widget.connection.ffWeb3Connection?.ffAccount;
        final ethereumAddress = ffAccount?.ethereumAddress;
        final tezosAddress = ffAccount?.tezosAddress;

        if (ethereumAddress != null) {
          contextAddresses
              .add(ContextedAddress(CryptoType.ETH, ethereumAddress));
          fetchETHBalance(ethereumAddress);
        }

        if (tezosAddress != null) {
          contextAddresses.add(ContextedAddress(CryptoType.XTZ, tezosAddress));
          fetchXtzBalance(tezosAddress);
        }

        break;

      case "walletBeacon":
        _source = widget.connection.walletBeaconConnection?.peer.name ??
            "tezos_wallet".tr();
        contextAddresses.add(ContextedAddress(CryptoType.XTZ, address));
        fetchXtzBalance(address);
        break;

      case "walletBrowserConnect":
        _source = widget.connection.data;
        contextAddresses.add(ContextedAddress(CryptoType.ETH, address));
        fetchETHBalance(address);
        break;

      case 'ledger':
        final data = widget.connection.ledgerConnection;
        _source = data?.ledgerName ?? 'Unknown';
        final ethereumAddress = data?.etheremAddress.firstOrNull;
        final tezosAddress = data?.tezosAddress.firstOrNull;

        if (ethereumAddress != null) {
          contextAddresses
              .add(ContextedAddress(CryptoType.ETH, ethereumAddress));
          fetchETHBalance(ethereumAddress);
        }

        if (tezosAddress != null) {
          contextAddresses.add(ContextedAddress(CryptoType.XTZ, tezosAddress));
          fetchXtzBalance(tezosAddress);
        }
        break;
      case "manuallyAddress":
        contextAddresses.add(ContextedAddress(
            CryptoType.UNKNOWN, widget.connection.accountNumber));
        break;

      default:
        break;
    }
  }

  Future fetchXtzBalance(String address) async {
    int balance = await injector<TezosService>().getBalance(address);
    setState(() {
      _balances[address] = "${XtzAmountFormatter(balance).format()} XTZ";
    });
  }

  Future fetchETHBalance(String address) async {
    final balance = await injector<EthereumService>().getBalance(address);
    setState(() {
      _balances[address] =
          "${EthAmountFormatter(balance.getInWei).format()} ETH";
    });
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
    super.didPopNext();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.connection.connectionType) {
      case 'feralFileWeb3':
      case 'feralFileToken':
        _source = "FeralFile";

        final feralFileState = context.watch<FeralfileBloc>().state;
        final wyreWallet =
            (feralFileState.connection?.ffConnection?.ffAccount ??
                    feralFileState.connection?.ffWeb3Connection?.ffAccount)
                ?.wyreWallet;
        if (wyreWallet != null) {
          setState(() {
            _balances[widget.connection.accountNumber] =
                "${wyreWallet.availableBalances['USDC'] ?? 0} USDC";
          });
        }
        break;
    }

    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: widget.connection.name.isNotEmpty
            ? widget.connection.name.maskIfNeeded()
            : widget.connection.accountNumber,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            addTitleSpace(),
            Padding(
              padding: padding,
              child: _addressesSection(context),
            ),
            addOnlyDivider(),
            const SizedBox(height: 16),
            Padding(
              padding: padding,
              child: _backupSection(context),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _addressesSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contextAddresses.length > 1
              ? "linked_addresses".tr()
              : "linked_address".tr(),
          style: theme.textTheme.ppMori400Black16,
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...contextAddresses.map(
              (e) => Column(
                children: [
                  _addressRow(context, e.cryptoType,
                      address: e.address,
                      balanceString: e.cryptoType != CryptoType.UNKNOWN
                          ? _balances[e.address] ?? '-- ${e.cryptoType.code}'
                          : ""),
                  e == contextAddresses.last
                      ? const SizedBox()
                      : addOnlyDivider(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _addressRow(BuildContext context, CryptoType type,
      {required String address, required balanceString}) {
    final theme = Theme.of(context);
    final balanceStyle = theme.textTheme.ppMori400Grey14;
    final isHideGalleryEnabled =
        injector<AccountService>().isLinkedAccountHiddenInGallery(address);
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dragDismissible: false,
        children: slidableActions(context, address),
      ),
      child: TappableForwardRowWithContent(
        leftWidget: Text(type.source, style: theme.textTheme.ppMori700Black14),
        rightWidget: Row(
          children: [
            if (isHideGalleryEnabled) ...[
              SvgPicture.asset(
                'assets/images/hide.svg',
                color: theme.colorScheme.surface,
              ),
              const SizedBox(width: 10),
            ],
            Text(balanceString, style: balanceStyle),
          ],
        ),
        bottomWidget: Text(
          address,
          style: theme.textTheme.ppMori400Black14,
        ),
        onTap: () {},
      ),
    );
  }

  Widget _backupSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("backup".tr(), style: theme.textTheme.ppMori400Black16),
        const SizedBox(height: 24),
        if (_source == 'FeralFile') ...[
          Text("ba_the_keys_for_thisFf".tr(),
              //'The keys for this account are either automatically backed up by Feral File or managed by your web3 wallet (if you connected one).',
              style: theme.textTheme.ppMori400Black14),
        ] else ...[
          Text("ba_the_keys_for_this".tr(args: [_source]),
              //"The keys for this account are in $_source. You should manage your key backups there.",
              style: theme.textTheme.ppMori400Black14),
        ],
      ],
    );
  }

  List<CustomSlidableAction> slidableActions(
      BuildContext context, String address) {
    final theme = Theme.of(context);
    final isHidden =
        injector<AccountService>().isLinkedAccountHiddenInGallery(address);
    return [
      CustomSlidableAction(
        backgroundColor: AppColor.secondarySpanishGrey,
        foregroundColor: theme.colorScheme.secondary,
        child: Semantics(
          label: "${address}_hide",
          child: SvgPicture.asset(
              isHidden ? 'assets/images/unhide.svg' : 'assets/images/hide.svg'),
        ),
        onPressed: (_) async {
          await injector<AccountService>()
              .setHideLinkedAccountInGallery(address, !isHidden);
          setState(() {});
        },
      ),
    ];
  }
}
