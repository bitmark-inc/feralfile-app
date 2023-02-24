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
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';

import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  }

  Future _approve() async {
    final authorizedKeypair =
        await injector<AccountService>().authorizeToViewer();

    final chainId = Environment.web3ChainId;

    final isApproveSuccess = await injector<WalletConnectService>()
        .approveSession(const Uuid().v4(),0, widget.wcConnectArgs.peerMeta,
            [authorizedKeypair], chainId);

    if (!mounted) return;
    if (!isApproveSuccess) {
      await UIHelper.showConnectionFailed(
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
        appBar: getBackAppBar(
          context,
          onBack: () {
            _reject();
            Navigator.of(context).pop();
          },
          title: 'connect'.tr(),
        ),
        body: Container(
          margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              addTitleSpace(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: theme.auSuperTeal,
                        borderRadius: BorderRadius.circular(20)),
                    child: SizedBox(
                      width: 45,
                      height: 45,
                      child: Image.asset("assets/images/moma_logo.png"),
                    ),
                  ),
                  const SizedBox(
                    width: 24,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "autonomy_on_TV".tr(),
                          style: theme.textTheme.ppMori700Black24,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          "set_up_gallery".tr(),
                          style: theme.textTheme.ppMori400Black12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 24,
                  ),
                ],
              ),
              addTitleSpace(),
              const Divider(),
              const SizedBox(
                height: 24,
              ),
              Text(
                "you_have_permission".tr(),
                style: theme.textTheme.ppMori400Black16,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: BoxDecoration(
                  color: theme.auLightGrey,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  "view_collections".tr(),
                  style: theme.textTheme.ppMori400Black14,
                ),
              ),
              const Expanded(child: SizedBox()),
              PrimaryButton(
                text: 'connect'.tr(),
                onTap: () => withDebounce(() => _approve()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
