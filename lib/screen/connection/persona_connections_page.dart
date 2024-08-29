//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/usdc/usdc_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/shared.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PersonaConnectionsPage extends StatefulWidget {
  final PersonaConnectionsPayload payload;

  const PersonaConnectionsPage({required this.payload, super.key});

  @override
  State<PersonaConnectionsPage> createState() => _PersonaConnectionsPageState();
}

class _PersonaConnectionsPageState extends State<PersonaConnectionsPage>
    with RouteAware, WidgetsBindingObserver {
  final _tezosBeaconService = injector<TezosBeaconService>();
  final _wallet2ConnectService = injector<Wc2Service>();

  @override
  void initState() {
    super.initState();
    final personUUID = widget.payload.personaUUID;
    final index = widget.payload.index;
    context.read<AccountsBloc>().add(
        FindAccount(personUUID, widget.payload.address, widget.payload.type));
    switch (widget.payload.type) {
      case CryptoType.ETH:
        context.read<EthereumBloc>().add(GetEthereumAddressEvent(personUUID));
        context
            .read<EthereumBloc>()
            .add(GetEthereumBalanceWithUUIDEvent(personUUID));
      case CryptoType.XTZ:
        context.read<TezosBloc>().add(GetTezosBalanceWithUUIDEvent(personUUID));
        context.read<TezosBloc>().add(GetTezosAddressEvent(personUUID));
      case CryptoType.USDC:
        context.read<USDCBloc>().add(GetAddressEvent(personUUID, index));
        context
            .read<USDCBloc>()
            .add(GetUSDCBalanceWithUUIDEvent(personUUID, index));
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
        context.read<ConnectionsBloc>().add(GetETHConnectionsEvent(
            personUUID, widget.payload.index, widget.payload.address));
      case CryptoType.XTZ:
        context.read<ConnectionsBloc>().add(GetXTZConnectionsEvent(
            personUUID, widget.payload.index, widget.payload.address));
      default:
        // do nothing
        break;
    }
  }

  void _showConnectionOption() {
    final options = [
      OptionItem(
          title: 'connect_via_clipboard'.tr(),
          icon: SvgPicture.asset('assets/images/DApp.svg'),
          onTap: () async {
            if (!mounted) {
              return;
            }
            Navigator.of(context).pop();
            try {
              final clipboardData = await Clipboard.getData('text/plain');
              if (clipboardData == null ||
                  clipboardData.text == null ||
                  clipboardData.text!.isEmpty) {
                throw ConnectionViaClipboardError('Clipboard is empty');
              }
              final text = clipboardData.text!;
              log.info('Connect via clipboard: $text');
              await _processDeeplink(text);
            } catch (e) {
              log.info('Connect via clipboard: failed $e');
              if (e is ConnectionViaClipboardError) {
                if (!mounted) {
                  return;
                }
                UIHelper.hideInfoDialog(context);
                unawaited(UIHelper.showInvalidURI(context));
              }
            }
          }),
      OptionItem(),
    ];
    unawaited(UIHelper.showDrawerAction(context, options: options));
  }

  bool _isTezosBeconUri(String uri) {
    try {
      final base58Decode = bs58check.decode(uri);
      final uriData = jsonDecode(String.fromCharCodes(base58Decode));
      return uriData['type'] == 'p2p-pairing-request';
    } catch (_) {
      return false;
    }
  }

  bool _isWalletConnectUri(String uri) => uri.startsWith('wc:');

  bool _isUriValid(String uri) =>
      _isWalletConnectUri(uri) || _isTezosBeconUri(uri);

  void _onConnectTimeout() {
    if (!mounted) {
      return;
    }
    UIHelper.hideInfoDialog(context);
    unawaited(UIHelper.showInvalidURI(context));
  }

  Future<void> _processDeeplink(String code) async {
    if (!_isUriValid(code)) {
      throw ConnectionViaClipboardError('Invalid URI');
    }
    if (code.startsWith('wc:')) {
      unawaited(
          _wallet2ConnectService.connect(code, onTimeout: _onConnectTimeout));
    } else {
      final tezosUri = 'tezos://?type=tzip10&data=$code';
      await _tezosBeaconService.addPeer(tezosUri, onTimeout: _onConnectTimeout);
      unawaited(injector<NavigationService>().showContactingDialog());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getBackAppBar(context, title: 'connections'.tr(), onBack: () {
          if (widget.payload.isBackHome) {
            unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.homePage,
              (route) => false,
            ));
          } else {
            Navigator.of(context).pop();
          }
        },
            icon: SvgPicture.asset(
              'assets/images/more_circle.svg',
              width: 22,
              colorFilter: const ColorFilter.mode(
                  AppColor.primaryBlack, BlendMode.srcIn),
            ),
            action: _showConnectionOption),
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
      );

  Widget _connectionsSection() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        BlocBuilder<ConnectionsBloc, ConnectionsState>(
            builder: (context, state) {
          final connectionItems = state.connectionItems;
          if (connectionItems == null) {
            return const SizedBox();
          }

          if (connectionItems.isEmpty) {
            return _emptyConnectionsWidget(context);
          } else {
            return Column(
              children: [
                ...connectionItems.map((connectionItem) => Column(
                      children: [
                        Slidable(
                          groupTag: 'connectionsView',
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            dragDismissible: false,
                            children: _slidableActions(context, connectionItem),
                          ),
                          child: Padding(
                            padding: ResponsiveLayout.pageEdgeInsets
                                .copyWith(top: 0, bottom: 0),
                            child:
                                _connectionItemWidget(context, connectionItem),
                          ),
                        ),
                        addOnlyDivider()
                      ],
                    )),
              ],
            );
          }
        }),
      ]);

  Widget _emptyConnectionsWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Padding(
        padding: ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0),
        child: TappableForwardRowWithContent(
            leftWidget: Row(children: [
              Text('add_connection'.tr(),
                  style: theme.textTheme.ppMori400Black16),
            ]),
            bottomWidget: Text('connect_dapp'.tr(),
                //"Connect this address to an external dapp or platform.",
                style: theme.textTheme.ppMori400Black14),
            onTap: () {
              late ScannerItem scanItem;

              switch (widget.payload.type) {
                case CryptoType.ETH:
                  scanItem = ScannerItem.WALLET_CONNECT;
                case CryptoType.XTZ:
                  scanItem = ScannerItem.BEACON_CONNECT;
                default:
                  break;
              }

              unawaited(Navigator.of(context)
                  .pushNamed(AppRouter.scanQRPage, arguments: scanItem));
            }),
      ),
      addOnlyDivider(),
    ]);
  }

  Widget _connectionItemWidget(
      BuildContext context, ConnectionItem connectionItem) {
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
        unawaited(Navigator.of(context).pushNamed(
            AppRouter.connectionDetailsPage,
            arguments: connectionItem));
        _callFetchConnections();
      },
    );
  }

  List<CustomSlidableAction> _slidableActions(
      BuildContext context, ConnectionItem connectionItem) {
    final connection = connectionItem.representative;
    final theme = Theme.of(context);

    return [
      CustomSlidableAction(
        backgroundColor: Colors.red,
        foregroundColor: theme.colorScheme.secondary,
        child: Semantics(
          label: '${connection.appName}_delete',
          child: SvgPicture.asset('assets/images/unlink.svg'),
        ),
        onPressed: (_) {
          context
              .read<ConnectionsBloc>()
              .add(DeleteConnectionsEvent(connectionItem));
        },
      ),
    ];
  }
}

class PersonaConnectionsPayload {
  final String personaUUID;
  final int index;
  final String address;
  final CryptoType type;
  final bool isBackHome;

  PersonaConnectionsPayload({
    required this.personaUUID,
    required this.index,
    required this.address,
    required this.type,
    this.isBackHome = false,
  });
}

class ConnectionViaClipboardError implements Exception {
  final String message;

  ConnectionViaClipboardError(this.message);
}
