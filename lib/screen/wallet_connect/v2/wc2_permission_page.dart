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
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:readmore/readmore.dart';

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
  bool _isAccountSelected = false;

  @override
  void initState() {
    super.initState();
    context
        .read<PersonaBloc>()
        .add(GetListPersonaEvent(useDidKeyForAlias: true));
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
    required WalletStorage account,
  }) async {
    final accountService = injector<AccountService>();

    final signature = await (await accountService.getDefaultAccount())
        .getAccountDIDSignature(params.message);
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
      String signature;
      if (chain.caip2Namespace == Wc2Chain.autonomy) {
        signature =
            await (await accountService.getDefaultAccount()).signMessage(
          chain: chain,
          message: params.message,
        );
      } else {
        signature = await account.signMessage(
          chain: chain,
          message: params.message,
        );
      }
      wc2Service.respondOnApprove(request.topic, signature);
    } catch (e) {
      log.info("[Wc2RequestPage] _handleAuSignRequest $e");
    }
  }

  Future _approve() async {
    if (selectedPersona == null) return;
    final wc2Service = injector<Wc2Service>();
    if (widget.request.method == "au_permissions") {
      final params =
          Wc2PermissionsRequestParams.fromJson(widget.request.params);
      final account = selectedPersona;
      if (account != null) {
        final response = await _handleAuPermissionRequest(
          params: params,
          account: account.wallet(),
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
          child: Column(
            children: [
              Expanded(
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
                      ReadMoreText(
                        widget.request.params["message"],
                        style: theme.textTheme.bodyText2,
                        trimMode: TrimMode.Line,
                        colorClickableText: AppColor.primaryBlack,
                      ),
                      Divider(
                        height: 32,
                        color: theme.colorScheme.secondary,
                      ),
                      BlocConsumer<PersonaBloc, PersonaState>(
                          listener: (context, state) {
                        var statePersonas = state.personas;
                        if (statePersonas == null) return;

                        if (statePersonas.length == 1) {
                          setState(() {
                            selectedPersona = statePersonas.first;
                          });
                        }

                        setState(() {
                          personas = statePersonas;
                        });
                      }, builder: (context, state) {
                        final statePersonas = personas;
                        if (statePersonas == null) return const SizedBox();

                        return _selectPersonaWidget(statePersonas);
                      })
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: AuFilledButton(
                      text: "sign".tr().toUpperCase(),
                      onPress: _isAccountSelected
                          ? () => withDebounce(() => _approve())
                          : null,
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

  Widget _selectPersonaWidget(List<Persona> personas) {
    bool hasRadio = personas.length > 1;
    final theme = Theme.of(context);
    if (!hasRadio) _isAccountSelected = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "select_grand_access".tr(), //"Select an account to grant access:",
          style: theme.textTheme.headline4,
        ),
        const SizedBox(height: 16.0),
        ...personas
            .map((persona) => Column(
                  children: [
                    ListTile(
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
                                child:
                                    Image.asset("assets/images/moma_logo.png"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          FutureBuilder<String>(
                            future: persona.wallet().getAccountDID(),
                            builder: (context, snapshot) {
                              final name = persona.name.isNotEmpty
                                  ? persona.name
                                  : snapshot.data ?? '';
                              return Expanded(
                                child: Text(
                                  name.replaceFirst('did:key:', ''),
                                  style: theme.textTheme.headline4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      contentPadding: EdgeInsets.zero,
                      trailing: (hasRadio
                          ? Transform.scale(
                              scale: 1.2,
                              child: Radio(
                                activeColor: theme.colorScheme.primary,
                                value: persona,
                                groupValue: selectedPersona,
                                onChanged: (Persona? value) {
                                  setState(() {
                                    selectedPersona = value;
                                    _isAccountSelected = true;
                                  });
                                },
                              ),
                            )
                          : null),
                    ),
                    const Divider(height: 16.0),
                  ],
                ))
            .toList(),
      ],
    );
  }
}
