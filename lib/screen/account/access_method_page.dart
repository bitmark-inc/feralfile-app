//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: unused_field

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_toggle.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../common/injector.dart';
import '../../database/cloud_database.dart';
import '../../database/entity/connection.dart';
import '../../util/constants.dart';

class AccessMethodPage extends StatefulWidget {
  const AccessMethodPage({Key? key}) : super(key: key);

  @override
  State<AccessMethodPage> createState() => _AccessMethodPageState();
}

class _AccessMethodPageState extends State<AccessMethodPage>
    with AfterLayoutMixin {
  var _redrawObject = Object();
  final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);

  @override
  void afterFirstLayout(BuildContext context) {
    injector<ConfigurationService>().setAlreadyShowLinkOrImportTip(true);
    injector<ConfigurationService>().showLinkOrImportTip.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "add_existing_wallet".tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            addDivider(height: 48),
            Padding(
              padding: padding,
              child: _linkAccount(context),
            ),
            addDivider(height: 48),
            injector<ConfigurationService>().isDoneOnboarding()
                ? _linkDebugWidget(context)
                : const SizedBox(),
          ]),
        ),
      ),
    );
  }

  Widget _addWalletItem(
      {required BuildContext context,
      required String title,
      String? content,
      required dynamic Function()? onTap,
      bool forward = true}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.ppMori400Black16,
                  ),
                  const Spacer(),
                  forward
                      ? SvgPicture.asset('assets/images/iconForward.svg')
                      : const SizedBox(),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Text(
              content ?? "",
              style: theme.textTheme.ppMori400Black14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkAccount(BuildContext context) {
    return _addWalletItem(
        context: context,
        title: "link_existing_wallet".tr(),
        content: "link_wallet_description".tr(),
        onTap: () {
          Navigator.of(context).pushNamed(AppRouter.linkAccountpage);
        });
  }

  Widget _linkDebugWidget(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Column(
              children: [
                Padding(
                  padding: padding,
                  child: _addWalletItem(
                      context: context,
                      title: 'debug_address'.tr(),
                      content: "da_manually_input_an".tr(),
                      onTap: () => Navigator.of(context).pushNamed(
                          AppRouter.linkManually,
                          arguments: 'address')),
                ),
                addDivider(height: 48),
                Padding(
                  padding: padding,
                  child: _addWalletItem(
                      context: context,
                      title: 'test_artwork'.tr(),
                      onTap: () => Navigator.of(context).pushNamed(
                            AppRouter.testArtwork,
                          )),
                ),
                addDivider(height: 48),
                Padding(
                  padding: padding,
                  child: _linkTokenIndexerIDWidget(context),
                ),
                addDivider(height: 48),
                Padding(
                  padding: padding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("show_token_debug_log".tr(),
                          style: theme.textTheme.headlineMedium),
                      AuToggle(
                        value: injector<ConfigurationService>()
                            .showTokenDebugInfo(),
                        onToggle: (isEnabled) async {
                          await injector<ConfigurationService>()
                              .setShowTokenDebugInfo(isEnabled);
                          setState(() {
                            _redrawObject = Object();
                          });
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          }

          return const SizedBox();
        });
  }

  Widget _linkTokenIndexerIDWidget(BuildContext context) {
    return Column(
      children: [
        _addWalletItem(
          context: context,
          title: "debug_indexer_tokenId".tr(),
          content: "dit_manually_input_an".tr(),
          onTap: () => Navigator.of(context)
              .pushNamed(AppRouter.linkManually, arguments: 'indexerTokenID'),
        ),
        TextButton(
            onPressed: () {
              injector<CloudDatabase>().connectionDao.deleteConnectionsByType(
                  ConnectionType.manuallyIndexerTokenID.rawValue);
            },
            child: Text("delete_all_debug_li".tr())),
      ],
    );
  }
}
