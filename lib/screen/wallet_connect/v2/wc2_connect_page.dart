//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/wc2_proposal.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Wc2ConnectPage extends StatefulWidget {
  final Wc2Proposal proposal;

  const Wc2ConnectPage({Key? key, required this.proposal}) : super(key: key);

  @override
  State<Wc2ConnectPage> createState() => _Wc2ConnectPageState();
}

class _Wc2ConnectPageState extends State<Wc2ConnectPage>
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
    injector<Wc2Service>().rejectSession(
      widget.proposal.id,
      reason: "User reject",
    );
    Navigator.of(context).pop();
  }

  Future _approve() async {
    //final accountDid = await current !.wallet().getAccountDID();
    await injector<Wc2Service>().approveSession(
      widget.proposal,
      accountDid: "",
      personalUUID: "",
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            "Connect to ${widget.proposal.proposer.name}".tr(),
            style: theme.primaryTextTheme.headline1,
          ),
          const SizedBox(height: 24),
          Text(widget.proposal.proposer.description,
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
