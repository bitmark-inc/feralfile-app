//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/list_address_account.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class Wc2RequestPage extends StatefulWidget {
  final Wc2Request request;

  const Wc2RequestPage({required this.request, super.key});

  @override
  State<Wc2RequestPage> createState() => _Wc2RequestPageState();
}

class _Wc2RequestPageState extends State<Wc2RequestPage>
    with RouteAware, WidgetsBindingObserver {
  Persona? selectedPersona;
  List<Persona>? personas;

  bool get _isAccountSelected =>
      selectedAddresses.values.every((element) => element != null);
  late Wc2PermissionsRequestParams params;
  bool _selectETHAddress = false;
  bool _selectXTZAddress = false;

  final selectedAddresses = {};
  bool _includeLinkedAccount = false;

  @override
  void initState() {
    super.initState();
    params = Wc2PermissionsRequestParams.fromJson(widget.request.params);

    // ignore: avoid_function_literals_in_foreach_calls
    params.permissions.firstOrNull?.request.chains.forEach((element) {
      selectedAddresses[element] = null;
    });

    _includeLinkedAccount =
        params.permissions.firstOrNull?.includeLinkedAccount ?? false;

    _selectETHAddress = selectedAddresses.containsKey('eip155:1');
    _selectXTZAddress = selectedAddresses.containsKey('tezos');

    context.read<AccountsBloc>().add(
          GetCategorizedAccountsEvent(
              includeLinkedAccount: _includeLinkedAccount,
              getEth: _selectETHAddress,
              getTezos: _selectXTZAddress,
              autoAddAddress: true),
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
    log.info('[Wc2RequestPage] Reject request.');
    try {
      await injector<Wc2Service>().respondOnReject(
        widget.request.topic,
        reason: 'User reject',
      );
    } catch (e) {
      log.info('[Wc2RequestPage] Reject request error. $e');
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
              chain: chain, address: selectedAddresses[chain]);
          final chainResp = await account.signPermissionRequest(
            chain: chain,
            message: params.message,
          );
          return chainResp;
        } on AccountException {
          return Wc2Chain(
            chain: chain,
            address: selectedAddresses[chain],
          );
        }
      });
      final chains = (await Future.wait(chainFutures))
          .where((e) => e != null)
          .map((e) => e!)
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
    final cloudDB = injector<CloudDatabase>();
    final connections = await cloudDB.connectionDao
        .getConnectionsByType(ConnectionType.walletConnect2.rawValue);
    final pendingSession = wc2Service.getFirstSession();
    if (pendingSession != null) {
      final connection = connections
          .firstWhereOrNull((element) => element.key.contains(pendingSession));
      if (connection != null) {
        final accountNumber = selectedAddresses.values.join('||');
        await cloudDB.connectionDao.updateConnection(
            connection.copyWith(accountNumber: accountNumber));
      }
      wc2Service.removePendingSession(pendingSession);
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();

    showInfoNotification(
      const Key('signed'),
      'signed'.tr(),
      frontWidget: SvgPicture.asset(
        'assets/images/checkbox_icon.svg',
        width: 24,
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      showInfoNotification(const Key('switchBack'), 'you_all_set'.tr());
    });
  }

  Widget _wcAppInfo(BuildContext context) {
    final theme = Theme.of(context);
    final proposer = widget.request.proposer;
    if (proposer == null) {
      return const SizedBox();
    }
    final peerMeta = AppMetadata(
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
            width: 64,
            height: 64,
            errorWidget: (context, url, error) => SizedBox(
              width: 64,
              height: 64,
              child: Image.asset(
                'assets/images/walletconnect-alternative.png',
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: 64,
            height: 64,
            child: Image.asset(
              'assets/images/walletconnect-alternative.png',
            ),
          ),
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
            if (!mounted) {
              return;
            }
            Navigator.pop(context);
          },
          title: 'address_request'.tr(),
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
                child: _wcAppInfo(context),
              ),
              const SizedBox(height: 32),
              addDivider(height: 52),
              Expanded(
                child: SingleChildScrollView(
                  child: BlocConsumer<AccountsBloc, AccountsState>(
                      listener: (context, state) {
                    final categorizedAccounts = state.accounts ?? [];

                    if (state.accounts?.length == 2) {
                      if (selectedAddresses.containsKey('eip155:1')) {
                        selectedAddresses['eip155:1'] = categorizedAccounts
                            .firstWhere((element) => element.isEth)
                            .accountNumber;
                      }
                      if (selectedAddresses.containsKey('tezos')) {
                        selectedAddresses['tezos'] = categorizedAccounts
                            .firstWhere((element) => element.isTez)
                            .accountNumber;
                      }
                    }
                    setState(() {});
                  }, builder: (context, state) {
                    final accounts = state.accounts ?? [];
                    if (accounts.isEmpty) {
                      return const SizedBox();
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                          child: Text(
                            _selectETHAddress && _selectXTZAddress
                                ? 'select_tezo_and_eth_address'
                                    .tr(args: ['1', '1'])
                                : _selectETHAddress
                                    ? 'select_eth_address'.tr(args: ['1'])
                                    : _selectXTZAddress
                                        ? 'select_tezos_address'.tr(args: ['1'])
                                        : 'select_grand_access'.tr(),
                            style: theme.textTheme.ppMori400Black16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListAccountConnect(
                          accounts: accounts,
                          onSelectEth: (value) {
                            setState(() {
                              selectedAddresses['eip155:1'] =
                                  value.accountNumber;
                            });
                          },
                          onSelectTez: (value) {
                            setState(() {
                              selectedAddresses['tezos'] = value.accountNumber;
                            });
                          },
                          isAutoSelect: accounts.length == 2,
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
                        text: 'h_confirm'.tr(),
                        onTap: _isAccountSelected
                            ? () => withDebounce(() => unawaited(_approve()))
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
