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
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  void _reject() {
    injector<Wc2Service>().respondOnReject(widget.request.topic);
    Navigator.of(context).pop();
  }

  Future _approve() async {
    final String response;
    if (widget.request.method == "au_permissions") {
      response = '{"signature":"did_signature","permissionResults":[{"type":"chains_request","result":{"chains":[{"chain":"eth","address":"0xC045aD601027530f36D0609486A694a1744320F5","signature":"eth_signauture"},{"chain":"tezos","address":"tz1gDahtzboNACtGTkubR5RNXdtp2dANTNUu","publicKey":"edpk..","signature":"tezos_signauture"}]}}]}';
    } else if (widget.request.method == "au_sign") {
      response = "autonomy_signature";
    } else {
      response = "";
    }

    await injector<Wc2Service>()
        .respondOnApprove(widget.request.topic, response);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Wc2PermissionsRequestParams? permissionParams;
    Wc2SignRequestParams? signParams;
    if (widget.request.method == "au_permissions") {
      permissionParams = Wc2PermissionsRequestParams.fromJson(widget.request.params);
    } if (widget.request.method == "au_sign") {
      signParams = Wc2SignRequestParams.fromJson(widget.request.params);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        leading: const SizedBox(),
        leadingWidth: 0.0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _reject(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 7, 18, 8),
                child: Row(
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/nav-arrow-left.svg',
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          "back".tr(),
                          style: theme.primaryTextTheme.button,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        margin: pageEdgeInsetsWithSubmitButton,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            "Request data".tr(),
            style: theme.primaryTextTheme.headline1,
          ),
          const SizedBox(height: 24),
          Text("Method: ${widget.request.method}",
              //"Instantly set up your personal NFT art gallery on TVs and projectors anywhere you go.",
              style: theme.primaryTextTheme.bodyText1),
          if (permissionParams != null) ...[
            const SizedBox(height: 12),
            Text("Chains request: ${permissionParams.permissions.first.request.chains}",
              //"Instantly set up your personal NFT art gallery on TVs and projectors anywhere you go.",
              style: theme.primaryTextTheme.bodyText1),
          ],
          if (signParams != null) ...[
            const SizedBox(height: 12),
            Text("Sign message: ${signParams.message}",
                //"Instantly set up your personal NFT art gallery on TVs and projectors anywhere you go.",
                style: theme.primaryTextTheme.bodyText1),
          ],
          const SizedBox(height: 12),
          Text("Raw data: ${json.encode(widget.request.params)}",
              maxLines: 20,
              //"Instantly set up your personal NFT art gallery on TVs and projectors anywhere you go.",
              style: theme.primaryTextTheme.bodyText1),
          Divider(
            height: 64,
            color: theme.colorScheme.secondary,
          ),
          const Expanded(child: SizedBox()),
          Row(
            children: [
              Expanded(
                child: AuFilledButton(
                  text: "Authorize".tr().toUpperCase(),
                  onPress: () => withDebounce(() => _approve()),
                  color: theme.colorScheme.secondary,
                  textStyle: theme.textTheme.button,
                ),
              )
            ],
          )
        ]),
      ),
    );
  }
}
