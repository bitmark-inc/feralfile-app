//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/usdc/usdc_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../view/responsive.dart';

class PersonaConnectionsPage extends StatefulWidget {
  final PersonaConnectionsPayload payload;

  const PersonaConnectionsPage({Key? key, required this.payload})
      : super(key: key);

  @override
  State<PersonaConnectionsPage> createState() => _PersonaConnectionsPageState();
}

class _PersonaConnectionsPageState extends State<PersonaConnectionsPage>
    with RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    final personUUID = widget.payload.personaUUID;
    context.read<AccountsBloc>().add(
        FindAccount(personUUID, widget.payload.address, widget.payload.type));
    switch (widget.payload.type) {
      case CryptoType.ETH:
        context.read<EthereumBloc>().add(GetEthereumAddressEvent(personUUID));
        context
            .read<EthereumBloc>()
            .add(GetEthereumBalanceWithUUIDEvent(personUUID));
        break;
      case CryptoType.XTZ:
        context.read<TezosBloc>().add(GetTezosBalanceWithUUIDEvent(personUUID));
        context.read<TezosBloc>().add(GetTezosAddressEvent(personUUID));
        break;
      case CryptoType.USDC:
        context.read<USDCBloc>().add(GetAddressEvent(personUUID));
        context.read<USDCBloc>().add(GetUSDCBalanceWithUUIDEvent(personUUID));
        break;
      case CryptoType.UNKNOWN:
        // do nothing
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    _callFetchConnections();
    memoryValues =
        memoryValues.copyWith(scopedPersona: widget.payload.personaUUID);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _callFetchConnections();
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
    memoryValues.scopedPersona = null;
  }

  void _callFetchConnections() {
    final personUUID = widget.payload.personaUUID;

    switch (widget.payload.type) {
      case CryptoType.ETH:
        context.read<ConnectionsBloc>().add(GetETHConnectionsEvent(personUUID));
        break;
      case CryptoType.XTZ:
        context.read<ConnectionsBloc>().add(GetXTZConnectionsEvent(personUUID));
        break;
      default:
        // do nothing
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'connections_with_dapps'.tr(),
          onBack: () {
            if (widget.payload.isBackHome) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.homePage,
                (route) => false,
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              addTitleSpace(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.payload.type == CryptoType.ETH ||
                          widget.payload.type == CryptoType.XTZ) ...[
                        _connectionsSection(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _connectionsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      BlocBuilder<ConnectionsBloc, ConnectionsState>(builder: (context, state) {
        final connectionItems = state.connectionItems;
        if (connectionItems == null) return const SizedBox();

        if (connectionItems.isEmpty) {
          return _emptyConnectionsWidget();
        } else {
          return Column(
            children: [
              ...connectionItems.map((connectionItem) {
                return Column(
                  children: [
                    Padding(
                      padding: ResponsiveLayout.pageEdgeInsets
                          .copyWith(top: 0, bottom: 0),
                      child: _connectionItemWidget(connectionItem),
                    ),
                    addOnlyDivider()
                  ],
                );
              }).toList(),
            ],
          );
        }
      }),
    ]);
  }

  Widget _emptyConnectionsWidget() {
    final theme = Theme.of(context);
    return Column(children: [
      Padding(
        padding: ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0),
        child: TappableForwardRowWithContent(
            leftWidget: Row(children: [
              Text('add_connection'.tr(),
                  style: theme.textTheme.ppMori400Black16),
            ]),
            bottomWidget: Text("connect_dapp".tr(),
                //"Connect this address to an external dapp or platform.",
                style: theme.textTheme.ppMori400Black14),
            onTap: () {
              late ScannerItem scanItem;

              switch (widget.payload.type) {
                case CryptoType.ETH:
                  scanItem = ScannerItem.WALLET_CONNECT;
                  break;
                case CryptoType.XTZ:
                  scanItem = ScannerItem.BEACON_CONNECT;
                  break;
                default:
                  break;
              }

              Navigator.of(context)
                  .pushNamed(AppRouter.scanQRPage, arguments: scanItem);
            }),
      ),
      addOnlyDivider(),
    ]);
  }

  Widget _connectionItemWidget(ConnectionItem connectionItem) {
    final connection = connectionItem.representative;
    final theme = Theme.of(context);

    return TappableForwardRow(
      leftWidget: Row(children: [
        UIHelper.buildConnectionAppWidget(connection, 24),
        const SizedBox(width: 32),
        Expanded(
            child: Text(
          connection.appName,
          style: theme.textTheme.ppMori400Black14,
          overflow: TextOverflow.ellipsis,
        )),
      ]),
      onTap: () {
        Navigator.of(context).pushNamed(AppRouter.connectionDetailsPage,
            arguments: connectionItem);
        _callFetchConnections();
      },
    );
  }
}

class PersonaConnectionsPayload {
  final String personaUUID;
  final String address;
  final CryptoType type;
  final String personaName;
  final bool isBackHome;

  PersonaConnectionsPayload({
    required this.personaUUID,
    required this.address,
    required this.type,
    required this.personaName,
    this.isBackHome = false,
  });
}
