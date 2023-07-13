//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';

class LinkTezosKukaiPage extends StatefulWidget {
  const LinkTezosKukaiPage({Key? key}) : super(key: key);

  @override
  State<LinkTezosKukaiPage> createState() => _LinkTezosKukaiPageState();
}

class _LinkTezosKukaiPageState extends State<LinkTezosKukaiPage>
    with AfterLayoutMixin<LinkTezosKukaiPage> {
  final metricClient = injector.get<MetricClientService>();

  @override
  void afterFirstLayout(BuildContext context) {
    metricClient.timerEvent(MixpanelEvent.backGenerateLink);
    metricClient.timerEvent(MixpanelEvent.generateLink);
  }

  @override
  Widget build(BuildContext context) {
    final tezosBeaconService = injector<TezosBeaconService>();
    final theme = Theme.of(context);

    return Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () {
            metricClient.addEvent(MixpanelEvent.backGenerateLink);
            Navigator.of(context).pop();
          },
          title: "kukai".tr(),
        ),
        body: Container(
          margin: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      addTitleSpace(),
                      Text(
                        "link_to_web_wallet".tr(),
                        style: theme.textTheme.ppMori700Black24,
                      ),
                      addTitleSpace(),
                      Text(
                        "to_link_kukai".tr(),
                        style: theme.textTheme.ppMori400Black14,
                      ),
                      const SizedBox(height: 15),
                      stepWidget(context, '1', "ltk_generate_a_link".tr()),
                      const SizedBox(height: 15),
                      stepWidget(context, '2', "ltk_when_prompted_by".tr()),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                text: "generate_link".tr(),
                onTap: () {
                  metricClient.addEvent(MixpanelEvent.generateLink);
                  withDebounce(() async {
                    final uri = await tezosBeaconService.getConnectionURI();
                    Share.share("https://wallet.kukai.app/tezos$uri");
                  }, debounceTime: 2000000);
                },
              ),
            ],
          ),
        ));
  }
}
