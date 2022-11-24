//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';

class Wc2RequestPage extends StatefulWidget {
  final Wc2Request request;

  const Wc2RequestPage({Key? key, required this.request}) : super(key: key);

  @override
  State<Wc2RequestPage> createState() => _Wc2RequestPageState();
}

class _Wc2RequestPageState extends State<Wc2RequestPage>
    with RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    context.read<PersonaBloc>().add(GetListPersonaEvent());
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
    context.read<PersonaBloc>().add(GetListPersonaEvent());
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
    required WalletStorage account,
  }) async {
    final signature = await account.getAccountDIDSignature(params.message);
    final permissionResults = params.permissions.map((permission) async {
      final chainFutures = permission.request.chains.map((chain) async {
        final chainResp = await account.signPermissionRequest(
          chain: chain,
          message: params.message,
        );
        return chainResp;
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

  Future _handleAuSignRequest({required Wc2Request request}) async {
    final accountService = injector<AccountService>();
    final params = Wc2SignRequestParams.fromJson(request.params);
    final address = params.address;
    final chain = params.chain;
    final account = await accountService.getAccountByAddress(
      chain: chain,
      address: address,
    );
    final wc2Service = injector<Wc2Service>();
    try {
      final signature = await account.signMessage(
        chain: chain,
        message: params.message,
      );
      wc2Service.respondOnApprove(request.topic, signature);
    } catch (e) {
      log.info("[Wc2RequestPage] _handleAuSignRequest $e");
    }
  }

  Future _approve() async {
    final wc2Service = injector<Wc2Service>();
    if (widget.request.method == "au_permissions") {
      final params =
          Wc2PermissionsRequestParams.fromJson(widget.request.params);
      final accountService = injector<AccountService>();
      final did = "did:key:${params.account.split(":")[2]}";
      final account = await accountService.getAccount(did);
      if (account != null) {
        final response = await _handleAuPermissionRequest(
          params: params,
          account: account,
        );
        await wc2Service.respondOnApprove(widget.request.topic, response);
      } else {
        log.info("[Wc2RequestPage] Reject ${widget.request.toJson()}");
        await wc2Service.respondOnReject(widget.request.topic);
      }
    } else if (widget.request.method == "au_sign") {
      try {
        _handleAuSignRequest(request: widget.request);
      } catch (e) {
        log.info("[Wc2RequestPage] Handle sign request error $e");
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Wc2PermissionsRequestParams? permissionParams;
    Wc2SignRequestParams? signParams;
    if (widget.request.method == "au_permissions") {
      permissionParams =
          Wc2PermissionsRequestParams.fromJson(widget.request.params);
    }
    if (widget.request.method == "au_sign") {
      signParams = Wc2SignRequestParams.fromJson(widget.request.params);
    }

    return WillPopScope(
      onWillPop: () async {
        await _reject();
        return true;
      },
      child: Scaffold(
        appBar: getBackAppBar(context, onBack: () async {
          await _reject();
          if (!mounted) return;
          Navigator.pop(context);
        }),
        body: Container(
          margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Text(
                    "signature_request".tr(),
                    style: theme.textTheme.headline1,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "connection".tr(),
                  style: theme.textTheme.headline4,
                ),
                const SizedBox(height: 16.0),
                Text(
                  widget.request.proposer?.name ?? "",
                  style: theme.textTheme.bodyText2,
                ),
                const Divider(height: 32),
                Text(
                  "message".tr(),
                  style: theme.textTheme.headline4,
                ),
                const SizedBox(height: 16.0),
                Text(
                  widget.request.params["message"],
                  style: theme.textTheme.bodyText2,
                ),
                Divider(
                  height: 64,
                  color: theme.colorScheme.secondary,
                ),
                Row(
                  children: [
                    Expanded(
                      child: AuFilledButton(
                        text: "sign".tr().toUpperCase(),
                        onPress: () => withDebounce(() => _approve()),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
