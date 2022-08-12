//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/material.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share/share.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

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
      case CryptoType.BITMARK:
        // do nothing
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: widget.payload.address.mask(4),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: const EdgeInsets.only(
            top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _addressSection(),
                    if (widget.payload.type != CryptoType.BITMARK) ...[
                      const SizedBox(height: 40),
                      _connectionsSection(),
                    ],
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _addressSection() {
    var address = widget.payload.address;
    final addressSource = widget.payload.type.source;
    final theme = Theme.of(context);
    final addressStyle = theme.textTheme.subtitle1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Address",
          style: theme.textTheme.headline1,
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(addressSource, style: theme.textTheme.headline4),
                TextButton(
                  onPressed: () => Share.share(address),
                  child: Text(
                    "Share",
                    style: theme.textTheme.atlasBlackBold12,
                  ),
                )
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    address,
                    style: addressStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _connectionsSection() {
    final theme = Theme.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "Connections",
        style: theme.textTheme.headline1,
      ),
      const SizedBox(height: 24),
      BlocBuilder<ConnectionsBloc, ConnectionsState>(builder: (context, state) {
        final connectionItems = state.connectionItems;
        if (connectionItems == null) return const SizedBox();

        if (connectionItems.isEmpty) {
          return _emptyConnectionsWidget();
        } else {
          int index = 0;
          return Column(
            children: [
              ...connectionItems.map((connectionItem) {
                index++;
                return Column(
                  children: [
                    _connectionItemWidget(connectionItem),
                    index < connectionItems.length
                        ? addOnlyDivider()
                        : const SizedBox(),
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
      TappableForwardRowWithContent(
          leftWidget: Row(children: [
            SvgPicture.asset("assets/images/iconQr.svg"),
            const SizedBox(width: 17.5),
            Text('Add connection', style: theme.textTheme.headline4),
          ]),
          bottomWidget: Text(
              "Connect this address to an external dapp or platform.",
              style: theme.textTheme.bodyText1),
          onTap: () {
            late ScannerItem scanItem;

            switch (widget.payload.type) {
              case CryptoType.ETH:
                scanItem = ScannerItem.WALLET_CONNECT;
                break;
              case CryptoType.XTZ:
                scanItem = ScannerItem.BEACON_CONNECT;
                break;
              case CryptoType.BITMARK:
                // TODO: Handle this case.
                break;
            }

            Navigator.of(context)
                .pushNamed(AppRouter.scanQRPage, arguments: scanItem);
          }),
    ]);
  }

  Widget _connectionItemWidget(ConnectionItem connectionItem) {
    final connection = connectionItem.representative;
    final theme = Theme.of(context);

    return TappableForwardRow(
        leftWidget: Expanded(
          child: Row(children: [
            UIHelper.buildConnectionAppWidget(connection, 24),
            const SizedBox(width: 16),
            Expanded(
                child:
                    Text(connection.appName, style: theme.textTheme.headline4)),
          ]),
        ),
        onTap: () => Navigator.of(context).pushNamed(
            AppRouter.connectionDetailsPage,
            arguments: connectionItem));
  }
}

class PersonaConnectionsPayload {
  final String personaUUID;
  final String address;
  final CryptoType type;

  PersonaConnectionsPayload({
    required this.personaUUID,
    required this.address,
    required this.type,
  });
}
