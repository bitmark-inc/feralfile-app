//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/mixPanel_client_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';

class LinkTezosKukaiPage extends StatefulWidget {
  const LinkTezosKukaiPage({Key? key}) : super(key: key);

  @override
  State<LinkTezosKukaiPage> createState() => _LinkTezosKukaiPageState();
}

class _LinkTezosKukaiPageState extends State<LinkTezosKukaiPage> {
  final mixPanelClient = injector.get<MixPanelClientService>();

  @override
  void initState() {
    mixPanelClient.timerEvent(MixpanelEvent.backGenerateLink);
    mixPanelClient.timerEvent(MixpanelEvent.generateLink);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tezosBeaconService = injector<TezosBeaconService>();
    final theme = Theme.of(context);

    return Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () {
            mixPanelClient.trackEvent(MixpanelEvent.backGenerateLink);
            Navigator.of(context).pop();
          },
        ),
        body: Container(
          margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "linking_to_kukai".tr(),
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "ltk_since_kukai_only".tr(),
                      //"Since Kukai only exists as a web wallet, you will need to follow these additional steps to link it to Autonomy: ",
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 20),
                    _stepWidget(context, '1', "ltk_generate_a_link".tr()),
                    //'Generate a link request and send it to the web browser where you are currently signed in to Kukai.'),
                    const SizedBox(height: 10),
                    _stepWidget(context, '2', "ltk_when_prompted_by".tr()),
                    //'When prompted by Kukai, approve Autonomy’s permissions requests. '),
                    const SizedBox(height: 40),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: wantMoreSecurityWidget(
                                  context, WalletApp.Kukai))
                        ]),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "generate_link".tr().toUpperCase(),
                    onPress: () {
                      mixPanelClient.trackEvent(MixpanelEvent.generateLink);
                      withDebounce(() async {
                        final uri = await tezosBeaconService.getConnectionURI();
                        Share.share("https://wallet.kukai.app/tezos$uri");
                      }, debounceTime: 2000000);
                    },
                  ),
                ),
              ],
            ),
          ]),
        ));
  }

  Widget _stepWidget(
      BuildContext context, String stepNumber, String stepGuide) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            stepNumber,
            style: theme.textTheme.button,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(stepGuide, style: theme.textTheme.bodyText1),
        )
      ],
    );
  }
}
