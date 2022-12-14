//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/responsive.dart';

import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';

class TVConnectPage extends StatefulWidget {
  final WCConnectPageArgs wcConnectArgs;

  const TVConnectPage({Key? key, required this.wcConnectArgs})
      : super(key: key);

  @override
  State<TVConnectPage> createState() => _TVConnectPageState();
}

class _TVConnectPageState extends State<TVConnectPage>
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
    final wcConnectArgs = widget.wcConnectArgs;
    injector<WalletConnectService>().rejectSession(wcConnectArgs.peerMeta);

    Navigator.of(context).pop();
  }

  Future _approve() async {
    final authorizedKeypair =
        await injector<AccountService>().authorizeToViewer();

    final chainId = Environment.web3ChainId;

    final isApproveSuccess = await injector<WalletConnectService>()
        .approveSession(const Uuid().v4(), widget.wcConnectArgs.peerMeta,
            [authorizedKeypair], chainId);

    if (!mounted) return;
    if (!isApproveSuccess) {
      await UIHelper.showConnectionFaild(
        context,
        onClose: () {
          UIHelper.hideInfoDialog(context);
          Navigator.of(context).pop();
        },
      );
      return;
    }
    await UIHelper.showConnectionSuccess(
      context,
      onClose: () {
        UIHelper.hideInfoDialog(context);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        _reject();
        return true;
      },
      child: Scaffold(
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
          margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "connect_au_viewer".tr(),
              style: theme.primaryTextTheme.headline1,
            ),
            const SizedBox(height: 24),
            Text("set_up_gallery".tr(),
                style: theme.primaryTextTheme.bodyText1),
            const SizedBox(
              height: 32,
            ),
            Text("viewer_request_to".tr(),
                style: theme.primaryTextTheme.bodyText1),
            const SizedBox(height: 8),
            Text("view_collections".tr(),
                style: theme.primaryTextTheme.bodyText1),
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
      ),
    );
  }
}
